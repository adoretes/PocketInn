import 'dart:async';

import 'package:get_it/get_it.dart';

import '../data/api_configs.dart';
import '../data/mock_user_settings.dart';
import '../models/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/preset.dart';
import '../models/prompt_assembly.dart';
import '../models/regex_rule_group.dart';
import '../models/world_book.dart';
import 'chat_character_resolver.dart';
import 'chat_database_service.dart';
import 'chat_memory_service.dart';
import 'chat_variable_service.dart';
import 'gal_choice_parser.dart';
import 'i_openai_api_service.dart';
import 'openai_compatible_api_service.dart';
import 'preset_service.dart';
import 'prompt_assembler.dart';
import 'regex_rule_group_service.dart';
import 'regex_replacement_service.dart';
import 'world_book_service.dart';

class ChatSendResult {
  const ChatSendResult({
    required this.userNode,
    required this.assistantNode,
    required this.promptAssembly,
    required this.completion,
  });

  final ChatNode userNode;
  final ChatNode assistantNode;
  final PromptAssemblyResult promptAssembly;
  final ChatCompletionResult completion;
}

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  Future<ChatSendResult> sendMessage({
    required ChatSession session,
    required ResolvedChatCharacter character,
    required List<ChatMessage> chatMessages,
    required String input,
    String? selectedPresetId,
    String? selectedUserSettingId,
    Set<String> selectedWorldBookIds = const <String>{},
    Set<String> selectedRegexRuleGroupIds = const <String>{},
    bool useStreaming = false,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
    Future<ChatSession> Function()? persistSession,
    String? parentMessageId,
  }) async {
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      throw const FormatException('消息不能为空');
    }

    final effectiveRegexRuleGroupIds = selectedRegexRuleGroupIds.isNotEmpty
        ? selectedRegexRuleGroupIds
        : session.selectedRegexRuleGroupIds.toSet();

    // 「写入」规则：先替换再入库，请求与记录都使用替换后的文本。
    final storedInput = await _applyUserWriteRules(
      normalizedInput,
      effectiveRegexRuleGroupIds,
    );

    final config = resolvedSelectedApi;
    if (config == null) {
      throw StateError('当前未选择 API 模型');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前选中的模型未填写 Model ID');
    }

    final preset = await _resolvePreset(
      selectedPresetId ?? session.selectedPresetId,
    );
    final userSetting = _resolveUserSetting(
      selectedUserSettingId ?? session.selectedUserSettingId,
    );
    final worldBooks = await _loadSelectedWorldBooks(
      selectedWorldBookIds.isNotEmpty
          ? selectedWorldBookIds
          : session.selectedWorldBookIds.toSet(),
    );

    final memoryContext = await _buildMemoryContext(
      sessionId: session.id,
      chatMessages: chatMessages,
    );

    final truncatedChatMessages = _truncateChatMessages(chatMessages);

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: truncatedChatMessages,
        currentInput: storedInput,
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    final activeSession = persistSession == null
        ? session
        : await persistSession();

    final userNode = await ChatDatabaseService.instance.appendUserMessage(
      sessionId: activeSession.id,
      parentMessageId: parentMessageId ?? activeSession.currentLeafMessageId,
      text: storedInput,
    );

    try {
      final completion = await _createCompletion(
        config,
        promptAssembly: promptAssembly,
        preset: preset,
        useStreaming: useStreaming,
        selectedRegexRuleGroupIds: effectiveRegexRuleGroupIds,
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );

      final assistantNode = await ChatDatabaseService.instance
          .appendAssistantMessage(
            sessionId: activeSession.id,
            parentMessageId: userNode.id,
            text: await _applyAssistantOutputRules(
              completion.text,
              effectiveRegexRuleGroupIds,
            ),
            thinkingChain: completion.thinkingChain,
          );

      unawaited(
        _tryAutoExtractMemories(
          sessionId: activeSession.id,
          branchLeafId: assistantNode.id,
          chatMessages: chatMessages,
          userMessage: ChatMessage(
            id: userNode.id,
            text: userNode.text,
            isMe: true,
          ),
          assistantMessage: ChatMessage(
            id: assistantNode.id,
            text: assistantNode.text,
            isMe: false,
          ),
          characterName: character.name,
          userName: userSetting.name,
          currentInput: userNode.text,
          cardData: _extractCardData(character.cardJson),
        ),
      );

      return ChatSendResult(
        userNode: userNode,
        assistantNode: assistantNode,
        promptAssembly: promptAssembly,
        completion: completion,
      );
    } on ChatCompletionCancelledException {
      rethrow;
    } catch (error) {
      throw StateError('发送聊天请求失败: $error');
    }
  }

  Future<ChatSendResult> regenerateAssistantResponse({
    required ChatSession session,
    required ResolvedChatCharacter character,
    required List<ChatMessage> historyBeforeUserMessage,
    required ChatMessage userMessage,
    String? selectedPresetId,
    String? selectedUserSettingId,
    Set<String> selectedWorldBookIds = const <String>{},
    Set<String> selectedRegexRuleGroupIds = const <String>{},
    bool useStreaming = false,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    if (userMessage.id == null) {
      throw StateError('用户消息缺少 ID，无法重新生成');
    }
    if (!userMessage.isMe) {
      throw StateError('只能基于用户消息重新生成回复');
    }

    final config = resolvedSelectedApi;
    if (config == null) {
      throw StateError('当前未选择 API 模型');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前选中的模型未填写 Model ID');
    }

    final effectiveRegexRuleGroupIds = selectedRegexRuleGroupIds.isNotEmpty
        ? selectedRegexRuleGroupIds
        : session.selectedRegexRuleGroupIds.toSet();

    final preset = await _resolvePreset(
      selectedPresetId ?? session.selectedPresetId,
    );
    final userSetting = _resolveUserSetting(
      selectedUserSettingId ?? session.selectedUserSettingId,
    );
    final worldBooks = await _loadSelectedWorldBooks(
      selectedWorldBookIds.isNotEmpty
          ? selectedWorldBookIds
          : session.selectedWorldBookIds.toSet(),
    );

    final memoryContext = await _buildMemoryContext(
      sessionId: session.id,
      chatMessages: historyBeforeUserMessage,
    );

    final truncatedHistory = _truncateChatMessages(historyBeforeUserMessage);

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: truncatedHistory,
        currentInput: userMessage.text,
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    try {
      final completion = await _createCompletion(
        config,
        promptAssembly: promptAssembly,
        preset: preset,
        useStreaming: useStreaming,
        selectedRegexRuleGroupIds: effectiveRegexRuleGroupIds,
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );

      final assistantNode = await ChatDatabaseService.instance
          .appendAssistantMessage(
            sessionId: session.id,
            parentMessageId: userMessage.id,
            text: await _applyAssistantOutputRules(
              completion.text,
              effectiveRegexRuleGroupIds,
            ),
            thinkingChain: completion.thinkingChain,
          );

      unawaited(
        _tryAutoExtractMemories(
          sessionId: session.id,
          branchLeafId: assistantNode.id,
          chatMessages: historyBeforeUserMessage,
          userMessage: ChatMessage(
            id: userMessage.id,
            text: userMessage.text,
            isMe: true,
          ),
          assistantMessage: ChatMessage(
            id: assistantNode.id,
            text: assistantNode.text,
            isMe: false,
          ),
          characterName: character.name,
          userName: userSetting.name,
          currentInput: userMessage.text,
          cardData: _extractCardData(character.cardJson),
        ),
      );

      return ChatSendResult(
        userNode: ChatNode(
          id: userMessage.id!,
          sessionId: userMessage.sessionId ?? session.id,
          parentId: userMessage.parentId,
          role: ChatNodeRole.user,
          text: userMessage.text,
          createdAt: DateTime.now(),
          siblingOrder: userMessage.index - 1,
        ),
        assistantNode: assistantNode,
        promptAssembly: promptAssembly,
        completion: completion,
      );
    } on ChatCompletionCancelledException {
      rethrow;
    } catch (error) {
      throw StateError('重新生成聊天回复失败: $error');
    }
  }

  /// 继续推进：基于最后一条角色消息生成新的角色消息。
  /// 使用预设中的 `continue_nudge_prompt` 作为继续提示。
  Future<ChatCompletionResult> continueAssistantResponse({
    required ChatSession session,
    required ResolvedChatCharacter character,
    required List<ChatMessage> chatMessages,
    String? selectedPresetId,
    String? selectedUserSettingId,
    Set<String> selectedWorldBookIds = const <String>{},
    Set<String> selectedRegexRuleGroupIds = const <String>{},
    bool useStreaming = false,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    if (chatMessages.isEmpty) {
      throw StateError('没有可继续的消息');
    }
    final lastMessage = chatMessages.last;
    if (lastMessage.isMe) {
      throw StateError('只能继续角色消息');
    }
    final lastMessageId = lastMessage.id;
    if (lastMessageId == null) {
      throw StateError('角色消息缺少 ID，无法继续');
    }

    final config = resolvedSelectedApi;
    if (config == null) {
      throw StateError('当前未选择 API 模型');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前选中的模型未填写 Model ID');
    }

    final effectiveRegexRuleGroupIds = selectedRegexRuleGroupIds.isNotEmpty
        ? selectedRegexRuleGroupIds
        : session.selectedRegexRuleGroupIds.toSet();

    final preset = await _resolvePreset(
      selectedPresetId ?? session.selectedPresetId,
    );
    final userSetting = _resolveUserSetting(
      selectedUserSettingId ?? session.selectedUserSettingId,
    );
    final worldBooks = await _loadSelectedWorldBooks(
      selectedWorldBookIds.isNotEmpty
          ? selectedWorldBookIds
          : session.selectedWorldBookIds.toSet(),
    );

    final memoryContext = await _buildMemoryContext(
      sessionId: session.id,
      chatMessages: chatMessages,
    );

    final truncatedChatMessages = _truncateChatMessages(chatMessages);

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: truncatedChatMessages,
        currentInput: '',
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    final continueNudge = ChatVariableService.replacePlaceholders(
      preset.extra['continue_nudge_prompt'] as String? ??
          '[Continue your last message without repeating its original content.]',
      characterName: character.name,
      userName: userSetting.name,
    ).trim();

    final fixedRole = preset.extra['fixed_prompts_role'] as String? ?? 'system';

    final requestMessages = <Map<String, dynamic>>[
      for (final message in promptAssembly.messages)
        {'role': message.role, 'content': message.content},
      if (continueNudge.isNotEmpty)
        {'role': fixedRole, 'content': continueNudge},
    ];

    try {
      final completion = await _createCompletionFromMessages(
        config,
        messages: requestMessages,
        preset: preset,
        useStreaming: useStreaming,
        selectedRegexRuleGroupIds: effectiveRegexRuleGroupIds,
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );

      await ChatDatabaseService.instance.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: lastMessageId,
        text: await _applyAssistantOutputRules(
          completion.text,
          effectiveRegexRuleGroupIds,
        ),
        thinkingChain: completion.thinkingChain,
      );

      return completion;
    } on ChatCompletionCancelledException {
      rethrow;
    } catch (error) {
      throw StateError('继续推进失败: $error');
    }
  }

  /// Gal 模式选项生成：基于当前对话（含最新角色回复）生成若干玩家选项。
  ///
  /// 独立的子 API 请求（非流式、不写数据库），要求模型只输出
  /// `{"choices": ["…", "…"]}` 形式的 JSON；解析失败返回空列表。
  Future<List<String>> generateGalChoices({
    required ChatSession session,
    required ResolvedChatCharacter character,
    required List<ChatMessage> chatMessages,
    String? selectedPresetId,
    String? selectedUserSettingId,
    Set<String> selectedWorldBookIds = const <String>{},
    Set<String> selectedRegexRuleGroupIds = const <String>{},
    ChatCompletionCancelToken? cancellationToken,
  }) async {
    final config = resolvedSelectedApi;
    if (config == null) {
      throw StateError('当前未选择 API 模型');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前选中的模型未填写 Model ID');
    }

    final effectiveRegexRuleGroupIds = selectedRegexRuleGroupIds.isNotEmpty
        ? selectedRegexRuleGroupIds
        : session.selectedRegexRuleGroupIds.toSet();

    final preset = await _resolvePreset(
      selectedPresetId ?? session.selectedPresetId,
    );
    final userSetting = _resolveUserSetting(
      selectedUserSettingId ?? session.selectedUserSettingId,
    );
    final worldBooks = await _loadSelectedWorldBooks(
      selectedWorldBookIds.isNotEmpty
          ? selectedWorldBookIds
          : session.selectedWorldBookIds.toSet(),
    );

    final memoryContext = await _buildMemoryContext(
      sessionId: session.id,
      chatMessages: chatMessages,
    );

    final truncatedChatMessages = _truncateChatMessages(chatMessages);

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: truncatedChatMessages,
        currentInput: '',
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    final fixedRole = preset.extra['fixed_prompts_role'] as String? ?? 'system';
    final choiceInstruction = ChatVariableService.replacePlaceholders(
      '你正在运行一个视觉小说游戏。请根据以上剧情进展，为玩家（{{user}}）生成接下来 '
      '3-4 个可以采取的行动或台词选项。要求：\n'
      '- 只输出严格的 JSON，格式为 {"choices": ["选项1", "选项2", "选项3"]}，不要输出任何其他内容；\n'
      '- 每个选项一句话，使用与剧情一致的语言，以玩家视角描述；\n'
      '- 选项之间要有明显的方向差异，不要重复。',
      characterName: character.name,
      userName: userSetting.name,
    );

    final requestMessages = <Map<String, dynamic>>[
      for (final message in promptAssembly.messages)
        {'role': message.role, 'content': message.content},
      {'role': fixedRole, 'content': choiceInstruction},
    ];

    try {
      final completion = await _createCompletionFromMessages(
        config,
        messages: requestMessages,
        preset: preset,
        useStreaming: false,
        selectedRegexRuleGroupIds: effectiveRegexRuleGroupIds,
        cancellationToken: cancellationToken,
      );
      return parseGalChoices(completion.text);
    } on ChatCompletionCancelledException {
      rethrow;
    } catch (_) {
      // 选项生成失败不应打断聊天，静默返回空列表。
      return const <String>[];
    }
  }

  /// 助手帮答：基于当前对话生成一条用户回复，填入输入框。
  /// 使用预设中的 `impersonation_prompt` 作为扮演提示。不写入数据库。
  Future<String> generateUserReply({
    required ChatSession session,
    required ResolvedChatCharacter character,
    required List<ChatMessage> chatMessages,
    String? selectedPresetId,
    String? selectedUserSettingId,
    Set<String> selectedWorldBookIds = const <String>{},
    Set<String> selectedRegexRuleGroupIds = const <String>{},
    bool useStreaming = false,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    final config = resolvedSelectedApi;
    if (config == null) {
      throw StateError('当前未选择 API 模型');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前选中的模型未填写 Model ID');
    }

    final effectiveRegexRuleGroupIds = selectedRegexRuleGroupIds.isNotEmpty
        ? selectedRegexRuleGroupIds
        : session.selectedRegexRuleGroupIds.toSet();

    final preset = await _resolvePreset(
      selectedPresetId ?? session.selectedPresetId,
    );
    final userSetting = _resolveUserSetting(
      selectedUserSettingId ?? session.selectedUserSettingId,
    );
    final worldBooks = await _loadSelectedWorldBooks(
      selectedWorldBookIds.isNotEmpty
          ? selectedWorldBookIds
          : session.selectedWorldBookIds.toSet(),
    );

    final memoryContext = await _buildMemoryContext(
      sessionId: session.id,
      chatMessages: chatMessages,
    );

    final truncatedChatMessages = _truncateChatMessages(chatMessages);

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: truncatedChatMessages,
        currentInput: '',
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    final impersonationPrompt = ChatVariableService.replacePlaceholders(
      preset.extra['impersonation_prompt'] as String? ??
          '[Write your next reply from the point of view of {{user}}, using the chat history so far as a guideline for the writing style of {{user}}. Don\'t write as {{char}} or system. Don\'t describe actions of {{char}}.]',
      characterName: character.name,
      userName: userSetting.name,
    ).trim();

    final fixedRole = preset.extra['fixed_prompts_role'] as String? ?? 'system';

    final requestMessages = <Map<String, dynamic>>[
      for (final message in promptAssembly.messages)
        {'role': message.role, 'content': message.content},
      if (impersonationPrompt.isNotEmpty)
        {'role': fixedRole, 'content': impersonationPrompt},
    ];

    try {
      final completion = await _createCompletionFromMessages(
        config,
        messages: requestMessages,
        preset: preset,
        useStreaming: useStreaming,
        selectedRegexRuleGroupIds: effectiveRegexRuleGroupIds,
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );
      return completion.text;
    } on ChatCompletionCancelledException {
      rethrow;
    } catch (error) {
      throw StateError('助手帮答失败: $error');
    }
  }

  Future<Preset> _resolvePreset(String? presetId) async {
    if (presetId != null && presetId.trim().isNotEmpty) {
      final preset = await PresetService.instance.loadById(presetId);
      if (preset != null) {
        return preset;
      }
    }

    final fallback = await PresetService.instance.loadDefaultPreset();
    if (fallback != null) {
      return fallback;
    }
    throw StateError('未找到可用预设');
  }

  UserSetting _resolveUserSetting(String? userSettingId) {
    final settings = userSettingsNotifier.value;
    if (settings.isEmpty) {
      return defaultUserSettings.first;
    }

    if (userSettingId != null) {
      for (final item in settings) {
        if (item.id == userSettingId) {
          return item;
        }
      }
    }

    return settings.first;
  }

  Future<List<WorldBook>> _loadSelectedWorldBooks(Set<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }

    final books = <WorldBook>[];
    for (final id in ids) {
      final book = await WorldBookService.instance.loadById(id);
      if (book != null) {
        books.add(book);
      }
    }
    return books;
  }

  Future<List<RegexRuleGroup>> _loadRegexGroups(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return const [];
    try {
      final all = await RegexRuleGroupService.instance.loadAll();
      return all
          .where((group) => selectedIds.contains(group.id))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// 用户输入「写入」规则：发送时替换用户输入后再入库与组装请求。
  Future<String> _applyUserWriteRules(
    String text,
    Set<String> selectedRegexRuleGroupIds,
  ) async {
    final groups = await _loadRegexGroups(selectedRegexRuleGroupIds);
    if (groups.isEmpty) return text;
    return RegexReplacementService()
        .applyToMessage(
          text: text,
          groups: groups,
          isUserMessage: true,
          depth: 0,
          mode: RegexExecutionMode.store,
        )
        .text;
  }

  /// 助手输出「写入」规则：仅对最新一条助手消息生效。
  Future<String> _applyAssistantOutputRules(
    String text,
    Set<String> selectedRegexRuleGroupIds,
  ) async {
    final groups = await _loadRegexGroups(selectedRegexRuleGroupIds);
    if (groups.isEmpty) return text;
    return RegexReplacementService()
        .applyToMessage(
          text: text,
          groups: groups,
          isUserMessage: false,
          depth: 0,
          mode: RegexExecutionMode.store,
        )
        .text;
  }

  Future<ChatCompletionResult> _createCompletion(
    ResolvedApiConfig config, {
    required PromptAssemblyResult promptAssembly,
    required Preset preset,
    required bool useStreaming,
    required Set<String> selectedRegexRuleGroupIds,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    final requestMessages = [
      for (final message in promptAssembly.messages)
        {'role': message.role, 'content': message.content},
    ];

    return _createCompletionFromMessages(
      config,
      messages: requestMessages,
      preset: preset,
      useStreaming: useStreaming,
      selectedRegexRuleGroupIds: selectedRegexRuleGroupIds,
      cancellationToken: cancellationToken,
      onStreamProgress: onStreamProgress,
    );
  }

  Future<ChatCompletionResult> _createCompletionFromMessages(
    ResolvedApiConfig config, {
    required List<Map<String, dynamic>> messages,
    required Preset preset,
    required bool useStreaming,
    required Set<String> selectedRegexRuleGroupIds,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    final ruleGroups = await _loadRegexGroups(selectedRegexRuleGroupIds);
    final requestMessages = ruleGroups.isEmpty
        ? messages
        : RegexReplacementService().applyToRequestMessages(
            messages: messages,
            groups: ruleGroups,
          );

    final api = GetIt.instance<IOpenAiApiService>();
    if (!useStreaming) {
      return api.createChatCompletion(
        config,
        messages: requestMessages,
        defaults: _buildCompletionDefaults(preset, useStreaming: false),
        cancellationToken: cancellationToken,
      );
    }

    final textBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    try {
      await for (final progress in api.createStreamingChatCompletion(
        config,
        messages: requestMessages,
        defaults: _buildCompletionDefaults(preset, useStreaming: true),
        cancellationToken: cancellationToken,
      )) {
        if (progress.textDelta.isNotEmpty) {
          textBuffer.write(progress.textDelta);
        }
        if (progress.thinkingDelta.isNotEmpty) {
          thinkingBuffer.write(progress.thinkingDelta);
        }
        onStreamProgress?.call(progress);
      }
    } on ChatCompletionCancelledException {
      final partialText = textBuffer.toString().trim();
      if (partialText.isEmpty) {
        rethrow;
      }
      final partialThinking = thinkingBuffer.toString().trim();
      return ChatCompletionResult(
        text: partialText,
        thinkingChain: partialThinking.isEmpty ? null : partialThinking,
      );
    }

    final text = textBuffer.toString().trim();
    if (text.isEmpty) {
      throw const FormatException('聊天接口返回了空回复');
    }
    final thinking = thinkingBuffer.toString().trim();
    return ChatCompletionResult(
      text: text,
      thinkingChain: thinking.isEmpty ? null : thinking,
    );
  }

  List<ChatMessage> _truncateChatMessages(List<ChatMessage> messages) {
    return ChatMemoryService.truncateToRecentRounds(
      messages,
      memoryExtractionNotifier.value.recentRounds,
    );
  }

  Future<List<String>> _buildMemoryContext({
    required String sessionId,
    required List<ChatMessage> chatMessages,
  }) async {
    final memoryConfig = memoryExtractionNotifier.value;
    if (!memoryConfig.enabled) return const [];

    final pathIds = chatMessages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();
    if (pathIds.isEmpty) return const [];

    final memories = await ChatMemoryService.instance.getRecentBranchMemories(
      sessionId: sessionId,
      pathMessageIds: pathIds,
      count: memoryConfig.recallCount,
    );
    return memories.map((m) => m.content).toList();
  }

  Future<void> _tryAutoExtractMemories({
    required String sessionId,
    required String branchLeafId,
    required List<ChatMessage> chatMessages,
    required ChatMessage userMessage,
    required ChatMessage assistantMessage,
    required String characterName,
    required String userName,
    required String currentInput,
    required Map<String, String> cardData,
  }) async {
    final memoryConfig = memoryExtractionNotifier.value;
    if (!memoryConfig.enabled) return;
    if (memoryConfig.interval <= 0) return;

    final allMessages = [...chatMessages, userMessage, assistantMessage];
    final pathIds = chatMessages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();
    final newAssistantCount = await _countNewAssistantSinceLastExtraction(
      sessionId: sessionId,
      allMessages: allMessages,
      pathIds: pathIds,
    );
    if (newAssistantCount < memoryConfig.interval) return;

    await ChatMemoryService.instance.tryExtractAndSave(
      sessionId: sessionId,
      branchLeafId: branchLeafId,
      messages: allMessages,
      characterName: characterName,
      userName: userName,
      currentInput: currentInput,
      cardData: cardData,
    );
  }

  Future<int> _countNewAssistantSinceLastExtraction({
    required String sessionId,
    required List<ChatMessage> allMessages,
    required List<String> pathIds,
  }) async {
    final memories = await ChatMemoryService.instance.getBranchMemories(
      sessionId: sessionId,
      pathMessageIds: pathIds,
    );
    if (memories.isEmpty) {
      return allMessages.where((m) => !m.isMe).length;
    }
    final processedIds = memories.first.sourceMessageIds.toSet();
    return allMessages
        .where((m) => !m.isMe && m.id != null && !processedIds.contains(m.id))
        .length;
  }

  Map<String, dynamic> _buildCompletionDefaults(
    Preset preset, {
    required bool useStreaming,
  }) {
    return {
      'stream': useStreaming,
      if (preset.temperature != null) 'temperature': preset.temperature,
      if (preset.openaiMaxTokens > 0) 'max_tokens': preset.openaiMaxTokens,
      if (preset.extra['enable_reasoning'] == true) ...{
        'reasoning_effort': preset.extra['reasoning_effort'] ?? 'medium',
      },
    };
  }

  static Map<String, String> _extractCardData(Map<String, dynamic> cardJson) {
    final data = (cardJson['data'] as Map<String, dynamic>?) ?? cardJson;
    return {
      'personality': (data['personality'] as String?) ?? '',
      'description': (data['description'] as String?) ?? '',
      'scenario': (data['scenario'] as String?) ?? '',
    };
  }
}
