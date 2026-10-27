import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../core/service_locator.dart';
import '../../data/api_configs.dart';
import '../../data/app_settings.dart';
import '../../data/mock_user_settings.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/preset.dart';
import '../../models/world_book.dart';
import '../../services/api_config_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/chat_character_resolver.dart';
import '../../services/chat_database_service.dart';
import '../../services/chat_opening_message_builder.dart';
import '../../services/chat_service.dart';
import '../../services/chat_variable_service.dart';
import '../../services/openai_compatible_api_service.dart';
import '../../services/post_task_scheduler.dart';
import '../../services/preset_service.dart';
import '../../services/regex_rule_group_service.dart';
import '../../services/status_extraction_service.dart';
import '../../services/variable_state_service.dart';
import '../../services/world_book_service.dart';
import 'streaming_message_snapshot.dart';
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
  int? _replyToMessageIndex;
  bool _galModeEnabled = false;
  int? _galBrowsingIndex;
  List<String> _galChoices = const [];
  bool _isGeneratingGalChoices = false;
  String? _galChoicesMessageId;
  int _galChoicesRequestGeneration = 0;
  bool _galChoicesError = false;
  ChatCompletionCancelToken? _galChoicesCancelToken;
  String? _regeneratingUserMessageId;
  String _streamingAssistantText = '';
  String _streamingThinkingChain = '';
  String _streamingImpersonationText = '';

  /// 流式正文/思考链的高频发布通道。
  ///
  /// 该通道独立于 [notifyListeners]，只让流式中那条气泡订阅，避免每个
  /// token 都重建页面骨架、历史消息与输入区。发布节奏由
  /// [_scheduleStreamingPublish] 合并到下一帧。
  final ValueNotifier<StreamingMessageSnapshot> _streamingSnapshotNotifier =
      ValueNotifier<StreamingMessageSnapshot>(StreamingMessageSnapshot.empty);

  /// 本帧是否已注册过发布回调（同一帧内多次增量只发布一次）。
  bool _streamingPublishScheduled = false;

  /// 待执行帧回调的 id，用于结束流式或销毁时取消。
  int? _streamingPublishCallbackId;

  bool _isDraftSession = false;
  List<String> _draftOpeningAssistantMessages = const [];
  int _draftOpeningMessageIndex = 0;
  int _sessionLoadGeneration = 0;
  bool _isDisposed = false;

  /// 正在进行中的数据库变化重载任务；并发广播复用它而不是再跑一遍。
  Future<void>? _dbReloadTask;

  /// 本轮重载期间又收到了数据变化广播，结束后需要补跑一次。
  bool _dbReloadPending = false;

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
  bool get galModeEnabled => _galModeEnabled;

  /// Gal 模式下正在浏览的历史消息索引；null 表示跟随最新消息。
  int? get galBrowsingIndex => _galBrowsingIndex;

  /// 更新浏览索引（Gal 视图回看/推进时回写）。
  void setGalBrowsingIndex(int? index) {
    if (_galBrowsingIndex == index) return;
    _galBrowsingIndex = index;
    notifyListeners();
  }

  List<String> get galChoices => _galChoices;
  bool get isGeneratingGalChoices => _isGeneratingGalChoices;

  /// 选项归属的角色消息 ID；与当前展示消息不一致时 UI 不显示选项。
  String? get galChoicesMessageId => _galChoicesMessageId;

  /// 上一次选项生成是否失败；UI 据此显示重试入口。
  bool get galChoicesError => _galChoicesError;
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
  int? get replyToMessageIndex => _replyToMessageIndex;
  String? get regeneratingUserMessageId => _regeneratingUserMessageId;
  String get streamingAssistantText => _streamingAssistantText;
  String get streamingThinkingChain => _streamingThinkingChain;

  /// 流式正文/思考链的只读订阅入口（按帧合并，内容不变时不通知）。
  ValueListenable<StreamingMessageSnapshot> get streamingMessageListenable =>
      _streamingSnapshotNotifier;

  /// 当前生效的可见消息列表（含待发送、流式中、重新生成占位）。
  List<ChatMessage> get visibleMessages {
    final items = List<ChatMessage>.from(_messages);

    // 从历史消息处回复/重新生成时，旧分支尾部已不再属于新路径，
    // 先截断到目标消息，保证流式占位显示在正确位置。
    final replyToMessageIndex = _replyToMessageIndex;
    if (replyToMessageIndex != null &&
        replyToMessageIndex >= 0 &&
        replyToMessageIndex < items.length - 1) {
      items.removeRange(replyToMessageIndex + 1, items.length);
    }

    final regeneratingUserMessageId = _regeneratingUserMessageId;
    if (regeneratingUserMessageId != null) {
      final regeneratingIndex = items.indexWhere(
        (m) => m.id == regeneratingUserMessageId,
      );
      if (regeneratingIndex >= 0 && regeneratingIndex < items.length - 1) {
        items.removeRange(regeneratingIndex + 1, items.length);
      } else if (items.isNotEmpty &&
          !items.last.isMe &&
          items.last.parentId == regeneratingUserMessageId) {
        items.removeLast();
      }
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
  ///
  /// 一次用户操作往往连续写入多行并连续广播多次。并发的广播不再各跑一遍
  /// 完整加载（那会重复执行同一批 SQL，且只有最后一份结果被采用），而是
  /// 复用正在进行的那一轮，并在结束后补跑一次以覆盖期间的新写入。
  Future<void> onChatDatabaseChanged() async {
    if (_isDraftSession) {
      return;
    }
    final sessionId = _activeSession?.id ?? preferredSessionId;
    if (sessionId == null || _isLoading || _isSwitchingSession || _isSending) {
      return;
    }

    final running = _dbReloadTask;
    if (running != null) {
      // 已有一轮在跑：登记一次补跑，并等它（含补跑）结束。
      _dbReloadPending = true;
      await running;
      return;
    }

    final task = _runDbReload(sessionId);
    _dbReloadTask = task;
    try {
      await task;
    } finally {
      if (identical(_dbReloadTask, task)) {
        _dbReloadTask = null;
      }
    }
  }

  /// 串行执行数据库变化触发的重载：跑完当前一轮后，若期间又收到广播则再跑一轮。
  Future<void> _runDbReload(String sessionId) async {
    try {
      do {
        _dbReloadPending = false;
        // 初始化/切换已在加载另一条会话时，旧会话的数据库广播不得覆盖它。
        final loadGeneration = _sessionLoadGeneration;
        // 后台写入触发的主体数据变化不应清空用户正在编辑的输入框。
        // 若目标会话已不存在并回退到其他会话，则需要清空，避免草稿串台。
        await _loadSession(
          preferredSessionId: sessionId,
          notifyReloaded: false,
        );
        if (_isDisposed || loadGeneration + 1 != _sessionLoadGeneration) {
          return;
        }
        if (_activeSession?.id != sessionId) {
          onSessionReloaded?.call();
        }
      } while (_dbReloadPending);
    } finally {
      _dbReloadPending = false;
    }
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
    _galModeEnabled = false;
    _galBrowsingIndex = null;
    _clearGalChoices();
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

  /// 加载会话数据。
  ///
  /// [notifyReloaded] 为 false 时跳过 [onSessionReloaded]（输入框清理）：
  /// 生成结束后的重载不应清掉用户在结果展示后立刻输入的草稿。
  Future<void> _loadSession({
    String? preferredSessionId,
    bool notifyReloaded = true,
  }) async {
    final loadGeneration = ++_sessionLoadGeneration;
    final database = getIt<ChatDatabaseService>();
    // 未指定会话时优先恢复上次选择的聊天，而不是最近更新的那条。
    // 直接按 id 读（主键索引），避免为挑一条会话而整表扫描 chat_sessions。
    final targetSessionId = preferredSessionId ?? _rememberedSessionId();
    ChatSessionBundle? bundle = targetSessionId == null
        ? null
        : await database.loadSessionBundle(targetSessionId);
    if (bundle == null) {
      // 没有记忆目标，或该会话已被删除：回退到最近更新的一条。
      final latestSessionId = await database.loadLatestSessionId();
      if (latestSessionId != null) {
        bundle = await database.loadSessionBundle(latestSessionId);
      }
    }
    if (_isDisposed || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    if (bundle == null) {
      // 库中没有任何会话：回到空状态。
      _activeSession = null;
      _activeCharacter = null;
      _messages = [];
      _selectedUserSettingId = null;
      _selectedPresetId = null;
      _selectedWorldBookIds.clear();
      _selectedRegexRuleGroupIds.clear();
      _galModeEnabled = false;
      _galBrowsingIndex = null;
      _clearGalChoices();
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _draftOpeningMessageIndex = 0;
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
    _galModeEnabled = bundle.session.galModeEnabled;
    _galBrowsingIndex = null;
    // 后台数据写入触发的重载不应打断或清掉 gal 选项：生成中跳过清理；
    // 选项归属的消息仍是当前叶子时保留。
    // 叶子变化（发送/重新生成/删除分支）或会话切换时照常清空。
    final lastMessageId = bundle.activeMessages.isNotEmpty
        ? bundle.activeMessages.last.id
        : null;
    final keepGalChoices =
        _isGeneratingGalChoices ||
        (_galChoicesMessageId != null && _galChoicesMessageId == lastMessageId);
    if (!keepGalChoices) {
      _clearGalChoices();
    }
    _isDraftSession = false;
    _draftOpeningAssistantMessages = const [];
    _draftOpeningMessageIndex = 0;
    _isLoading = false;
    if (_isSwitchingSession) {
      _resetPendingMessages();
    }
    _isSwitchingSession = false;
    notifyListeners();
    if (notifyReloaded) {
      onSessionReloaded?.call();
    }

    // 旧会话回填：早于状态系统的会话在加载时补写角色卡声明的初始变量
    // （仅补一次，不覆盖已有记录）。放在首屏刷新之后执行，避免拖慢
    // 气泡与操作按钮的出现。
    if (resolvedCharacter != null) {
      final loadedSessionId = bundle.session.id;
      unawaited(() async {
        try {
          await VariableStateService.instance.ensureCardInit(
            sessionId: loadedSessionId,
            cardJson: resolvedCharacter.cardJson,
          );
        } catch (_) {
          // 回填失败不影响会话加载。
        }
      }());
    }

    // 记住当前会话，下次启动时优先恢复到这条聊天。
    unawaited(_rememberSession(bundle.session.id));
  }

  /// 读取上次选择的聊天会话 id（储存不可用时忽略）。
  String? _rememberedSessionId() {
    try {
      return AppSettingsService.instance.getLastChatSessionId();
    } catch (_) {
      return null;
    }
  }

  /// 持久化当前选择的聊天会话 id，值未变化时不重复写入。
  Future<void> _rememberSession(String sessionId) async {
    final service = AppSettingsService.instance;
    try {
      if (service.getLastChatSessionId() == sessionId) {
        return;
      }
      await service.saveLastChatSessionId(sessionId);
    } catch (_) {
      // 忽略储存异常，不影响聊天流程。
    }
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
    if (session == null || _isSwitchingSession) {
      return;
    }

    if (_isDraftSession) {
      _activeSession = session.copyWith(
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
        selectedPresetId: _selectedPresetId,
        galModeEnabled: _galModeEnabled,
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
      galModeEnabled: _galModeEnabled,
    );
    if (_isDisposed ||
        _isSwitchingSession ||
        _activeSession?.id != session.id) {
      return;
    }
    _activeSession = session.copyWith(
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds.toList(),
      selectedPresetId: _selectedPresetId,
      galModeEnabled: _galModeEnabled,
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
      galModeEnabled: _galModeEnabled,
      openingAssistantMessages: _draftOpeningAssistantMessages,
      activeOpeningMessageIndex: _draftOpeningMessageIndex,
    );

    // 正式开始聊天：应用角色卡声明的初始状态变量。
    try {
      await VariableStateService.instance.applyCardInit(
        sessionId: createdSession.id,
        cardJson: character.cardJson,
      );
    } catch (_) {}

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
    if (_isDisposed || selectedApiModelIdNotifier.value != _apiStatusModelId) {
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

  // --- Gal 模式选项 ---

  /// 开关 gal 模式，状态按会话持久化。关闭时清空已生成的选项。
  Future<void> setGalMode(bool enabled) async {
    if (_isSwitchingSession) return;
    if (_galModeEnabled == enabled) return;
    _galModeEnabled = enabled;
    if (!enabled) {
      _clearGalChoices();
    }
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 点击选项：作为用户消息发送，复用现有分支机制。
  ///
  /// [replyToMessageIndex] 与直接输入一致：gal 模式下从浏览中的
  /// 历史消息处回复时传入，否则追加到当前分支末尾。
  Future<void> pickGalChoice(String choice, {int? replyToMessageIndex}) {
    return sendMessage(choice, replyToMessageIndex: replyToMessageIndex);
  }

  /// 手动为最新角色消息重新生成选项。
  Future<void> refreshGalChoices() async {
    await _maybeGenerateGalChoices(force: true);
  }

  void _clearGalChoices() {
    // 递增 generation 使仍在途的旧响应作废，并取消其请求，
    // 避免切会话/关闭 gal 模式后旧选项写入新状态。
    _galChoicesRequestGeneration++;
    _galChoicesCancelToken?.cancel();
    _galChoicesCancelToken = null;
    _galChoices = const [];
    _galChoicesMessageId = null;
    if (_isGeneratingGalChoices || _galChoicesError) {
      _isGeneratingGalChoices = false;
      _galChoicesError = false;
      notifyListeners();
    }
  }

  /// 发送/重新生成等完成后调用：gal 模式下为最新的角色回复生成选项。
  ///
  /// [force] 仅跳过「自动生成」设置检查，供手动刷新使用；
  /// 不会绕过 gal 模式开关。
  Future<void> _maybeGenerateGalChoices({bool force = false}) async {
    if (_isDisposed) return;
    if (!_galModeEnabled) return;
    if (!appSettingsNotifier.value.galChoiceAutoGenerate && !force) return;
    if (_isSending || _isImpersonating) return;

    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isDraftSession) return;

    // 只对末尾的角色消息生成选项。
    if (_messages.isEmpty || _messages.last.isMe) return;
    final targetMessageId = _messages.last.id;
    if (targetMessageId == null) return;

    _clearGalChoices();
    final requestGeneration = ++_galChoicesRequestGeneration;
    _isGeneratingGalChoices = true;
    notifyListeners();

    // 经后台调度器排队执行，与记忆/状态提取共用并发上限；任务被丢弃
    // （同锚点替代/会话切换/生成作废）时经 onSkipped 复位生成态。
    PostTaskScheduler.instance.schedule(
      kind: PostTaskKind.galChoices,
      sessionId: session.id,
      anchorKey: 'gal:$targetMessageId',
      isStale: () async =>
          _isDisposed ||
          !_galModeEnabled ||
          requestGeneration != _galChoicesRequestGeneration ||
          _messages.isEmpty ||
          _messages.last.id != targetMessageId,
      onSkipped: () => _resetGalChoicesActivity(requestGeneration),
      run: (ensureFresh) async {
        final cancelToken = ChatCompletionCancelToken();
        _galChoicesCancelToken = cancelToken;
        try {
          await ensureFresh();
          final choices = await getIt<ChatService>().generateGalChoices(
            session: session,
            character: character,
            chatMessages: _messages,
            selectedPresetId: _selectedPresetId,
            selectedUserSettingId: _selectedUserSettingId,
            selectedWorldBookIds: _selectedWorldBookIds,
            selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
            cancellationToken: cancelToken,
          );
          if (_isDisposed || requestGeneration != _galChoicesRequestGeneration) {
            return;
          }
          await ensureFresh();
          _galChoices = choices;
          _galChoicesMessageId = choices.isEmpty ? null : targetMessageId;
          _galChoicesError = false;
        } on PostTaskStaleException {
          rethrow;
        } catch (_) {
          // 选项生成失败不打断聊天：记录失败态供 UI 显示重试入口。
          if (_isDisposed || requestGeneration != _galChoicesRequestGeneration) {
            return;
          }
          _galChoices = const [];
          _galChoicesMessageId = null;
          _galChoicesError = true;
        } finally {
          if (!_isDisposed && requestGeneration == _galChoicesRequestGeneration) {
            _isGeneratingGalChoices = false;
            if (identical(_galChoicesCancelToken, cancelToken)) {
              _galChoicesCancelToken = null;
            }
            notifyListeners();
          }
        }
      },
    );
  }

  /// 任务被调度器丢弃（同锚点替代/过期）时复位 gal 选项生成态。
  void _resetGalChoicesActivity(int requestGeneration) {
    if (_isDisposed || requestGeneration != _galChoicesRequestGeneration) {
      return;
    }
    if (_isGeneratingGalChoices || _galChoicesError) {
      _isGeneratingGalChoices = false;
      _galChoicesError = false;
      notifyListeners();
    }
  }

  // --- 发送 / 重新生成 ---

  /// 发送一条用户消息。[rawText] 为未经变量替换的原始输入。
  ///
  /// [replyToMessageIndex] 用于 gal 模式中从当前展示的历史消息处回复：
  /// 传入非末尾消息索引时，会以该消息为父节点创建新分支，而不是追加到旧分支末尾。
  Future<void> sendMessage(String rawText, {int? replyToMessageIndex}) async {
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

    final effectiveReplyToIndex =
        replyToMessageIndex != null &&
            replyToMessageIndex >= 0 &&
            replyToMessageIndex < _messages.length - 1 &&
            _messages[replyToMessageIndex].id != null
        ? replyToMessageIndex
        : null;
    final chatMessages = effectiveReplyToIndex != null
        ? _messages.take(effectiveReplyToIndex + 1).toList(growable: false)
        : _messages;
    final sessionForSend = effectiveReplyToIndex != null
        ? session.copyWith(
            currentLeafMessageId: _messages[effectiveReplyToIndex].id,
          )
        : session;
    final parentMessageId = effectiveReplyToIndex != null
        ? _messages[effectiveReplyToIndex].id
        : null;

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    _isSending = true;
    // 上一轮结束后的会话重载可能仍在进行，先让它失效。
    _invalidateSessionReload();
    _clearGalChoices();
    _galBrowsingIndex = null;
    _replyToMessageIndex = effectiveReplyToIndex;
    _pendingUserMessage = ChatMessage(text: text, isMe: true);
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    // 清空上一轮残留的快照，避免新气泡在首个 token 到达前显示旧文本。
    _publishStreamingSnapshot();
    notifyListeners();

    ChatSession? persistedSession;
    ChatSendResult? sendResult;

    try {
      sendResult = await getIt<ChatService>().sendMessage(
        session: sessionForSend,
        character: character,
        chatMessages: chatMessages,
        input: text,
        parentMessageId: parentMessageId,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        selectedRegexRuleGroupIds: _selectedRegexRuleGroupIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: _appendStreamProgress,
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
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        // 先用发送结果乐观更新列表，让新气泡与操作按钮立即出现；
        // 完整重载随后补齐分支索引等派生数据。
        _appendSendResultLocally(
          sendResult,
          replyToMessageIndex: effectiveReplyToIndex,
          persistedSession: persistedSession,
        );
        notifyListeners();
      }
      final reloadSessionId = persistedSession?.id;
      if (reloadSessionId != null || !_isDraftSession) {
        await _loadSession(
          preferredSessionId: reloadSessionId ?? session.id,
          notifyReloaded: false,
        );
      }
      if (!_isDisposed) {
        // gal 模式下回复完成后自动生成选项。
        unawaited(_maybeGenerateGalChoices());
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
    if (session == null ||
        character == null ||
        _isSending ||
        _isSwitchingSession ||
        _isImpersonating) {
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
    // 上一轮结束后的会话重载可能仍在进行，先让它失效。
    _invalidateSessionReload();
    _pendingUserMessage = null;
    _regeneratingUserMessageId = userMessage.id;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    // 清空上一轮残留的快照，避免新气泡在首个 token 到达前显示旧文本。
    _publishStreamingSnapshot();
    _clearGalChoices();
    _galBrowsingIndex = null;
    notifyListeners();

    ChatSendResult? sendResult;
    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    try {
      sendResult = await getIt<ChatService>().regenerateAssistantResponse(
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
        onStreamProgress: _appendStreamProgress,
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } finally {
      _resetPendingMessages();
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        // 先用重新生成结果乐观更新列表，让按钮立即恢复可用。
        _appendRegenerateResultLocally(
          sendResult,
          userMessageIndex: userMessageIndex,
        );
        notifyListeners();
      }
      await _loadSession(
        preferredSessionId: session.id,
        notifyReloaded: false,
      );
      if (!_isDisposed) {
        // gal 模式下回复完成后自动生成选项。
        unawaited(_maybeGenerateGalChoices());
      }
    }
  }

  /// 重新生成指定位置的角色消息（其上一条为用户消息）。
  Future<void> regenerateMessage(int assistantMessageIndex) async {
    if (_isSending || _isSwitchingSession || _isImpersonating) {
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
    if (_isSending || _isSwitchingSession || _isImpersonating) {
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
    // 上一轮结束后的会话重载可能仍在进行，先让它失效。
    _invalidateSessionReload();
    _pendingUserMessage = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    // 清空上一轮残留的快照，避免新气泡在首个 token 到达前显示旧文本。
    _publishStreamingSnapshot();
    _clearGalChoices();
    _galBrowsingIndex = null;
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
        onStreamProgress: _appendStreamProgress,
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } finally {
      _resetPendingMessages();
      if (!_isDisposed) {
        _isSending = false;
        if (identical(_activeCompletionCancelToken, cancellationToken)) {
          _activeCompletionCancelToken = null;
        }
        notifyListeners();
      }
      await _loadSession(
        preferredSessionId: session.id,
        notifyReloaded: false,
      );
      if (!_isDisposed) {
        // gal 模式下回复完成后自动生成选项。
        unawaited(_maybeGenerateGalChoices());
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
        _isSwitchingSession ||
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

      // 新分支节点尚未出现在本地列表中。先补上编辑后的用户消息，
      // 让流式占位、截断位置与乐观更新都落在正确分支上。
      final editedMessage = _nodeToChatMessage(editedNode, isMe: true).copyWith(
        index: editedNode.siblingOrder + 1,
        total: editedNode.siblingOrder + 1,
        siblingIds: [
          ...editingMessage.siblingIds,
          if (!editingMessage.siblingIds.contains(editedNode.id))
            editedNode.id,
        ],
      );
      _replaceUserMessageBranch(editedMessage, index);

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

    // 角色消息文本变了，其上的状态变量差量随之过期：清空旧差量并重提。
    if (!editingMessage.isMe) {
      unawaited(
        StatusExtractionService.instance.extractForAssistantMessage(
          sessionId: session.id,
          assistantMessageId: editingMessage.id!,
          assistantText: normalizedText,
          recentMessages: _messages.take(index).toList(growable: false),
          characterName: _activeCharacter?.name ?? '角色',
          userName: resolvedUserName(),
          cardJson: _activeCharacter?.cardJson,
        ),
      );
    }

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
    if (session == null ||
        message?.id == null ||
        _isSwitchingSession ||
        _isSending) {
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
    if (_isSwitchingSession) {
      return;
    }
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
    if (_isSwitchingSession) return;
    _selectedUserSettingId = id;
    notifyListeners();
    await _persistSessionConfig();
  }

  /// 切换世界书选中状态并持久化。
  Future<void> toggleWorldBook(String id) async {
    if (_isSwitchingSession) return;
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
    if (_isSwitchingSession) return;
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
    if (_isSwitchingSession) return;
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
    if (session == null || _isSwitchingSession) {
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
    if (_isDisposed ||
        _isSwitchingSession ||
        _activeSession?.id != session.id) {
      return;
    }
    _activeSession = session.copyWith(title: normalizedTitle);
    notifyListeners();
  }

  /// 重置当前聊天（按当前选择重新初始化）。成功完成不抛异常。
  Future<void> resetChat(String nextTitle) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null ||
        character == null ||
        _isSwitchingSession ||
        _isSending) {
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
      // 消息已全部清空（diff 随之级联消失），
      // 按角色卡当前声明的初始变量重新开始。
      try {
        await VariableStateService.instance.applyCardInit(
          sessionId: session.id,
          cardJson: character.cardJson,
        );
      } catch (_) {}
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

  /// 处理新建用户设定。
  Future<void> handleUserSettingCreated(UserSetting setting) async {
    await addUserSetting(setting);
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
    bool? isLoading,
    bool? isSending,
    bool? isSwitchingSession,
    bool? useStreaming,
    ChatMessage? pendingUserMessage,
    int? replyToMessageIndex,
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
    if (isLoading != null) _isLoading = isLoading;
    if (isSending != null) _isSending = isSending;
    if (isSwitchingSession != null) _isSwitchingSession = isSwitchingSession;
    if (useStreaming != null) _useStreaming = useStreaming;
    _pendingUserMessage = pendingUserMessage;
    _replyToMessageIndex = replyToMessageIndex;
    _regeneratingUserMessageId = regeneratingUserMessageId;
    if (streamingAssistantText != null) {
      _streamingAssistantText = streamingAssistantText;
    }
    if (streamingThinkingChain != null) {
      _streamingThinkingChain = streamingThinkingChain;
    }
    if (streamingAssistantText != null || streamingThinkingChain != null) {
      // 测试直接写入流式文本时同步快照，保证气泡订阅方读到同一份内容。
      _streamingSnapshotNotifier.value = StreamingMessageSnapshot(
        text: _streamingAssistantText,
        thinkingChain: _streamingThinkingChain,
      );
    }
    if (isDraftSession != null) _isDraftSession = isDraftSession;
    if (selectedUserSettingId != null) {
      _selectedUserSettingId = selectedUserSettingId;
    }
    if (selectedPresetId != null) _selectedPresetId = selectedPresetId;
  }

  /// 仅供测试使用：模拟一条流式增量，验证按帧合并与主通知隔离。
  @visibleForTesting
  void appendStreamProgressForTesting(ChatCompletionProgress progress) {
    _appendStreamProgress(progress);
  }

  /// 仅供测试使用：立即发布待处理快照（不依赖真实帧调度）。
  @visibleForTesting
  void flushStreamingSnapshotForTesting() {
    _publishStreamingSnapshot();
  }

  /// 仅供测试使用：清空待处理消息与流式快照。
  @visibleForTesting
  void resetPendingMessagesForTesting() {
    _resetPendingMessages();
  }

  /// 仅供测试使用：模拟发送成功后把助手节点乐观并入列表。
  @visibleForTesting
  void appendAssistantNodeLocallyForTesting(
    ChatNode assistantNode, {
    int? truncateToIndex,
  }) {
    _appendNodesLocally(
      assistantNode: assistantNode,
      truncateToIndex: truncateToIndex,
    );
  }

  /// 仅供测试使用：模拟“保存并发送”编辑后本地分支的即时替换。
  @visibleForTesting
  void replaceUserMessageBranchForTesting(
    ChatMessage editedMessage,
    int index,
  ) {
    _replaceUserMessageBranch(editedMessage, index);
  }

  // --- 私有辅助 ---

  /// 丢弃旧分支尾部，并把编辑生成的新用户节点放到原位置。
  void _replaceUserMessageBranch(
    ChatMessage editedMessage,
    int index,
  ) {
    _messages = [
      ..._messages.take(index),
      editedMessage,
    ];
  }

  /// 使进行中的会话重载失效。
  ///
  /// 新操作（发送、重新生成、继续推进）会自行触发新的重载，若让旧重载
  /// 继续执行，其较早的快照会覆盖刚乐观更新出来的消息。
  void _invalidateSessionReload() {
    _sessionLoadGeneration++;
  }

  /// 用发送结果就地追加用户与助手消息。
  ///
  /// 全量重载会话需要串行查询多条数据，慢设备或大历史下可能耗时一两秒；
  /// 先用返回值补齐列表，能让新气泡及其操作按钮立即出现，重载完成后自动
  /// 修正分支索引等派生字段。
  void _appendSendResultLocally(
    ChatSendResult? result, {
    int? replyToMessageIndex,
    ChatSession? persistedSession,
  }) {
    if (result == null) {
      return;
    }
    if (persistedSession != null) {
      // 草稿会话已转正式：立刻切到真实会话，界面不再停留在草稿态。
      _activeSession = persistedSession;
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _draftOpeningMessageIndex = 0;
    }
    _appendNodesLocally(
      userNode: result.userNode,
      assistantNode: result.assistantNode,
      truncateToIndex: replyToMessageIndex,
    );
    _activeSession = _activeSession?.copyWith(
      currentLeafMessageId: result.assistantNode.id,
    );
  }

  /// 用重新生成结果替换旧分支尾部。
  void _appendRegenerateResultLocally(
    ChatSendResult? result, {
    required int userMessageIndex,
  }) {
    if (result == null) {
      return;
    }
    _appendNodesLocally(
      assistantNode: result.assistantNode,
      truncateToIndex: userMessageIndex,
    );
    _activeSession = _activeSession?.copyWith(
      currentLeafMessageId: result.assistantNode.id,
    );
  }

  /// 把节点并入消息列表；[truncateToIndex] 非空时先截断旧分支尾部。
  void _appendNodesLocally({
    required ChatNode assistantNode,
    ChatNode? userNode,
    int? truncateToIndex,
  }) {
    final base =
        truncateToIndex != null &&
            truncateToIndex >= 0 &&
            truncateToIndex < _messages.length
        ? _messages.take(truncateToIndex + 1).toList()
        : List<ChatMessage>.of(_messages);
    if (userNode != null) {
      base.add(_nodeToChatMessage(userNode, isMe: true));
    }
    base.add(_nodeToChatMessage(assistantNode, isMe: false));
    _messages = base;
  }

  ChatMessage _nodeToChatMessage(ChatNode node, {required bool isMe}) {
    return ChatMessage(
      id: node.id,
      sessionId: node.sessionId,
      parentId: node.parentId,
      text: node.text,
      isMe: isMe,
      thinkingChain: node.thinkingChain,
      index: node.siblingOrder + 1,
      total: node.siblingOrder + 1,
      siblingIds: [node.id],
    );
  }

  /// 追加一条流式增量，并把发布推迟到下一帧。
  ///
  /// 高频通道不调用 [notifyListeners]，页面骨架与历史消息不参与逐 token
  /// 刷新；同一帧内的多次增量只会发布一次快照。
  void _appendStreamProgress(ChatCompletionProgress progress) {
    if (_isDisposed) {
      return;
    }
    if (progress.textDelta.isEmpty && progress.thinkingDelta.isEmpty) {
      return;
    }
    if (progress.textDelta.isNotEmpty) {
      _streamingAssistantText += progress.textDelta;
    }
    if (progress.thinkingDelta.isNotEmpty) {
      _streamingThinkingChain += progress.thinkingDelta;
    }
    _scheduleStreamingPublish();
  }

  /// 注册下一帧的发布回调；本帧已注册时直接复用。
  void _scheduleStreamingPublish() {
    if (_streamingPublishScheduled || _isDisposed) {
      return;
    }
    _streamingPublishScheduled = true;
    _streamingPublishCallbackId = SchedulerBinding.instance
        .scheduleFrameCallback((_) {
          _streamingPublishCallbackId = null;
          _streamingPublishScheduled = false;
          if (_isDisposed) {
            return;
          }
          _publishStreamingSnapshot();
        });
  }

  /// 取消尚未执行的帧回调（结束流式、切换会话或销毁时调用）。
  void _cancelPendingStreamingPublish() {
    final callbackId = _streamingPublishCallbackId;
    _streamingPublishCallbackId = null;
    _streamingPublishScheduled = false;
    if (callbackId == null) {
      return;
    }
    SchedulerBinding.instance.cancelFrameCallbackWithId(callbackId);
  }

  /// 立即把当前缓冲区发布为快照（内容未变化时不通知监听者）。
  void _publishStreamingSnapshot() {
    if (_isDisposed) {
      // 请求在页面销毁后才结束时会走到这里，notifier 已释放。
      return;
    }
    final snapshot = StreamingMessageSnapshot(
      text: _streamingAssistantText,
      thinkingChain: _streamingThinkingChain,
    );
    if (_streamingSnapshotNotifier.value == snapshot) {
      return;
    }
    _streamingSnapshotNotifier.value = snapshot;
  }

  void _resetPendingMessages() {
    _pendingUserMessage = null;
    _replyToMessageIndex = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
    // 取消待发布回调；快照保持最后一帧内容，让占位气泡在被会话重载移除前
    // 不会短暂回落到「...」。下一轮发送开始时统一清空。
    _cancelPendingStreamingPublish();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelPendingStreamingPublish();
    apiConfigsNotifier.removeListener(onApiConfigsChanged);
    selectedApiModelIdNotifier.removeListener(onApiConfigsChanged);
    _chatDbChangeNotifier.removeListener(onChatDatabaseChanged);
    _presetChangeNotifier.removeListener(onPresetsChanged);
    _activeCompletionCancelToken?.cancel();
    _galChoicesCancelToken?.cancel();
    _streamingSnapshotNotifier.dispose();
    super.dispose();
  }
}
