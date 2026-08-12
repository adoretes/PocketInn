import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/service_locator.dart';
import '../../data/api_configs.dart';
import '../../data/mock_user_settings.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/preset.dart';
import '../../models/world_book.dart';
import '../../services/api_config_service.dart';
import '../../services/chat_character_resolver.dart';
import '../../services/chat_database_service.dart';
import '../../services/chat_opening_message_builder.dart';
import '../../services/chat_service.dart';
import '../../services/chat_variable_service.dart';
import '../../services/openai_compatible_api_service.dart';
import '../../services/preset_service.dart';
import '../../services/regex_rule_group_service.dart';
import '../../services/world_book_service.dart';
import 'widgets/message_edit_dialog.dart';

/// 聊天页面的视图模型。
///
/// 持有原 [_ChatPageState] 的全部业务状态，通过 [ChangeNotifier]
/// 通知 UI 刷新。UI 层（[ChatPage]）仅负责组装子 Widget 与转发
/// 用户事件，不再直接持有 service 或业务状态。
///
/// 设计约束：
/// - 不持有 [BuildContext]，所有 SnackBar / 对话框 / 导航由 UI 层处理。
/// - 业务方法在失败时抛出异常，由 UI 层捕获并展示。
/// - [ChatCompletionCancelledException] 为用户主动终止，内部吞没不抛出。
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    this.preferredSessionId,
    this.draftCharacterId,
    this.draftTitle,
    this.draftSelectedUserSettingId,
    this.draftSelectedPresetId,
    this.draftSelectedWorldBookIds = const [],
    List<String> initialDraftOpeningMessages = const [],
  }) : _initialDraftOpeningMessages = initialDraftOpeningMessages {
    // 缓存 notifier 引用，避免 dispose 时再次查找 getIt（DI 容器可能已重置）。
    _chatDbChangeNotifier = getIt<ChatDatabaseService>().changeNotifier;
    _presetChangeNotifier = getIt<PresetService>().changeNotifier;
    apiConfigsNotifier.addListener(onApiConfigsChanged);
    selectedApiModelIdNotifier.addListener(onApiConfigsChanged);
    _chatDbChangeNotifier.addListener(onChatDatabaseChanged);
    _presetChangeNotifier.addListener(onPresetsChanged);
  }

  /// 来自 [ChatPage] 的初始会话偏好 ID。
  final String? preferredSessionId;

  /// 草稿会话相关参数（来自 [ChatPage.draft]）。
  final String? draftCharacterId;
  final String? draftTitle;
  final String? draftSelectedUserSettingId;
  final String? draftSelectedPresetId;
  final List<String> draftSelectedWorldBookIds;
  final List<String> _initialDraftOpeningMessages;

  /// 缓存构造时获取的 notifier，用于 dispose 时安全移除监听。
  late final ValueNotifier<int> _chatDbChangeNotifier;
  late final ValueNotifier<int> _presetChangeNotifier;

  // --- 业务状态字段 ---
  ChatSession? _activeSession;
  ResolvedChatCharacter? _activeCharacter;
  List<ChatMessage> _messages = [];
  List<WorldBook> _worldBooks = [];
  List<PresetSummary> _presets = [];
  List<RegexRuleGroupSummary> _regexRuleGroups = [];

  final Set<String> _selectedWorldBookIds = {};
  final Set<String> _selectedRegexRuleGroupIds = {};
  String? _selectedPresetId;
  String? _selectedUserSettingId;
  bool _isLoading = true;
  bool _isSwitchingSession = false;
  bool _isSending = false;
  bool _isImpersonating = false;
  bool _useStreaming = true;
  bool _isCheckingApiStatus = false;
  String? _apiStatusModelId;
  ApiConnectionTestResult? _apiStatusResult;
  ChatCompletionCancelToken? _activeCompletionCancelToken;
  ChatMessage? _pendingUserMessage;
  String? _regeneratingUserMessageId;
  String _streamingAssistantText = '';
  String _streamingThinkingChain = '';
  String _streamingImpersonationText = '';
  bool _isDraftSession = false;
  List<String> _draftOpeningAssistantMessages = const [];
  int _draftOpeningMessageIndex = 0;
  int _sessionLoadGeneration = 0;
  bool _isDisposed = false;

  /// 会话重新加载完成后的回调（由 UI 层注册，用于清理输入框等 UI 状态）。
  ///
  /// 原实现中 [_loadSession] 末尾会清空文本控制器；VM 不持有 UI 控件，
  /// 故通过此回调通知 UI 在每次会话加载完成后执行等价清理。
  VoidCallback? onSessionReloaded;

  // --- 状态读取器 ---
  ChatSession? get activeSession => _activeSession;
  ResolvedChatCharacter? get activeCharacter => _activeCharacter;
  List<ChatMessage> get messages => _messages;
  List<WorldBook> get worldBooks => _worldBooks;
  List<PresetSummary> get presets => _presets;
  List<RegexRuleGroupSummary> get regexRuleGroups => _regexRuleGroups;
  Set<String> get selectedWorldBookIds => _selectedWorldBookIds;
  Set<String> get selectedRegexRuleGroupIds => _selectedRegexRuleGroupIds;
  String? get selectedPresetId => _selectedPresetId;
  String? get selectedUserSettingId => _selectedUserSettingId;
  bool get isLoading => _isLoading;
  bool get isSwitchingSession => _isSwitchingSession;
  bool get isSending => _isSending;
  bool get isImpersonating => _isImpersonating;
  bool get useStreaming => _useStreaming;
  bool get isCheckingApiStatus => _isCheckingApiStatus;
  String? get apiStatusModelId => _apiStatusModelId;
  ApiConnectionTestResult? get apiStatusResult => _apiStatusResult;
  bool get isDraftSession => _isDraftSession;
  List<String> get draftOpeningAssistantMessages =>
      _draftOpeningAssistantMessages;
  int get draftOpeningMessageIndex => _draftOpeningMessageIndex;
  ChatMessage? get pendingUserMessage => _pendingUserMessage;
  String? get regeneratingUserMessageId => _regeneratingUserMessageId;
  String get streamingAssistantText => _streamingAssistantText;
  String get streamingThinkingChain => _streamingThinkingChain;

  /// 当前生效的可见消息列表（含待发送、流式中、重新生成占位）。
  List<ChatMessage> get visibleMessages {
    final items = List<ChatMessage>.from(_messages);
    final regeneratingUserMessageId = _regeneratingUserMessageId;
    if (regeneratingUserMessageId != null &&
        items.isNotEmpty &&
        !items.last.isMe &&
        items.last.parentId == regeneratingUserMessageId) {
      items.removeLast();
    }
    final pendingUserMessage = _pendingUserMessage;
    if (pendingUserMessage != null) {
      items.add(pendingUserMessage);
    }

    if (_isSending &&
        (_useStreaming ||
            _streamingAssistantText.isNotEmpty ||
            _streamingThinkingChain.isNotEmpty) &&
        _activeCharacter != null) {
      items.add(
        ChatMessage(
          text:
              _streamingAssistantText.isEmpty && _streamingThinkingChain.isEmpty
              ? '...'
              : _streamingAssistantText,
          isMe: false,
          thinkingChain: _streamingThinkingChain.isEmpty
              ? null
              : _streamingThinkingChain,
        ),
      );
    }
    return items;
  }

  /// 当前选中的用户设定（若未选中则回退到列表首项）。
  UserSetting? currentUserSetting() {
    final settings = userSettingsNotifier.value;
    if (settings.isEmpty) {
      return null;
    }
    final selectedId = _selectedUserSettingId;
    if (selectedId != null) {
      for (final item in settings) {
        if (item.id == selectedId) {
          return item;
        }
      }
    }
    return settings.first;
  }

  /// 解析当前用户名。
  String resolvedUserName() {
    return currentUserSetting()?.name ?? '默认用户';
  }

  /// 替换聊天变量占位符。
  String replaceChatVariables(String input) {
    return ChatVariableService.replacePlaceholders(
      input,
      characterName: _activeCharacter?.name ?? '角色',
      userName: resolvedUserName(),
    );
  }

  // --- 生命周期 ---

  /// 初始化页面：加载世界书、预设，随后加载草稿会话或常规会话。
  /// 同时并发刷新 API 状态（与原 initState 中 _refreshEnabledApiStatus 并行）。
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 并发触发 API 状态刷新（不等待，匹配原 initState 行为）。
    _refreshSelectedApiStatus();

    final books = await getIt<WorldBookService>().loadAll();
    final presets = await getIt<PresetService>().loadAllSummaries();
    final regexGroups = await RegexRuleGroupService.instance.loadAllSummaries();

    if (_isDisposed) {
      return;
    }

    _worldBooks = books;
    _presets = presets;
    _regexRuleGroups = regexGroups;
    notifyListeners();

    if (draftCharacterId != null) {
      await _loadDraftSession();
      return;
    }

    await _loadSession(preferredSessionId: preferredSessionId);
  }

  /// 全局 API 配置或选中模型变化时刷新 API 状态。
  Future<void> onApiConfigsChanged() => _refreshSelectedApiStatus();

  /// 聊天数据库变化时重新加载当前会话。
  Future<void> onChatDatabaseChanged() async {
    if (_isDraftSession) {
      return;
    }
    final sessionId = _activeSession?.id ?? preferredSessionId;
    if (sessionId == null || _isLoading || _isSwitchingSession || _isSending) {
      return;
    }
    await _loadSession(preferredSessionId: sessionId);
  }

  /// 预设列表变化时重新加载预设摘要。
  Future<void> onPresetsChanged() async {
    final presets = await getIt<PresetService>().loadAllSummaries();
    if (_isDisposed) {
      return;
    }
    _presets = presets;
    notifyListeners();
  }

  // --- 会话加载 ---

  Future<void> _loadDraftSession() async {
    final characterId = draftCharacterId;
    if (characterId == null) {
      return;
    }

    final loadGeneration = ++_sessionLoadGeneration;
    final resolvedCharacter = await getIt<ChatCharacterResolver>().resolveById(
      characterId,
    );
    if (_isDisposed || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    if (resolvedCharacter == null) {
      _activeSession = null;
      _activeCharacter = null;
      _messages = [];
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _isLoading = false;
      _isSwitchingSession = false;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final openingMessages = _initialDraftOpeningMessages
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final title = draftTitle?.trim().isNotEmpty == true
        ? draftTitle!.trim()
        : resolvedCharacter.name;

    final initialWorldBookIds = List<String>.from(draftSelectedWorldBookIds);
    _activeSession = ChatSession(
      id: '__draft_chat__${resolvedCharacter.id}',
      title: title,
      characterId: resolvedCharacter.id,
      selectedUserSettingId: draftSelectedUserSettingId,
      selectedWorldBookIds: initialWorldBookIds,
      selectedRegexRuleGroupIds: const [],
      selectedPresetId: draftSelectedPresetId,
      currentLeafMessageId: null,
      lastMessagePreview: openingMessages.isNotEmpty
          ? openingMessages.first
          : '',
      createdAt: now,
      updatedAt: now,
    );
    _activeCharacter = resolvedCharacter;
    _draftOpeningMessageIndex = 0;
    _messages = _buildDraftOpeningMessages(openingMessages);
    _selectedUserSettingId = draftSelectedUserSettingId;
    _selectedPresetId = draftSelectedPresetId;
    _selectedWorldBookIds
      ..clear()
      ..addAll(initialWorldBookIds);
    _selectedRegexRuleGroupIds.clear();
    _isDraftSession = true;
    _draftOpeningAssistantMessages = openingMessages;
    _isLoading = false;
    _isSwitchingSession = false;
    notifyListeners();
  }

  List<ChatMessage> _buildDraftOpeningMessages(List<String> openingMessages) {
    if (openingMessages.isEmpty) {
      return const [];
    }
    final index = _draftOpeningMessageIndex.clamp(
      0,
      openingMessages.length - 1,
    );
    return [
      ChatMessage(
        text: openingMessages[index],
        isMe: false,
        index: index + 1,
        total: openingMessages.length,
      ),
    ];
  }

  Future<void> loadWorldBooks() async {
    final books = await getIt<WorldBookService>().loadAll();
    if (_isDisposed) {
      return;
    }
    _worldBooks = books;
    notifyListeners();
  }

  Future<void> loadRegexRuleGroups() async {
    final groups = await RegexRuleGroupService.instance.loadAllSummaries();
    if (_isDisposed) {
      return;
    }
    _regexRuleGroups = groups;
    notifyListeners();
  }

  Future<void> _loadSession({String? preferredSessionId}) async {
    final loadGeneration = ++_sessionLoadGeneration;
    final summaries = await getIt<ChatDatabaseService>().loadSessionSummaries();
    if (_isDisposed || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    if (summaries.isEmpty) {
      _activeSession = null;
      _activeCharacter = null;
      _messages = [];
      _selectedUserSettingId = null;
      _selectedPresetId = null;
      _selectedWorldBookIds.clear();
      _selectedRegexRuleGroupIds.clear();
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _draftOpeningMessageIndex = 0;
      _isLoading = false;
      _isSwitchingSession = false;
      notifyListeners();
      return;
    }

    final targetSummary = summaries.firstWhere(
      (item) => item.id == preferredSessionId,
      orElse: () => summaries.first,
    );
    final bundle = await getIt<ChatDatabaseService>().loadSessionBundle(
      targetSummary.id,
    );
    if (_isDisposed || loadGeneration != _sessionLoadGeneration) {
      return;
    }
    if (bundle == null) {
      _isLoading = false;
      _isSwitchingSession = false;
      notifyListeners();
      return;
    }

    final resolvedCharacter = await getIt<ChatCharacterResolver>().resolveById(
      bundle.session.characterId,
    );
    if (_isDisposed || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    _activeSession = bundle.session;
    _activeCharacter = resolvedCharacter;
    _messages = bundle.activeMessages;
    _selectedUserSettingId = bundle.session.selectedUserSettingId;
    _selectedPresetId = bundle.session.selectedPresetId;
    _selectedWorldBookIds
      ..clear()
      ..addAll(bundle.session.selectedWorldBookIds);
    _selectedRegexRuleGroupIds
      ..clear()
      ..addAll(bundle.session.selectedRegexRuleGroupIds);
    _isDraftSession = false;
    _draftOpeningAssistantMessages = const [];
    _draftOpeningMessageIndex = 0;
    _isLoading = false;
    if (_isSwitchingSession) {
      _resetPendingMessages();
    }
    _isSwitchingSession = false;
    notifyListeners();
    onSessionReloaded?.call();
  }

  /// 从侧边栏选择一个会话。返回是否已开始切换（false 表示当前正在发送）。
  bool selectSession(String sessionId) {
    if (_isSending || _isImpersonating) {
      return false;
    }
    if (sessionId == _activeSession?.id) {
      return false;
    }
    _isSwitchingSession = true;
    notifyListeners();
    _loadSession(preferredSessionId: sessionId);
    return true;
  }

  Future<void> _persistSessionConfig() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    if (_isDraftSession) {
      _activeSession = session.copyWith(
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
        selectedPresetId: _selectedPresetId,
      );
      notifyListeners();
      return;
    }

    await getIt<ChatDatabaseService>().updateSessionConfig(
      sessionId: session.id,
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
      selectedPresetId: _selectedPresetId,
    );
    if (_isDisposed) {
      return;
    }
    _activeSession = session.copyWith(
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
      selectedPresetId: _selectedPresetId,
    );
    notifyListeners();
  }

  Future<ChatSession> _persistDraftSession() async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (!_isDraftSession || session == null || character == null) {
      if (session == null) {
        throw StateError('当前没有可保存的聊天');
      }
      return session;
    }

    final createdSession = await getIt<ChatDatabaseService>().createSession(
      characterId: character.id,
      title: session.title,
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
      selectedPresetId: _selectedPresetId,
      openingAssistantMessages: _draftOpeningAssistantMessages,
      activeOpeningMessageIndex: _draftOpeningMessageIndex,
    );

    _activeSession = createdSession;
    _isDraftSession = false;
    _draftOpeningAssistantMessages = const [];
    _draftOpeningMessageIndex = 0;
    notifyListeners();

    return createdSession;
  }

  // --- API 状态 ---

  Future<void> _refreshSelectedApiStatus() async {
    final config = resolvedSelectedApi;
    if (config == null) {
      if (_isDisposed) {
        return;
      }
      _isCheckingApiStatus = false;
      _apiStatusModelId = null;
      _apiStatusResult = null;
      notifyListeners();
      return;
    }

    _isCheckingApiStatus = true;
    _apiStatusModelId = selectedApiModelIdNotifier.value;
    notifyListeners();

    final result = await getIt<OpenAICompatibleApiService>().testConnection(
      config,
    );
    if (_isDisposed ||
        selectedApiModelIdNotifier.value != _apiStatusModelId) {
      return;
    }

    _isCheckingApiStatus = false;
    _apiStatusModelId = selectedApiModelIdNotifier.value;
    _apiStatusResult = result;
    notifyListeners();
  }

  /// 选择某个模型。直接委托给全局 [selectApiModel]（来自 data/api_configs.dart）。
  ///
  /// 选择状态变化会触发 [selectedApiModelIdNotifier]，本 VM 在构造时已注册监听，
  /// 故 [_refreshSelectedApiStatus] 会自动执行，无需在此显式调用。
  Future<void> selectApiModel(String modelId) async {
    // 显式调用顶层函数（通过 getIt 间接拿到 Service 不可行，
    // 这里直接复用全局辅助），使用 ApiConfigService 单例完成持久化。
    selectedApiModelIdNotifier.value = modelId;
    await ApiConfigService.instance.saveSelectedModelId(modelId);
  }

  // --- 发送 / 重新生成 ---

  /// 发送一条用户消息。[rawText] 为未经变量替换的原始输入。
  Future<void> sendMessage(String rawText) async {
    final session = _activeSession;
    final character = _activeCharacter;
    final text = replaceChatVariables(rawText.trim()).trim();
    if (text.isEmpty ||
        session == null ||
        character == null ||
        _isSwitchingSession ||
        _isSending ||
        _isImpersonating) {
      return;
    }

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    _isSending = true;
    _pendingUserMessage = ChatMessage(text: text, isMe: true);
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    notifyListeners();

    ChatSession? persistedSession;

    try {
      await getIt<ChatService>().sendMessage(
        session: session,
        character: character,
        chatMessages: _messages,
        input: text,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (_isDisposed) {
            return;
          }
          if (progress.textDelta.isNotEmpty) {
            _streamingAssistantText += progress.textDelta;
          }
          if (progress.thinkingDelta.isNotEmpty) {
            _streamingThinkingChain += progress.thinkingDelta;
          }
          notifyListeners();
        },
        persistSession: _isDraftSession
            ? () async {
                final createdSession = await _persistDraftSession();
                persistedSession = createdSession;
                return createdSession;
              }
            : null,
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } finally {
      _resetPendingMessages();
      final reloadSessionId = persistedSession?.id;
      if (reloadSessionId != null || !_isDraftSession) {
        await _loadSession(preferredSessionId: reloadSessionId ?? session.id);
      }
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        notifyListeners();
      }
    }
  }

  /// 终止当前进行中的流式请求。
  void stopStreaming() {
    _activeCompletionCancelToken?.cancel();
  }

  Future<void> regenerateFromUserMessage({
    required int userMessageIndex,
    String? editedText,
    ChatMessage? userMessageOverride,
    List<ChatMessage>? historyBeforeOverride,
  }) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isSending || _isImpersonating) {
      return;
    }
    if (userMessageIndex < 0 || userMessageIndex >= _messages.length) {
      return;
    }

    final originalUserMessage =
        userMessageOverride ?? _messages[userMessageIndex];
    if (!originalUserMessage.isMe || originalUserMessage.id == null) {
      return;
    }

    final userMessage = ChatMessage(
      id: originalUserMessage.id,
      sessionId: originalUserMessage.sessionId,
      parentId: originalUserMessage.parentId,
      text: editedText ?? originalUserMessage.text,
      isMe: true,
      index: originalUserMessage.index,
      total: originalUserMessage.total,
      siblingIds: originalUserMessage.siblingIds,
    );
    final historyBeforeUserMessage =
        historyBeforeOverride ??
        _messages.take(userMessageIndex).toList(growable: false);

    _isSending = true;
    _pendingUserMessage = null;
    _regeneratingUserMessageId = userMessage.id;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    notifyListeners();

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    try {
      await getIt<ChatService>().regenerateAssistantResponse(
        session: session,
        character: character,
        historyBeforeUserMessage: historyBeforeUserMessage,
        userMessage: userMessage,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (_isDisposed) {
            return;
          }
          if (progress.textDelta.isNotEmpty) {
            _streamingAssistantText += progress.textDelta;
          }
          if (progress.thinkingDelta.isNotEmpty) {
            _streamingThinkingChain += progress.thinkingDelta;
          }
          notifyListeners();
        },
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } finally {
      _resetPendingMessages();
      await _loadSession(preferredSessionId: session.id);
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        notifyListeners();
      }
    }
  }

  /// 重新生成指定位置的角色消息（其上一条为用户消息）。
  Future<void> regenerateMessage(int assistantMessageIndex) async {
    if (_isSending || _isImpersonating) {
      return;
    }
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null) {
      return;
    }
    if (assistantMessageIndex <= 0 ||
        assistantMessageIndex >= _messages.length) {
      return;
    }

    final userMessage = _messages[assistantMessageIndex - 1];
    if (!userMessage.isMe || userMessage.id == null) {
      return;
    }

    await regenerateFromUserMessage(
      userMessageIndex: assistantMessageIndex - 1,
    );
  }

  /// 继续推进：基于最后一条角色消息生成新的角色消息。
  Future<void> continueAssistantMessage(int assistantMessageIndex) async {
    if (_isSending || _isImpersonating) {
      return;
    }
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null) {
      return;
    }
    if (assistantMessageIndex < 0 ||
        assistantMessageIndex >= _messages.length) {
      return;
    }
    if (assistantMessageIndex != _messages.length - 1) {
      return;
    }

    final lastAssistantMessage = _messages[assistantMessageIndex];
    if (lastAssistantMessage.isMe || lastAssistantMessage.id == null) {
      return;
    }

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    _isSending = true;
    _pendingUserMessage = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    notifyListeners();

    try {
      await getIt<ChatService>().continueAssistantResponse(
        session: session,
        character: character,
        chatMessages: _messages,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (_isDisposed) {
            return;
          }
          if (progress.textDelta.isNotEmpty) {
            _streamingAssistantText += progress.textDelta;
          }
          if (progress.thinkingDelta.isNotEmpty) {
            _streamingThinkingChain += progress.thinkingDelta;
          }
          notifyListeners();
        },
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } finally {
      _resetPendingMessages();
      await _loadSession(preferredSessionId: session.id);
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        notifyListeners();
      }
    }
  }

  /// 助手帮答：生成一条用户回复文本，由 UI 层填入输入框。
  /// 返回 null 表示当前不可用或被取消。
  /// [onProgress] 在流式生成时回调累积文本。
  Future<String?> generateUserReply({
    void Function(String accumulatedText)? onProgress,
  }) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null) {
      return null;
    }
    if (_isSending || _isImpersonating || _isSwitchingSession) {
      return null;
    }
    if (_messages.isEmpty) {
      return null;
    }

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    _isImpersonating = true;
    _streamingImpersonationText = '';
    notifyListeners();

    try {
      return await getIt<ChatService>().generateUserReply(
        session: session,
        character: character,
        chatMessages: _messages,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (_isDisposed) {
            return;
          }
          if (progress.textDelta.isNotEmpty) {
            _streamingImpersonationText += progress.textDelta;
            onProgress?.call(_streamingImpersonationText);
          }
        },
      );
    } on ChatCompletionCancelledException {
      return null;
    } finally {
      _isImpersonating = false;
      _streamingImpersonationText = '';
      if (identical(_activeCompletionCancelToken, cancellationToken)) {
        _activeCompletionCancelToken = null;
      }
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  // --- 消息操作 ---

  /// 编辑消息。[text] 为对话框返回的已规范化文本（用户消息未做变量替换）。
  Future<void> editMessage(
    int index,
    String text,
    MessageEditAction action,
  ) async {
    final session = _activeSession;
    final message = index >= 0 && index < _messages.length
        ? _messages[index]
        : null;
    if (session == null ||
        message == null ||
        message.id == null ||
        _isSending) {
      return;
    }
    final editingMessage = message;

    var normalizedText = text;
    if (editingMessage.isMe) {
      normalizedText = replaceChatVariables(normalizedText).trim();
    } else {
      normalizedText = normalizedText.trim();
    }

    if (editingMessage.isMe && action == MessageEditAction.saveAndSend) {
      final editedNode = await getIt<ChatDatabaseService>()
          .branchMessageFromEdit(
            sessionId: session.id,
            messageId: editingMessage.id!,
            text: normalizedText,
          );

      await regenerateFromUserMessage(
        userMessageIndex: index,
        userMessageOverride: ChatMessage(
          id: editedNode.id,
          sessionId: editedNode.sessionId,
          parentId: editedNode.parentId,
          text: editedNode.text,
          isMe: true,
        ),
        historyBeforeOverride: _messages.take(index).toList(growable: false),
      );
      return;
    }

    await getIt<ChatDatabaseService>().updateMessage(
      sessionId: session.id,
      messageId: editingMessage.id!,
      text: normalizedText,
      thinkingChain: editingMessage.isMe ? null : editingMessage.thinkingChain,
      clearThinkingChain:
          editingMessage.isMe || editingMessage.thinkingChain == null,
    );

    if (action == MessageEditAction.saveAndSend) {
      await regenerateFromUserMessage(
        userMessageIndex: index,
        editedText: normalizedText,
      );
      return;
    }

    await _loadSession(preferredSessionId: session.id);
  }

  /// 编辑草稿会话的开场消息。
  Future<void> editDraftOpeningMessage(String text) async {
    final session = _activeSession;
    if (!_isDraftSession ||
        session == null ||
        _isSending ||
        _draftOpeningAssistantMessages.isEmpty) {
      return;
    }
    final editingIndex = _draftOpeningMessageIndex.clamp(
      0,
      _draftOpeningAssistantMessages.length - 1,
    );

    final normalizedText = text.trim();
    final nextOpeningMessages = List<String>.from(
      _draftOpeningAssistantMessages,
    );
    nextOpeningMessages[editingIndex] = normalizedText;
    _draftOpeningAssistantMessages = nextOpeningMessages;
    _messages = _buildDraftOpeningMessages(nextOpeningMessages);
    _activeSession = session.copyWith(lastMessagePreview: normalizedText);
    notifyListeners();
  }

  /// 删除指定位置的消息分支。
  Future<void> deleteMessage(int index) async {
    final session = _activeSession;
    final message = index >= 0 && index < _messages.length
        ? _messages[index]
        : null;
    if (session == null || message?.id == null || _isSending) {
      return;
    }

    await getIt<ChatDatabaseService>().deleteMessageBranch(
      sessionId: session.id,
      messageId: message!.id!,
    );
    await _loadSession(preferredSessionId: session.id);
  }

  /// 切换消息变体（分支）。[delta] 为 -1 或 1。
  Future<void> switchMessageVariant(ChatMessage message, int delta) async {
    if (_isDraftSession) {
      if (message.isMe || _draftOpeningAssistantMessages.length <= 1) {
        return;
      }
      final nextIndex = (_draftOpeningMessageIndex + delta).clamp(
        0,
        _draftOpeningAssistantMessages.length - 1,
      );
      if (nextIndex == _draftOpeningMessageIndex) {
        return;
      }
      _draftOpeningMessageIndex = nextIndex;
      _messages = _buildDraftOpeningMessages(_draftOpeningAssistantMessages);
      _activeSession = _activeSession?.copyWith(
        lastMessagePreview:
            _draftOpeningAssistantMessages[_draftOpeningMessageIndex],
      );
      notifyListeners();
      return;
    }

    final session = _activeSession;
    if (session == null || message.id == null || message.siblingIds.isEmpty) {
      return;
    }

    final currentIndex = message.index - 1;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= message.siblingIds.length) {
      return;
    }

    await getIt<ChatDatabaseService>().switchActiveBranch(
      sessionId: session.id,
      parentMessageId: message.parentId,
      childMessageId: message.siblingIds[nextIndex],
    );
    await _loadSession(preferredSessionId: session.id);
  }

  // --- 会话配置操作 ---

  /// 更新选中的用户设定并持久化。
  Future<void> setSelectedUserSettingId(String id) async {
    _selectedUserSettingId = id;
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 切换世界书选中状态并持久化。
  Future<void> toggleWorldBook(String id) async {
    if (_selectedWorldBookIds.contains(id)) {
      _selectedWorldBookIds.remove(id);
    } else {
      _selectedWorldBookIds.add(id);
    }
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 切换正则规则组选中状态并持久化。
  Future<void> toggleRegexRuleGroup(String id) async {
    if (_selectedRegexRuleGroupIds.contains(id)) {
      _selectedRegexRuleGroupIds.remove(id);
    } else {
      _selectedRegexRuleGroupIds.add(id);
    }
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 更新选中的预设并持久化。
  Future<void> setSelectedPresetId(String id) async {
    _selectedPresetId = id;
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 更新流式开关。
  void setUseStreaming(bool value) {
    _useStreaming = value;
    notifyListeners();
  }

  /// 重命名当前会话标题。
  Future<void> renameChatTitle(String title) async {
    final session = _activeSession;
    if (session == null) {
      return;
    }
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || normalizedTitle == session.title) {
      return;
    }

    if (_isDraftSession) {
      _activeSession = session.copyWith(title: normalizedTitle);
      notifyListeners();
      return;
    }

    await getIt<ChatDatabaseService>().updateSessionTitle(
      sessionId: session.id,
      title: normalizedTitle,
    );
    if (_isDisposed) {
      return;
    }
    _activeSession = session.copyWith(title: normalizedTitle);
    notifyListeners();
  }

  /// 重置当前聊天（按当前选择重新初始化）。成功完成不抛异常。
  Future<void> resetChat(String nextTitle) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isSending) {
      return;
    }

    final selectedUserSettingId = currentUserSetting()?.id;
    final openingMessages = ChatOpeningMessageBuilder.build(
      characterCardData: character.cardJson,
      characterName: character.name,
      userName: resolvedUserName(),
    );

    if (_isDraftSession) {
      _resetPendingMessages();
      _draftOpeningMessageIndex = 0;
      _draftOpeningAssistantMessages = openingMessages;
      _messages = _buildDraftOpeningMessages(openingMessages);
      _selectedUserSettingId = selectedUserSettingId;
      _activeSession = session.copyWith(
        title: nextTitle,
        selectedUserSettingId: selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
        selectedPresetId: _selectedPresetId,
        lastMessagePreview: openingMessages.isNotEmpty
            ? openingMessages.first
            : '',
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    _resetPendingMessages();
    notifyListeners();

    try {
      await getIt<ChatDatabaseService>().resetSession(
        sessionId: session.id,
        title: nextTitle,
        selectedUserSettingId: selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
        selectedPresetId: _selectedPresetId,
        openingAssistantMessages: openingMessages,
      );
      await _loadSession(preferredSessionId: session.id);
    } catch (error) {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// 处理用户设定被删除后的状态同步。
  Future<void> handleUserSettingDeleted(String settingId) async {
    await deleteUserSetting(settingId);
    if (_selectedUserSettingId == settingId) {
      _selectedUserSettingId = userSettingsNotifier.value.isNotEmpty
          ? userSettingsNotifier.value.first.id
          : null;
    }
    notifyListeners();
  }

  /// 处理用户设定被更新。
  Future<void> handleUserSettingUpdated(UserSetting setting) async {
    await updateUserSetting(setting);
    notifyListeners();
  }

  // --- 测试辅助 ---

  /// 仅供测试使用：批量覆盖内部状态，便于在不依赖 service 的前提下
  /// 测试 [visibleMessages]、[sendMessage] 守卫等纯逻辑。
  @visibleForTesting
  void setStateForTesting({
    ChatSession? activeSession,
    ResolvedChatCharacter? activeCharacter,
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isSwitchingSession,
    bool? useStreaming,
    ChatMessage? pendingUserMessage,
    String? regeneratingUserMessageId,
    String? streamingAssistantText,
    String? streamingThinkingChain,
    bool? isDraftSession,
    String? selectedUserSettingId,
    String? selectedPresetId,
  }) {
    if (activeSession != null) _activeSession = activeSession;
    if (activeCharacter != null) _activeCharacter = activeCharacter;
    if (messages != null) _messages = messages;
    if (isSending != null) _isSending = isSending;
    if (isSwitchingSession != null) _isSwitchingSession = isSwitchingSession;
    if (useStreaming != null) _useStreaming = useStreaming;
    _pendingUserMessage = pendingUserMessage;
    _regeneratingUserMessageId = regeneratingUserMessageId;
    if (streamingAssistantText != null) {
      _streamingAssistantText = streamingAssistantText;
    }
    if (streamingThinkingChain != null) {
      _streamingThinkingChain = streamingThinkingChain;
    }
    if (isDraftSession != null) _isDraftSession = isDraftSession;
    if (selectedUserSettingId != null) {
      _selectedUserSettingId = selectedUserSettingId;
    }
    if (selectedPresetId != null) _selectedPresetId = selectedPresetId;
  }

  // --- 私有辅助 ---

  void _resetPendingMessages() {
    _pendingUserMessage = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
  }

  @override
  void dispose() {
    _isDisposed = true;
    apiConfigsNotifier.removeListener(onApiConfigsChanged);
    selectedApiModelIdNotifier.removeListener(onApiConfigsChanged);
    _chatDbChangeNotifier.removeListener(onChatDatabaseChanged);
    _presetChangeNotifier.removeListener(onPresetsChanged);
    _activeCompletionCancelToken?.cancel();
    super.dispose();
  }
}
