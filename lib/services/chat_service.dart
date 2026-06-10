import 'dart:async';
import 'dart:io';

import '../data/api_configs.dart';
import '../data/mock_user_settings.dart';
import '../models/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/preset.dart';
import '../models/prompt_assembly.dart';
import '../models/world_book.dart';
import 'chat_character_resolver.dart';
import 'chat_database_service.dart';
import 'chat_memory_service.dart';
import 'openai_compatible_api_service.dart';
import 'preset_service.dart';
import 'prompt_assembler.dart';
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
    bool useStreaming = false,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
    Future<ChatSession> Function()? persistSession,
  }) async {
    final normalizedInput = input.trim();
    if (normalizedInput.isEmpty) {
      throw const FormatException('消息不能为空');
    }

    final config = enabledApiConfig?.copyWith();
    if (config == null) {
      throw StateError('当前没有启用的 API 配置');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前启用的 API 配置未填写 Model');
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

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: chatMessages,
        currentInput: normalizedInput,
        memoryContext: memoryContext,
      ),
    );
    cancellationToken?.throwIfCancelled();

    final activeSession = persistSession == null
        ? session
        : await persistSession();

    final userNode = await ChatDatabaseService.instance.appendUserMessage(
      sessionId: activeSession.id,
      parentMessageId: activeSession.currentLeafMessageId,
      text: normalizedInput,
    );

    try {
      final completion = await _createCompletion(
        config,
        promptAssembly: promptAssembly,
        preset: preset,
        useStreaming: useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );

      final assistantNode = await ChatDatabaseService.instance
          .appendAssistantMessage(
            sessionId: activeSession.id,
            parentMessageId: userNode.id,
            text: completion.text,
            thinkingChain: completion.thinkingChain,
          );

      unawaited(_tryAutoExtractMemories(
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
      ));

      return ChatSendResult(
        userNode: userNode,
        assistantNode: assistantNode,
        promptAssembly: promptAssembly,
        completion: completion,
      );
    } on SocketException catch (_) {
      rethrow;
    } on HttpException catch (_) {
      rethrow;
    } on FormatException catch (_) {
      rethrow;
    } on StateError catch (_) {
      rethrow;
    } on ChatCompletionCancelledException catch (_) {
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

    final config = enabledApiConfig?.copyWith();
    if (config == null) {
      throw StateError('当前没有启用的 API 配置');
    }
    if (config.model.trim().isEmpty) {
      throw const FormatException('当前启用的 API 配置未填写 Model');
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
      chatMessages: historyBeforeUserMessage,
    );

    final promptAssembly = PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: worldBooks,
        chatMessages: historyBeforeUserMessage,
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
        cancellationToken: cancellationToken,
        onStreamProgress: onStreamProgress,
      );

      final assistantNode = await ChatDatabaseService.instance
          .appendAssistantMessage(
            sessionId: session.id,
            parentMessageId: userMessage.id,
            text: completion.text,
            thinkingChain: completion.thinkingChain,
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
    } on SocketException catch (_) {
      rethrow;
    } on HttpException catch (_) {
      rethrow;
    } on FormatException catch (_) {
      rethrow;
    } on StateError catch (_) {
      rethrow;
    } on ChatCompletionCancelledException catch (_) {
      rethrow;
    } catch (error) {
      throw StateError('重新生成聊天回复失败: $error');
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

  Future<ChatCompletionResult> _createCompletion(
    ApiConfig config, {
    required PromptAssemblyResult promptAssembly,
    required Preset preset,
    required bool useStreaming,
    ChatCompletionCancelToken? cancellationToken,
    void Function(ChatCompletionProgress progress)? onStreamProgress,
  }) async {
    final requestMessages = [
      for (final message in promptAssembly.messages)
        {'role': message.role, 'content': message.content},
    ];

    if (!useStreaming) {
      return OpenAICompatibleApiService.instance.createChatCompletion(
        config,
        messages: requestMessages,
        defaults: _buildCompletionDefaults(preset, useStreaming: false),
        cancellationToken: cancellationToken,
      );
    }

    final textBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    try {
      await for (final progress
          in OpenAICompatibleApiService.instance.createStreamingChatCompletion(
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
  }) async {
    final memoryConfig = memoryExtractionNotifier.value;
    if (!memoryConfig.enabled) return;
    if (memoryConfig.interval <= 0) return;

    final allMessages = [
      ...chatMessages,
      userMessage,
      assistantMessage,
    ];
    final pathIds = chatMessages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();
    final newAssistantCount =
        await _countNewAssistantSinceLastExtraction(
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
      'temperature': preset.temperature,
      'top_p': preset.topP,
      'frequency_penalty': preset.frequencyPenalty,
      'presence_penalty': preset.presencePenalty,
      if (preset.openaiMaxTokens > 0) 'max_tokens': preset.openaiMaxTokens,
    };
  }
}
