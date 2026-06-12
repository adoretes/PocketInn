import 'dart:io';

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
import '../pages/chat/widgets/api_selector_sheet.dart';
import '../pages/chat/widgets/chat_input_area.dart';
import '../pages/chat/widgets/chat_title_dialog.dart';
import '../pages/chat/widgets/memory_edit_dialog.dart';
import '../pages/chat/widgets/message_bubble.dart';
import '../pages/chat/widgets/message_edit_dialog.dart';
import '../pages/chat/utils/popup_menu_position.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/chat_opening_message_builder.dart';
import '../services/chat_service.dart';
import '../services/chat_variable_service.dart';
import '../services/openai_compatible_api_service.dart';
import '../services/preset_service.dart';
import '../services/world_book_service.dart';
import '../widgets/scroll_float_button.dart';
import 'chat_sidebar_page.dart';
import 'preset_edit_page.dart';
import 'user_settings_page.dart';
import 'world_book_edit_page.dart';

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

  Future<void> _openMemoryManager() async {
    final session = _activeSession;
    if (session == null) return;
    final pathMessageIds = _messages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemoryEditDialog(
          sessionId: session.id,
          pathMessageIds: pathMessageIds,
        ),
      ),
    );
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
    await showApiSelectorSheet(
      context: context,
      statusProvider: () => ApiStatusInfo(
        isChecking: _isCheckingApiStatus,
        configId: _apiStatusConfigId,
        result: _apiStatusResult,
      ),
      useStreamingProvider: () => _useStreaming,
      isSendingProvider: () => _isSending,
      onStreamingChanged: (value) {
        setState(() {
          _useStreaming = value;
        });
      },
      onSelectConfig: _selectApiConfig,
      onRefreshStatus: _refreshEnabledApiStatus,
      onOpenConfigPage: _openApiConfigPage,
      onOpenRequestLogPage: _openApiRequestLogPage,
      onOpenMemoryManager: _openMemoryManager,
    );
  }

  Future<void> _renameChatTitle() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    final result = await showDialog<ChatTitleDialogResult>(
      context: context,
      builder: (_) => ChatTitleDialog(initialTitle: session.title),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }

    final normalizedTitle = result.title.trim();
    if (result.action == ChatTitleDialogAction.reset) {
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

    if (!mounted) {
      return;
    }
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
      position: PopupMenuPositioning.positionAbove(
        context,
        userSettingsNotifier.value.length,
      ),
      constraints: PopupMenuPositioning.constraintsAbove(context),
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
      position: PopupMenuPositioning.positionAbove(context, _worldBooks.length),
      constraints: PopupMenuPositioning.constraintsAbove(context),
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
      position: PopupMenuPositioning.positionAbove(context, _presets.length),
      constraints: PopupMenuPositioning.constraintsAbove(context),
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

    final result = await showDialog<MessageEditDialogResult>(
      context: context,
      builder: (context) => MessageEditDialog(
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
      if (editingMessage.isMe && action == MessageEditAction.saveAndSend) {
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

      if (action == MessageEditAction.saveAndSend) {
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

    final result = await showDialog<MessageEditDialogResult>(
      context: context,
      builder: (context) => MessageEditDialog(
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
        actions: [
          ApiStatusActionButton(
            status: ApiStatusInfo(
              isChecking: _isCheckingApiStatus,
              configId: _apiStatusConfigId,
              result: _apiStatusResult,
            ),
            onPressed: _showApiSelectorSheet,
          ),
        ],
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
                      child: Stack(
                        children: [
                          if (visibleMessages.isEmpty)
                            const Center(child: Text('这段聊天还没有消息'))
                          else
                            ListView.builder(
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
                                  child: MessageBubble(
                                    key: ValueKey(msg.id ?? messageIndex),
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
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: ScrollFloatButton(
                              scrollController: _scrollController,
                              isReversed: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ChatInputArea(
                    textController: _textController,
                    focusNode: _inputFocusNode,
                    inputTapRegionGroupId: _inputTapRegionGroupId,
                    sessionKey: ValueKey(_activeSession?.id),
                    isSendEnabled: isSendEnabled,
                    isSending: _isSending,
                    hasBackground: hasBackground,
                    settings: settings,
                    worldBooks: _worldBooks,
                    selectedWorldBookIds: _selectedWorldBookIds,
                    currentUserSetting: _currentUserSetting(),
                    onUserSettingsPressed: _onUserSettingsPressed,
                    onWorldBookPressed: _onWorldBookPressed,
                    onPresetPressed: _onPresetPressed,
                    onSendPressed: _onSendPressed,
                    onStopGeneratingPressed: _onStopGeneratingPressed,
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
