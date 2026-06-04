import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../data/mock_user_settings.dart';
import '../models/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/preset.dart';
import '../models/world_book.dart';
import '../pages/api_request_log_page.dart';
import '../pages/api_config_page.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/chat_opening_message_builder.dart';
import '../services/chat_service.dart';
import '../services/chat_variable_service.dart';
import '../services/openai_compatible_api_service.dart';
import '../services/preset_service.dart';
import '../services/world_book_service.dart';
import '../widgets/chat_markdown_body.dart';
import '../widgets/expanded_text_editor_field.dart';
import 'chat_sidebar_page.dart';
import 'preset_edit_page.dart';
import 'user_settings_page.dart';
import 'world_book_edit_page.dart';

enum _MessageEditAction { save, saveAndSend }

enum _ChatTitleDialogAction { save, reset }

class _MessageEditDialogResult {
  const _MessageEditDialogResult({required this.action, required this.text});

  final _MessageEditAction action;
  final String text;
}

class _ChatTitleDialogResult {
  const _ChatTitleDialogResult({required this.action, required this.title});

  final _ChatTitleDialogAction action;
  final String title;
}

class _MessageEditDialog extends StatefulWidget {
  const _MessageEditDialog({
    required this.initialText,
    required this.title,
    required this.canSaveAndSend,
  });

  final String initialText;
  final String title;
  final bool canSaveAndSend;

  @override
  State<_MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<_MessageEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeWith(_MessageEditAction action) {
    Navigator.of(
      context,
    ).pop(_MessageEditDialogResult(action: action, text: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardInset - 48;
    final dialogMaxHeight = availableHeight
        .clamp(240.0, mediaQuery.size.height)
        .toDouble();
    final keyboardVisible = keyboardInset > 0;
    final actionButtons = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      TextButton(
        onPressed: () => _closeWith(_MessageEditAction.save),
        child: const Text('保存'),
      ),
      if (widget.canSaveAndSend)
        FilledButton(
          onPressed: () => _closeWith(_MessageEditAction.saveAndSend),
          child: const Text('保存并发送'),
        ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: dialogMaxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ExpandedTextEditorField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: keyboardVisible ? 5 : 10,
                  minLines: keyboardVisible ? 3 : 5,
                  dialogTitle: widget.title,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入消息内容',
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actionButtons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actionButtons[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 聊天页面
class ChatPage extends StatefulWidget {
  final String? sessionId;
  final String? draftCharacterId;
  final String? draftTitle;
  final String? draftSelectedUserSettingId;
  final String? draftSelectedPresetId;
  final List<String> draftOpeningAssistantMessages;

  const ChatPage({super.key, this.sessionId})
    : draftCharacterId = null,
      draftTitle = null,
      draftSelectedUserSettingId = null,
      draftSelectedPresetId = null,
      draftOpeningAssistantMessages = const [];

  const ChatPage.draft({
    super.key,
    required String characterId,
    required String title,
    String? selectedUserSettingId,
    String? selectedPresetId,
    List<String> openingAssistantMessages = const [],
  }) : sessionId = null,
       draftCharacterId = characterId,
       draftTitle = title,
       draftSelectedUserSettingId = selectedUserSettingId,
       draftSelectedPresetId = selectedPresetId,
       draftOpeningAssistantMessages = openingAssistantMessages;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const double _popupMenuAnchorGap = 8.0;
  static const double _popupMenuScreenPadding = 8.0;
  static const double _popupMenuVerticalPadding = 16.0;
  static const double _popupMenuMinWidth = 112.0;
  static const double _popupMenuMaxWidth = 280.0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final Object _inputTapRegionGroupId = Object();
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  ChatSession? _activeSession;
  ResolvedChatCharacter? _activeCharacter;
  List<ChatMessage> _messages = [];
  List<WorldBook> _worldBooks = [];
  List<PresetSummary> _presets = [];

  String _inputText = '';
  final Set<String> _selectedWorldBookIds = {};
  String? _selectedPresetId;
  String? _selectedUserSettingId;
  bool _isLoading = true;
  bool _isSwitchingSession = false;
  bool _isSending = false;
  bool _useStreaming = true;
  bool _isCheckingApiStatus = false;
  String? _apiStatusConfigId;
  ApiConnectionTestResult? _apiStatusResult;
  ChatCompletionCancelToken? _activeCompletionCancelToken;
  ChatMessage? _pendingUserMessage;
  String? _regeneratingUserMessageId;
  String _streamingAssistantText = '';
  String _streamingThinkingChain = '';
  bool _isDraftSession = false;
  List<String> _draftOpeningAssistantMessages = const [];
  int _draftOpeningMessageIndex = 0;
  int _sessionLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    apiConfigsNotifier.addListener(_handleApiConfigsChanged);
    ChatDatabaseService.instance.changeNotifier.addListener(
      _handleChatDatabaseChanged,
    );
    PresetService.instance.changeNotifier.addListener(_handlePresetsChanged);
    _textController.addListener(() {
      if (_inputText == _textController.text) {
        return;
      }
      setState(() {
        _inputText = _textController.text;
      });
    });
    _initializePage();
    _refreshEnabledApiStatus();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
    });

    final books = await WorldBookService.instance.loadAll();
    final presets = await PresetService.instance.loadAllSummaries();

    if (!mounted) {
      return;
    }

    setState(() {
      _worldBooks = books;
      _presets = presets;
    });

    if (widget.draftCharacterId != null) {
      await _loadDraftSession();
      return;
    }

    await _loadSession(preferredSessionId: widget.sessionId);
  }

  Future<void> _loadDraftSession() async {
    final characterId = widget.draftCharacterId;
    if (characterId == null) {
      return;
    }

    final loadGeneration = ++_sessionLoadGeneration;
    final resolvedCharacter = await ChatCharacterResolver.instance.resolveById(
      characterId,
    );
    if (!mounted || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    if (resolvedCharacter == null) {
      setState(() {
        _activeSession = null;
        _activeCharacter = null;
        _messages = [];
        _isDraftSession = false;
        _draftOpeningAssistantMessages = const [];
        _isLoading = false;
        _isSwitchingSession = false;
      });
      return;
    }

    final now = DateTime.now();
    final openingMessages = widget.draftOpeningAssistantMessages
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final title = widget.draftTitle?.trim().isNotEmpty == true
        ? widget.draftTitle!.trim()
        : resolvedCharacter.name;

    setState(() {
      _activeSession = ChatSession(
        id: '__draft_chat__${resolvedCharacter.id}',
        title: title,
        characterId: resolvedCharacter.id,
        selectedUserSettingId: widget.draftSelectedUserSettingId,
        selectedWorldBookIds: const [],
        selectedPresetId: widget.draftSelectedPresetId,
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
      _selectedUserSettingId = widget.draftSelectedUserSettingId;
      _selectedPresetId = widget.draftSelectedPresetId;
      _selectedWorldBookIds.clear();
      _isDraftSession = true;
      _draftOpeningAssistantMessages = openingMessages;
      _isLoading = false;
      _isSwitchingSession = false;
    });
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

  Future<void> _loadWorldBooks() async {
    final books = await WorldBookService.instance.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _worldBooks = books;
    });
  }

  Future<void> _loadSession({String? preferredSessionId}) async {
    final loadGeneration = ++_sessionLoadGeneration;
    final summaries = await ChatDatabaseService.instance.loadSessionSummaries();
    if (!mounted || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    if (summaries.isEmpty) {
      setState(() {
        _activeSession = null;
        _activeCharacter = null;
        _messages = [];
        _selectedUserSettingId = null;
        _selectedPresetId = null;
        _selectedWorldBookIds.clear();
        _isDraftSession = false;
        _draftOpeningAssistantMessages = const [];
        _draftOpeningMessageIndex = 0;
        _isLoading = false;
        _isSwitchingSession = false;
      });
      return;
    }

    final targetSummary = summaries.firstWhere(
      (item) => item.id == preferredSessionId,
      orElse: () => summaries.first,
    );
    final bundle = await ChatDatabaseService.instance.loadSessionBundle(
      targetSummary.id,
    );
    if (!mounted || loadGeneration != _sessionLoadGeneration) {
      return;
    }
    if (bundle == null) {
      setState(() {
        _isLoading = false;
        _isSwitchingSession = false;
      });
      return;
    }

    final resolvedCharacter = await ChatCharacterResolver.instance.resolveById(
      bundle.session.characterId,
    );
    if (!mounted || loadGeneration != _sessionLoadGeneration) {
      return;
    }

    setState(() {
      _activeSession = bundle.session;
      _activeCharacter = resolvedCharacter;
      _messages = bundle.activeMessages;
      _selectedUserSettingId = bundle.session.selectedUserSettingId;
      _selectedPresetId = bundle.session.selectedPresetId;
      _selectedWorldBookIds
        ..clear()
        ..addAll(bundle.session.selectedWorldBookIds);
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _draftOpeningMessageIndex = 0;
      _isLoading = false;
      if (_isSwitchingSession) {
        _inputText = '';
        _resetPendingMessages();
      }
      _isSwitchingSession = false;
    });
    if (_textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  Future<void> _persistSessionConfig() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    if (_isDraftSession) {
      setState(() {
        _activeSession = session.copyWith(
          selectedUserSettingId: _selectedUserSettingId,
          selectedWorldBookIds: _selectedWorldBookIds.toList(),
          selectedPresetId: _selectedPresetId,
        );
      });
      return;
    }

    await ChatDatabaseService.instance.updateSessionConfig(
      sessionId: session.id,
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedPresetId: _selectedPresetId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSession = session.copyWith(
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedPresetId: _selectedPresetId,
      );
    });
  }

  List<ChatMessage> get _visibleMessages {
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

  void _resetPendingMessages() {
    _pendingUserMessage = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
  }

  void _dismissInputKeyboard() {
    _inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Widget _inputTapRegion(Widget child) {
    return TextFieldTapRegion(groupId: _inputTapRegionGroupId, child: child);
  }

  RelativeRect _popupMenuPositionAbove(
    BuildContext buttonContext,
    int itemCount,
  ) {
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlayRenderObject = Navigator.of(
      buttonContext,
    ).overlay?.context.findRenderObject();
    final overlay = overlayRenderObject is RenderBox
        ? overlayRenderObject
        : null;
    final overlaySize = overlay?.size ?? MediaQuery.sizeOf(buttonContext);
    final buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );
    final menuHeight = _popupMenuHeightAbove(buttonRect, itemCount);
    final top = (buttonRect.top - menuHeight - _popupMenuAnchorGap)
        .clamp(_popupMenuScreenPadding, double.infinity)
        .toDouble();

    return RelativeRect.fromRect(
      Rect.fromLTWH(buttonRect.left, top, buttonRect.width, buttonRect.height),
      Offset.zero & overlaySize,
    );
  }

  BoxConstraints _popupMenuConstraintsAbove(BuildContext buttonContext) {
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlayRenderObject = Navigator.of(
      buttonContext,
    ).overlay?.context.findRenderObject();
    final overlay = overlayRenderObject is RenderBox
        ? overlayRenderObject
        : null;
    final buttonTop = button.localToGlobal(Offset.zero, ancestor: overlay).dy;
    final maxHeight =
        (buttonTop - _popupMenuAnchorGap - _popupMenuScreenPadding)
            .clamp(kMinInteractiveDimension, double.infinity)
            .toDouble();

    return BoxConstraints(
      minWidth: _popupMenuMinWidth,
      maxWidth: _popupMenuMaxWidth,
      maxHeight: maxHeight,
    );
  }

  double _popupMenuHeightAbove(Rect buttonRect, int itemCount) {
    final estimatedHeight =
        itemCount * kMinInteractiveDimension + _popupMenuVerticalPadding;
    final availableHeight =
        buttonRect.top - _popupMenuAnchorGap - _popupMenuScreenPadding;
    final maxHeight = availableHeight < kMinInteractiveDimension
        ? kMinInteractiveDimension
        : availableHeight;
    return estimatedHeight
        .clamp(kMinInteractiveDimension, maxHeight)
        .toDouble();
  }

  String _resolvedUserName() {
    return _currentUserSetting()?.name ?? '默认用户';
  }

  String _replaceChatVariables(String input) {
    return ChatVariableService.replacePlaceholders(
      input,
      characterName: _activeCharacter?.name ?? '角色',
      userName: _resolvedUserName(),
    );
  }

  @override
  void dispose() {
    _activeCompletionCancelToken?.cancel();
    apiConfigsNotifier.removeListener(_handleApiConfigsChanged);
    ChatDatabaseService.instance.changeNotifier.removeListener(
      _handleChatDatabaseChanged,
    );
    PresetService.instance.changeNotifier.removeListener(_handlePresetsChanged);
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleApiConfigsChanged() {
    _refreshEnabledApiStatus();
  }

  void _handleChatDatabaseChanged() {
    if (_isDraftSession) {
      return;
    }
    final sessionId = _activeSession?.id ?? widget.sessionId;
    if (sessionId == null || _isLoading || _isSwitchingSession || _isSending) {
      return;
    }
    _loadSession(preferredSessionId: sessionId);
  }

  Future<void> _handlePresetsChanged() async {
    final presets = await PresetService.instance.loadAllSummaries();
    if (!mounted) return;
    setState(() {
      _presets = presets;
    });
  }

  void _onChatListPressed() {
    _dismissInputKeyboard();
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _selectSessionFromSidebar(ChatSessionSummary summary) async {
    _dismissInputKeyboard();
    final currentSessionId = _activeSession?.id;
    if (summary.id == currentSessionId) {
      return;
    }
    if (_isSending) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('回复生成中，稍后再切换聊天')));
      return;
    }

    _isSwitchingSession = true;
    await _loadSession(preferredSessionId: summary.id);
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

    final createdSession = await ChatDatabaseService.instance.createSession(
      characterId: character.id,
      title: session.title,
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedPresetId: _selectedPresetId,
      openingAssistantMessages: _draftOpeningAssistantMessages,
      activeOpeningMessageIndex: _draftOpeningMessageIndex,
    );

    if (mounted) {
      setState(() {
        _activeSession = createdSession;
        _isDraftSession = false;
        _draftOpeningAssistantMessages = const [];
        _draftOpeningMessageIndex = 0;
      });
    } else {
      _activeSession = createdSession;
      _isDraftSession = false;
      _draftOpeningAssistantMessages = const [];
      _draftOpeningMessageIndex = 0;
    }

    return createdSession;
  }

  Future<void> _refreshEnabledApiStatus() async {
    final config = enabledApiConfig;
    if (config == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingApiStatus = false;
        _apiStatusConfigId = null;
        _apiStatusResult = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingApiStatus = true;
        _apiStatusConfigId = config.id;
      });
    }

    final result = await OpenAICompatibleApiService.instance.testConnection(
      config.copyWith(),
    );
    if (!mounted || enabledApiConfig?.id != config.id) {
      return;
    }

    setState(() {
      _isCheckingApiStatus = false;
      _apiStatusConfigId = config.id;
      _apiStatusResult = result;
    });
  }

  Future<void> _selectApiConfig(ApiConfig target) async {
    final nextConfigs = apiConfigsNotifier.value
        .map((item) => item.copyWith(enabled: item.id == target.id))
        .toList();
    await updateApiConfigs(nextConfigs);
  }

  Future<void> _openApiConfigPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenAICompatibleConfigPage()),
    );
    await _refreshEnabledApiStatus();
  }

  Future<void> _openApiRequestLogPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ApiRequestLogPage()));
  }

  Future<void> _showApiSelectorSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              child: ValueListenableBuilder<List<ApiConfig>>(
                valueListenable: apiConfigsNotifier,
                builder: (context, configs, _) {
                  final currentConfig = enabledApiConfig;
                  final settings = appSettingsNotifier.value;
                  return SizedBox(
                    height: screenHeight * 0.6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API 选择',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentConfig == null
                                ? '当前未启用 API 配置'
                                : '当前: ${currentConfig.name} · ${_apiStatusLabel(currentConfig)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('流式输出'),
                            subtitle: Text(
                              _useStreaming ? '实时显示回复内容' : '等待完整回复后再显示',
                            ),
                            value: _useStreaming,
                            onChanged: _isSending
                                ? null
                                : (value) {
                                    setState(() {
                                      _useStreaming = value;
                                    });
                                    sheetSetState(() {});
                                  },
                          ),
                          const SizedBox(height: 8),
                          if (configs.isEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.hub_outlined),
                              title: const Text('暂无 API 配置'),
                              subtitle: const Text('先添加配置后才能切换和检测状态'),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _openApiConfigPage();
                                },
                                child: const Text('去配置'),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView(
                                children: [
                                  for (final item in configs)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        item.id == currentConfig?.id
                                            ? Icons.check_circle
                                            : Icons.hub_outlined,
                                        color: item.id == currentConfig?.id
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      title: Text(
                                        item.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        item.model.trim().isEmpty
                                            ? item.baseUrl
                                            : '${item.model} · ${item.baseUrl}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: item.id == currentConfig?.id
                                          ? _buildApiStatusChip(
                                              colorScheme,
                                              item,
                                            )
                                          : null,
                                      onTap: () async {
                                        Navigator.of(sheetContext).pop();
                                        await _selectApiConfig(item);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              TextButton.icon(
                                onPressed: currentConfig == null
                                    ? null
                                    : () async {
                                        Navigator.of(sheetContext).pop();
                                        await _refreshEnabledApiStatus();
                                      },
                                icon: const Icon(Icons.sync),
                                label: const Text('刷新状态'),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _openApiConfigPage();
                                },
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('管理配置'),
                              ),
                              if (settings.showApiRequestLogEntry)
                                TextButton.icon(
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();
                                    await _openApiRequestLogPage();
                                  },
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: const Text('请求日志'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _apiStatusLabel(ApiConfig config) {
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return '检查中';
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return '未检查';
    }
    if (_apiStatusResult!.success) {
      return _apiStatusResult!.isPartial ? '部分可用' : '在线';
    }
    return '异常';
  }

  Color _apiStatusColor(ColorScheme colorScheme, ApiConfig? config) {
    if (config == null) {
      return colorScheme.outline;
    }
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return colorScheme.primary;
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return colorScheme.outline;
    }
    return _apiStatusResult!.success
        ? (_apiStatusResult!.isPartial ? Colors.orange : Colors.green)
        : colorScheme.error;
  }

  IconData _apiStatusIcon(ApiConfig? config) {
    if (config == null) {
      return Icons.hub_outlined;
    }
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return Icons.sync;
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return Icons.help_outline;
    }
    return _apiStatusResult!.success
        ? (_apiStatusResult!.isPartial
              ? Icons.cloud_queue_outlined
              : Icons.cloud_done_outlined)
        : Icons.cloud_off_outlined;
  }

  Widget _buildApiStatusChip(ColorScheme colorScheme, ApiConfig config) {
    final statusColor = _apiStatusColor(colorScheme, config);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _apiStatusLabel(config),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildApiActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = enabledApiConfig;
    final statusColor = _apiStatusColor(colorScheme, config);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: _showApiSelectorSheet,
        tooltip: config == null
            ? 'API：未配置'
            : 'API：${config.name}（${_apiStatusLabel(config)}）',
        style: IconButton.styleFrom(
          foregroundColor: statusColor,
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(_apiStatusIcon(config), size: 20),
      ),
    );
  }

  Future<void> _renameChatTitle() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    final controller = TextEditingController(text: session.title);
    final result = await showDialog<_ChatTitleDialogResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改聊天名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入聊天名称'),
            onSubmitted: (value) => Navigator.of(context).pop(
              _ChatTitleDialogResult(
                action: _ChatTitleDialogAction.save,
                title: value,
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(
                _ChatTitleDialogResult(
                  action: _ChatTitleDialogAction.reset,
                  title: controller.text,
                ),
              ),
              icon: const Icon(Icons.refresh),
              tooltip: '按当前选择重置聊天',
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _ChatTitleDialogResult(
                  action: _ChatTitleDialogAction.save,
                  title: controller.text,
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null) {
      return;
    }

    final normalizedTitle = result.title.trim();
    if (result.action == _ChatTitleDialogAction.reset) {
      final nextTitle = normalizedTitle.isEmpty
          ? session.title
          : normalizedTitle;
      await _confirmAndResetChat(nextTitle);
      return;
    }

    if (normalizedTitle.isEmpty || normalizedTitle == session.title) {
      return;
    }

    if (_isDraftSession) {
      setState(() {
        _activeSession = session.copyWith(title: normalizedTitle);
      });
      return;
    }

    await ChatDatabaseService.instance.updateSessionTitle(
      sessionId: session.id,
      title: normalizedTitle,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSession = session.copyWith(title: normalizedTitle);
    });
  }

  Future<void> _confirmAndResetChat(String nextTitle) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isSending) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置聊天'),
          content: const Text('将清空当前聊天记录，并按当前选择重新初始化聊天。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重置'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final selectedUserSettingId = _currentUserSetting()?.id;
    final openingMessages = ChatOpeningMessageBuilder.build(
      characterCardData: character.cardJson,
      characterName: character.name,
      userName: _resolvedUserName(),
    );

    if (_isDraftSession) {
      setState(() {
        _textController.clear();
        _inputText = '';
        _resetPendingMessages();
        _draftOpeningMessageIndex = 0;
        _draftOpeningAssistantMessages = openingMessages;
        _messages = _buildDraftOpeningMessages(openingMessages);
        _selectedUserSettingId = selectedUserSettingId;
        _activeSession = session.copyWith(
          title: nextTitle,
          selectedUserSettingId: selectedUserSettingId,
          selectedWorldBookIds: _selectedWorldBookIds.toList(),
          selectedPresetId: _selectedPresetId,
          lastMessagePreview: openingMessages.isNotEmpty
              ? openingMessages.first
              : '',
        );
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已按当前选择重置聊天')));
      return;
    }

    setState(() {
      _isLoading = true;
      _textController.clear();
      _inputText = '';
      _resetPendingMessages();
    });

    try {
      await ChatDatabaseService.instance.resetSession(
        sessionId: session.id,
        title: nextTitle,
        selectedUserSettingId: selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedPresetId: _selectedPresetId,
        openingAssistantMessages: openingMessages,
      );
      await _loadSession(preferredSessionId: session.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已按当前选择重置聊天')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _onUserSettingsPressed(BuildContext context) {
    showMenu<String>(
      context: context,
      requestFocus: false,
      position: _popupMenuPositionAbove(
        context,
        userSettingsNotifier.value.length,
      ),
      constraints: _popupMenuConstraintsAbove(context),
      items: userSettingsNotifier.value.map((setting) {
        final isSelected = setting.id == _selectedUserSettingId;
        return PopupMenuItem<String>(
          value: setting.id,
          padding: EdgeInsets.zero,
          child: _inputTapRegion(
            Container(
              decoration: isSelected
                  ? BoxDecoration(color: setting.color.withValues(alpha: 0.12))
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: setting.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      setting.avatarText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(setting.name, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onUserSettingEditPressed(setting.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ).then((value) async {
      if (value != null) {
        setState(() {
          _selectedUserSettingId = value;
        });
        await _persistSessionConfig();
      }
    });
  }

  void _onWorldBookPressed(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<String>(
      context: context,
      requestFocus: false,
      position: _popupMenuPositionAbove(context, _worldBooks.length),
      constraints: _popupMenuConstraintsAbove(context),
      items: _worldBooks.map((worldBook) {
        final isSelected = _selectedWorldBookIds.contains(worldBook.id);
        return PopupMenuItem<String>(
          value: worldBook.id,
          padding: EdgeInsets.zero,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWorldBookIds.remove(worldBook.id);
              } else {
                _selectedWorldBookIds.add(worldBook.id);
              }
            });
            Future<void>.microtask(_persistSessionConfig);
          },
          child: _inputTapRegion(
            Container(
              decoration: isSelected
                  ? BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      worldBook.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onWorldBookEditPressed(worldBook.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onWorldBookEditPressed(String worldBookId) async {
    final worldBook = await WorldBookService.instance.loadById(worldBookId);
    if (worldBook == null) return;
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldBookEditPage(worldBook: worldBook),
      ),
    );

    await _loadWorldBooks();
  }

  Future<void> _onUserSettingEditPressed(String settingId) async {
    final settings = userSettingsNotifier.value;
    final setting = settings.firstWhere((s) => s.id == settingId);
    final result = await showEditUserSettingDialog(context, setting);
    if (result == null || !mounted) return;

    if (result.deleted) {
      await deleteUserSetting(settingId);
      if (_selectedUserSettingId == settingId) {
        setState(() {
          _selectedUserSettingId = userSettingsNotifier.value.isNotEmpty
              ? userSettingsNotifier.value.first.id
              : null;
        });
      }
    } else {
      await updateUserSetting(result.setting);
    }
  }

  Future<void> _onPresetEditPressed(String presetId) async {
    final preset = await PresetService.instance.loadById(presetId);
    if (preset == null || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PresetEditPage(preset: preset)),
    );

    if (saved == true && mounted) {
      final presets = await PresetService.instance.loadAllSummaries();
      setState(() {
        _presets = presets;
      });
    }
  }

  void _onPresetPressed(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<String>(
      context: context,
      requestFocus: false,
      position: _popupMenuPositionAbove(context, _presets.length),
      constraints: _popupMenuConstraintsAbove(context),
      items: _presets.map((preset) {
        final isSelected = preset.id == _selectedPresetId;
        return PopupMenuItem<String>(
          value: preset.id,
          padding: EdgeInsets.zero,
          child: _inputTapRegion(
            Container(
              decoration: isSelected
                  ? BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(preset.name, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onPresetEditPressed(preset.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ).then((value) async {
      if (value != null) {
        setState(() {
          _selectedPresetId = value;
        });
        await _persistSessionConfig();
      }
    });
  }

  Future<void> _onSendPressed() async {
    final session = _activeSession;
    final character = _activeCharacter;
    final text = _replaceChatVariables(_inputText.trim()).trim();
    if (text.isEmpty ||
        session == null ||
        character == null ||
        _isSwitchingSession ||
        _isSending) {
      return;
    }

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    setState(() {
      _isSending = true;
      _pendingUserMessage = ChatMessage(text: text, isMe: true);
      _streamingAssistantText = '';
      _streamingThinkingChain = '';
    });

    _textController.clear();
    ChatSession? persistedSession;

    try {
      await ChatService.instance.sendMessage(
        session: session,
        character: character,
        chatMessages: _messages,
        input: text,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (progress.textDelta.isNotEmpty) {
              _streamingAssistantText += progress.textDelta;
            }
            if (progress.thinkingDelta.isNotEmpty) {
              _streamingThinkingChain += progress.thinkingDelta;
            }
          });
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      _resetPendingMessages();
      final reloadSessionId = persistedSession?.id;
      if (reloadSessionId != null || !_isDraftSession) {
        await _loadSession(preferredSessionId: reloadSessionId ?? session.id);
      }
      if (mounted) {
        setState(() {
          _isSending = false;
          if (identical(_activeCompletionCancelToken, cancellationToken)) {
            _activeCompletionCancelToken = null;
          }
        });
      }
    }
  }

  void _onStopGeneratingPressed() {
    _activeCompletionCancelToken?.cancel();
  }

  // 消息操作方法
  void _onCopyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _onEditMessage(int index) async {
    final session = _activeSession;
    final character = _activeCharacter;
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

    final result = await showDialog<_MessageEditDialogResult>(
      context: context,
      builder: (context) => _MessageEditDialog(
        initialText: editingMessage.text,
        title: editingMessage.isMe ? '编辑用户消息' : '编辑角色消息',
        canSaveAndSend: editingMessage.isMe && character != null,
      ),
    );

    if (result == null) {
      return;
    }
    final action = result.action;
    var normalizedText = result.text.trim();
    if (normalizedText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息不能为空')));
      return;
    }

    if (editingMessage.isMe) {
      normalizedText = _replaceChatVariables(normalizedText).trim();
    }

    try {
      if (editingMessage.isMe && action == _MessageEditAction.saveAndSend) {
        final editedNode = await ChatDatabaseService.instance
            .branchMessageFromEdit(
              sessionId: session.id,
              messageId: editingMessage.id!,
              text: normalizedText,
            );

        await _regenerateFromUserMessage(
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

      await ChatDatabaseService.instance.updateMessage(
        sessionId: session.id,
        messageId: editingMessage.id!,
        text: normalizedText,
        thinkingChain: editingMessage.isMe
            ? null
            : editingMessage.thinkingChain,
        clearThinkingChain:
            editingMessage.isMe || editingMessage.thinkingChain == null,
      );

      if (action == _MessageEditAction.saveAndSend) {
        await _regenerateFromUserMessage(
          userMessageIndex: index,
          editedText: normalizedText,
        );
        return;
      }

      await _loadSession(preferredSessionId: session.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onEditDraftOpeningMessage() async {
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

    final result = await showDialog<_MessageEditDialogResult>(
      context: context,
      builder: (context) => _MessageEditDialog(
        initialText: _draftOpeningAssistantMessages[editingIndex],
        title: '编辑角色消息',
        canSaveAndSend: false,
      ),
    );

    if (result == null) {
      return;
    }
    final normalizedText = result.text.trim();
    if (normalizedText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息不能为空')));
      return;
    }
    if (!mounted) {
      return;
    }

    final nextOpeningMessages = List<String>.from(
      _draftOpeningAssistantMessages,
    );
    nextOpeningMessages[editingIndex] = normalizedText;
    setState(() {
      _draftOpeningAssistantMessages = nextOpeningMessages;
      _messages = _buildDraftOpeningMessages(nextOpeningMessages);
      _activeSession = session.copyWith(lastMessagePreview: normalizedText);
    });
  }

  Future<void> _onDeleteMessage(int index) async {
    final session = _activeSession;
    final message = index >= 0 && index < _messages.length
        ? _messages[index]
        : null;
    if (session == null || message?.id == null || _isSending) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除消息'),
          content: Text(message!.isMe ? '确定删除这条用户消息吗？' : '确定删除这条角色消息吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await ChatDatabaseService.instance.deleteMessageBranch(
      sessionId: session.id,
      messageId: message!.id!,
    );
    await _loadSession(preferredSessionId: session.id);
  }

  Future<void> _onRegenerateMessage(int assistantMessageIndex) async {
    if (_isSending) {
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

    await _regenerateFromUserMessage(
      userMessageIndex: assistantMessageIndex - 1,
    );
  }

  Future<void> _regenerateFromUserMessage({
    required int userMessageIndex,
    String? editedText,
    ChatMessage? userMessageOverride,
    List<ChatMessage>? historyBeforeOverride,
  }) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isSending) {
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

    setState(() {
      _isSending = true;
      _pendingUserMessage = null;
      _regeneratingUserMessageId = userMessage.id;
      _streamingAssistantText = '';
      _streamingThinkingChain = '';
    });

    final cancellationToken = ChatCompletionCancelToken();
    _activeCompletionCancelToken = cancellationToken;
    try {
      await ChatService.instance.regenerateAssistantResponse(
        session: session,
        character: character,
        historyBeforeUserMessage: historyBeforeUserMessage,
        userMessage: userMessage,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        useStreaming: _useStreaming,
        cancellationToken: cancellationToken,
        onStreamProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (progress.textDelta.isNotEmpty) {
              _streamingAssistantText += progress.textDelta;
            }
            if (progress.thinkingDelta.isNotEmpty) {
              _streamingThinkingChain += progress.thinkingDelta;
            }
          });
        },
      );
    } on ChatCompletionCancelledException {
      // 用户主动终止，不弹错误提示。
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      _resetPendingMessages();
      await _loadSession(preferredSessionId: session.id);
      if (mounted) {
        setState(() {
          _isSending = false;
          if (identical(_activeCompletionCancelToken, cancellationToken)) {
            _activeCompletionCancelToken = null;
          }
        });
      }
    }
  }

  Future<void> _onSwitchMessageVariant(ChatMessage message, int delta) async {
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
      setState(() {
        _draftOpeningMessageIndex = nextIndex;
        _messages = _buildDraftOpeningMessages(_draftOpeningAssistantMessages);
        _activeSession = _activeSession?.copyWith(
          lastMessagePreview:
              _draftOpeningAssistantMessages[_draftOpeningMessageIndex],
        );
      });
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

    await ChatDatabaseService.instance.switchActiveBranch(
      sessionId: session.id,
      parentMessageId: message.parentId,
      childMessageId: message.siblingIds[nextIndex],
    );
    await _loadSession(preferredSessionId: session.id);
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = _visibleMessages;
    final isSendEnabled =
        !_isSwitchingSession &&
        !_isSending &&
        _inputText.trim().isNotEmpty &&
        _activeSession != null;
    final session = _activeSession;
    final character = _activeCharacter;
    final theme = Theme.of(context);
    final drawerEdgeDragWidth = (MediaQuery.sizeOf(context).width * 0.45).clamp(
      128.0,
      320.0,
    );
    final topContentPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight;
    final overlayStyle = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _dismissInputKeyboard();
        }
      },
      drawer: Drawer(
        child: SafeArea(
          child: ChatSidebarPage(
            activeSessionId: session?.id,
            onChatSelected: _selectSessionFromSidebar,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        leading: IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          onPressed: _onChatListPressed,
          tooltip: '聊天列表',
        ),
        title: InkWell(
          onTap: session == null ? null : _renameChatTitle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              session?.title ?? '聊天',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        centerTitle: true,
        actions: [_buildApiActionButton(context)],
      ),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: appSettingsNotifier,
        builder: (context, settings, _) {
          final backgroundPath = character?.imagePath ?? '';
          final hasBackground = backgroundPath.isNotEmpty;
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (session == null) {
            return const Center(child: Text('暂无聊天记录'));
          }
          return Stack(
            children: [
              if (hasBackground)
                Positioned.fill(
                  child: character?.isAssetImage == true
                      ? Image.asset(
                          backgroundPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        )
                      : Image.file(
                          File(backgroundPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              if (hasBackground)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(
                      alpha: settings.backgroundOpacity,
                    ),
                  ),
                ),
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: topContentPadding),
                      child: visibleMessages.isEmpty
                          ? const Center(child: Text('这段聊天还没有消息'))
                          : ListView.builder(
                              key: ValueKey(session.id),
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              itemCount: visibleMessages.length,
                              itemBuilder: (context, index) {
                                final messageIndex =
                                    visibleMessages.length - 1 - index;
                                final msg = visibleMessages[messageIndex];
                                final isLastMessage =
                                    messageIndex == visibleMessages.length - 1;
                                final isLastUserMessageWithoutReply =
                                    isLastMessage && msg.isMe;
                                final isLastCharacterMessage =
                                    isLastMessage && !msg.isMe;
                                final isRegeneratingUserMessage =
                                    _regeneratingUserMessageId != null &&
                                    msg.id == _regeneratingUserMessageId;
                                final hasPersistedMessage = msg.id != null;
                                final hasDraftOpeningActions =
                                    _isDraftSession &&
                                    !hasPersistedMessage &&
                                    !msg.isMe;
                                final showActions =
                                    (hasPersistedMessage ||
                                        hasDraftOpeningActions) &&
                                    (!_isSending || isRegeneratingUserMessage);
                                final canEditMessage =
                                    (hasPersistedMessage ||
                                        hasDraftOpeningActions) &&
                                    !_isSending;
                                final canDeleteMessage =
                                    hasPersistedMessage && !_isSending;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _MessageBubble(
                                    message: msg,
                                    userSetting: _currentUserSetting(),
                                    character: _activeCharacter,
                                    inputTapRegionGroupId:
                                        _inputTapRegionGroupId,
                                    isLastUserMessageWithoutReply:
                                        isLastUserMessageWithoutReply,
                                    isLastCharacterMessage:
                                        isLastCharacterMessage,
                                    showActions: showActions,
                                    canEdit: canEditMessage,
                                    canDelete: canDeleteMessage,
                                    isBusyRegenerating:
                                        isRegeneratingUserMessage,
                                    onCopy: () => _onCopyMessage(msg),
                                    onEdit: hasDraftOpeningActions
                                        ? _onEditDraftOpeningMessage
                                        : () => _onEditMessage(messageIndex),
                                    onDelete: () =>
                                        _onDeleteMessage(messageIndex),
                                    onGenerate:
                                        isLastUserMessageWithoutReply &&
                                            showActions &&
                                            !isRegeneratingUserMessage
                                        ? () => _regenerateFromUserMessage(
                                            userMessageIndex: messageIndex,
                                          )
                                        : null,
                                    onRegenerate:
                                        isLastCharacterMessage && showActions
                                        ? () =>
                                              _onRegenerateMessage(messageIndex)
                                        : null,
                                    onSelectPreviousVariant: msg.hasMultiple
                                        ? () => _onSwitchMessageVariant(msg, -1)
                                        : null,
                                    onSelectNextVariant: msg.hasMultiple
                                        ? () => _onSwitchMessageVariant(msg, 1)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  _buildInputArea(isSendEnabled, settings, hasBackground),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea(
    bool isSendEnabled,
    AppSettings settings,
    bool hasBackground,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasWorldBooks = _worldBooks.isNotEmpty;
    // 获取所有选中的世界书
    final selectedWorldBooks = _worldBooks
        .where((item) => _selectedWorldBookIds.contains(item.id))
        .toList();
    // 显示文本：多个世界书时显示数量，单个时显示名称
    final worldBookDisplayText = selectedWorldBooks.isEmpty
        ? '世界书'
        : selectedWorldBooks.length == 1
        ? selectedWorldBooks.first.name
        : '${selectedWorldBooks.length} 本世界书';
    final worldBookColor = selectedWorldBooks.isNotEmpty
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    // 是否启用毛玻璃效果（有背景且设置开启）
    final useGlassEffect = hasBackground && settings.inputGlassEffect;
    final sendButtonBackgroundColor = _isSending
        ? colorScheme.errorContainer
        : isSendEnabled
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final sendButtonForegroundColor = _isSending
        ? colorScheme.onErrorContainer
        : isSendEnabled
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    // 输入框内容
    Widget inputContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            key: ValueKey(_activeSession?.id),
            controller: _textController,
            focusNode: _inputFocusNode,
            groupId: _inputTapRegionGroupId,
            maxLines: 5,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '输入消息',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => ValueListenableBuilder<List<UserSetting>>(
                  valueListenable: userSettingsNotifier,
                  builder: (context, settings, _) {
                    if (settings.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final selectedSetting = _currentUserSetting();
                    if (selectedSetting == null) {
                      return const SizedBox.shrink();
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: TextButton.icon(
                        onPressed: () => _onUserSettingsPressed(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(40, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selectedSetting.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedSetting.avatarText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          selectedSetting.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Builder(
                builder: (context) => ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: TextButton.icon(
                    onPressed: hasWorldBooks
                        ? () => _onWorldBookPressed(context)
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: worldBookColor,
                    ),
                    label: Text(
                      worldBookDisplayText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.tune, size: 24),
                  onPressed: () => _onPresetPressed(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: '预设',
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isSending
                    ? _onStopGeneratingPressed
                    : (isSendEnabled ? _onSendPressed : null),
                icon: Icon(
                  _isSending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  size: 15,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(30, 30),
                  fixedSize: const Size(30, 30),
                  backgroundColor: sendButtonBackgroundColor,
                  disabledBackgroundColor: sendButtonBackgroundColor,
                  foregroundColor: sendButtonForegroundColor,
                  disabledForegroundColor: sendButtonForegroundColor.withValues(
                    alpha: 0.62,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                tooltip: _isSending ? '终止生成' : '发送',
              ),
            ],
          ),
        ),
      ],
    );
    inputContent = _inputTapRegion(inputContent);

    // 毛玻璃效果容器
    if (useGlassEffect) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surface.withValues(alpha: 0.4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: inputContent,
            ),
          ),
        ),
      );
    }

    // 普通容器
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: inputContent,
    );
  }

  UserSetting? _currentUserSetting() {
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
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.userSetting,
    required this.character,
    required this.inputTapRegionGroupId,
    required this.isLastUserMessageWithoutReply,
    required this.isLastCharacterMessage,
    required this.showActions,
    required this.canEdit,
    required this.canDelete,
    required this.isBusyRegenerating,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    this.onGenerate,
    this.onRegenerate,
    this.onSelectPreviousVariant,
    this.onSelectNextVariant,
  });

  final ChatMessage message;
  final UserSetting? userSetting;
  final ResolvedChatCharacter? character;
  final Object inputTapRegionGroupId;
  final bool isLastUserMessageWithoutReply;
  final bool isLastCharacterMessage;
  final bool showActions;
  final bool canEdit;
  final bool canDelete;
  final bool isBusyRegenerating;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onGenerate;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSelectPreviousVariant;
  final VoidCallback? onSelectNextVariant;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  static _MessageBubbleState? _currentPopupOwner;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideActionPopup();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hideActionPopup();
  }

  void _showActionPopup() {
    _currentPopupOwner?._hideActionPopup();
    _hideActionPopup();
    if (!mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final isMe = widget.message.isMe;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _hideActionPopup(),
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor:
                  isMe ? Alignment.bottomRight : Alignment.bottomLeft,
              followerAnchor:
                  isMe ? Alignment.topRight : Alignment.topLeft,
              offset: const Offset(0, 4),
              child: TextFieldTapRegion(
                groupId: widget.inputTapRegionGroupId,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surfaceContainerHigh,
                  shadowColor:
                      colorScheme.shadow.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildPopupActions(colorScheme),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _currentPopupOwner = this;
  }

  void _hideActionPopup() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (_currentPopupOwner == this) {
      _currentPopupOwner = null;
    }
    entry?.remove();
  }

  List<Widget> _buildPopupActions(ColorScheme colorScheme) {
    return <Widget>[
      _buildPopupActionButton(
        icon: Icons.copy_outlined,
        tooltip: '复制',
        onPressed: () {
          widget.onCopy();
          _hideActionPopup();
        },
        color: colorScheme.onSurface,
      ),
      if (widget.canEdit)
        _buildPopupActionButton(
          icon: Icons.edit_outlined,
          tooltip: '编辑',
          onPressed: () {
            widget.onEdit();
            _hideActionPopup();
          },
          color: colorScheme.onSurface,
        ),
      if (widget.canDelete)
        _buildPopupActionButton(
          icon: Icons.delete_outline,
          tooltip: '删除',
          onPressed: () {
            widget.onDelete();
            _hideActionPopup();
          },
          color: colorScheme.error,
        ),
    ];
  }

  Widget _buildPopupActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ExcludeFocus(
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        style: IconButton.styleFrom(
          foregroundColor: color,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final showAvatar = settings.showAvatar;

        if (isMe) {
          return _buildUserBubble(context, colorScheme, settings, showAvatar);
        } else {
          return _buildCharacterBubble(
            context,
            colorScheme,
            settings,
            showAvatar,
          );
        }
      },
    );
  }

  /// 构建用户消息气泡
  Widget _buildUserBubble(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettings settings,
    bool showAvatar,
  ) {
    final bubbleColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;
    final inlineCodeColor = colorScheme.primary.withValues(alpha: 0.12);
    final codeBlockColor = colorScheme.primary.withValues(alpha: 0.08);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: GestureDetector(
                  onTapDown: widget.showActions ? (_) => _showActionPopup() : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Semantics(
                      container: true,
                      child: ChatMarkdownBody(
                        text: widget.message.text,
                        settings: settings,
                        textColor: textColor,
                        inlineCodeColor: inlineCodeColor,
                        codeBlockColor: codeBlockColor,
                        applyBodyTextColor: false,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showActions)
                _buildActionButtons(context, colorScheme),
            ],
          ),
        ),
        if (showAvatar) ...[
          const SizedBox(width: 8),
          _buildUserAvatar(colorScheme),
        ],
      ],
    );
  }

  /// 构建角色消息气泡（全宽无背景）
  Widget _buildCharacterBubble(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettings settings,
    bool showAvatar,
  ) {
    final textColor = colorScheme.onSurface;
    final inlineCodeColor = colorScheme.surfaceContainerHigh;
    final codeBlockColor = colorScheme.surfaceContainerLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar) ...[
              _buildCharacterAvatar(colorScheme),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: CompositedTransformTarget(
                link: _layerLink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.hasThinkingChain)
                      _buildThinkingChain(context, colorScheme),
                    GestureDetector(
                      onTapDown: widget.showActions ? (_) => _showActionPopup() : null,
                      child: Semantics(
                        container: true,
                        child: ChatMarkdownBody(
                          text: widget.message.text,
                          settings: settings,
                          textColor: textColor,
                          inlineCodeColor: inlineCodeColor,
                          codeBlockColor: codeBlockColor,
                        ),
                      ),
                    ),
                    _buildActionButtons(context, colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建折叠的思考链
  Widget _buildThinkingChain(BuildContext context, ColorScheme colorScheme) {
    return _ThinkingChainWidget(
      thinkingChain: widget.message.thinkingChain!,
      colorScheme: colorScheme,
    );
  }

  /// 构建用户头像
  Widget _buildUserAvatar(ColorScheme colorScheme) {
    final currentUser = widget.userSetting;
    if (currentUser != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: currentUser.color,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          currentUser.avatarText.isEmpty ? '我' : currentUser.avatarText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 20, color: colorScheme.onPrimary),
    );
  }

  /// 构建角色头像
  Widget _buildCharacterAvatar(ColorScheme colorScheme) {
    final imagePath = widget.character?.thumbnailPath ?? widget.character?.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final imageProvider = imagePath.startsWith('assets/')
          ? AssetImage(imagePath) as ImageProvider
          : FileImage(File(imagePath));
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              );
            },
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.smart_toy_outlined,
        size: 20,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    if (!widget.showActions) {
      if (!widget.message.hasMultiple) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [const Spacer(), _buildIndexSelector(colorScheme)],
        ),
      );
    }

    final actionWidgets = <Widget>[
      if (widget.isLastUserMessageWithoutReply && widget.onGenerate != null)
        _buildActionButton(
          icon: widget.isBusyRegenerating
              ? Icons.hourglass_top
              : Icons.auto_awesome,
          tooltip: widget.isBusyRegenerating ? '生成中' : '生成回复',
          onPressed: widget.onGenerate!,
          colorScheme: colorScheme,
        ),
      if (widget.isLastCharacterMessage && widget.onRegenerate != null)
        _buildActionButton(
          icon: Icons.refresh,
          tooltip: '重新生成',
          onPressed: widget.onRegenerate!,
          colorScheme: colorScheme,
        ),
    ];

    if (actionWidgets.isEmpty && !widget.message.hasMultiple) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (widget.message.isMe) const Spacer(),
          ...actionWidgets,
          if (!widget.message.isMe) const Spacer(),
          if (widget.message.hasMultiple) _buildIndexSelector(colorScheme),
        ],
      ),
    );
}

  /// 构建消息索引选择器 < 1/x >
  Widget _buildIndexSelector(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSmallActionButton(
          icon: Icons.chevron_left,
          tooltip: '上一条',
          onPressed: widget.message.index > 1 ? widget.onSelectPreviousVariant : null,
          colorScheme: colorScheme,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${widget.message.index}/${widget.message.total}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildSmallActionButton(
          icon: Icons.chevron_right,
          tooltip: '下一条',
          onPressed: widget.message.index < widget.message.total ? widget.onSelectNextVariant : null,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  /// 构建小型操作按钮（用于索引选择器）
  Widget _buildSmallActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 思考链组件 - 文字加展开符样式，无底板
class _ThinkingChainWidget extends StatefulWidget {
  const _ThinkingChainWidget({
    required this.thinkingChain,
    required this.colorScheme,
  });

  final String thinkingChain;
  final ColorScheme colorScheme;

  @override
  State<_ThinkingChainWidget> createState() => _ThinkingChainWidgetState();
}

class _ThinkingChainWidgetState extends State<_ThinkingChainWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '思考过程',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: widget.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SizedBox(
                    width: 10,
                    child: Column(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.thinkingChain,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
