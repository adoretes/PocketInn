import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings.dart';
import '../data/mock_user_settings.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../pages/api_config_page.dart';
import '../pages/api_request_log_page.dart';
import '../pages/chat/chat_view_model.dart';
import '../pages/chat/widgets/api_selector_sheet.dart';
import '../pages/chat/widgets/chat_input_area.dart';
import '../pages/chat/widgets/chat_message_list.dart';
import '../pages/chat/widgets/chat_selector_menus.dart';
import '../pages/chat/widgets/chat_title_dialog.dart';
import '../pages/chat/widgets/gal_message_view.dart';
import '../pages/chat/widgets/memory_tree_page.dart';
import '../pages/chat/widgets/message_edit_dialog.dart';
import '../pages/chat/widgets/message_view_params.dart';
import '../pages/chat_sidebar_page.dart';
import '../pages/preset_edit_page.dart';
import '../pages/regex_rule_group_edit_page.dart';
import '../pages/user_settings_page.dart';
import '../pages/world_book_edit_page.dart';
import '../services/preset_service.dart';
import '../services/regex_rule_group_service.dart';
import '../services/world_book_service.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  final String? sessionId;
  final String? draftCharacterId;
  final String? draftTitle;
  final String? draftSelectedUserSettingId;
  final String? draftSelectedPresetId;
  final List<String> draftSelectedWorldBookIds;
  final List<String> draftOpeningAssistantMessages;

  const ChatPage({super.key, this.sessionId})
    : draftCharacterId = null,
      draftTitle = null,
      draftSelectedUserSettingId = null,
      draftSelectedPresetId = null,
      draftSelectedWorldBookIds = const [],
      draftOpeningAssistantMessages = const [];

  const ChatPage.draft({
    super.key,
    required String characterId,
    required String title,
    String? selectedUserSettingId,
    String? selectedPresetId,
    List<String> selectedWorldBookIds = const [],
    List<String> openingAssistantMessages = const [],
  }) : sessionId = null,
       draftCharacterId = characterId,
       draftTitle = title,
       draftSelectedUserSettingId = selectedUserSettingId,
       draftSelectedPresetId = selectedPresetId,
       draftSelectedWorldBookIds = selectedWorldBookIds,
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
  String _inputText = '';

  late final ChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(
      preferredSessionId: widget.sessionId,
      draftCharacterId: widget.draftCharacterId,
      draftTitle: widget.draftTitle,
      draftSelectedUserSettingId: widget.draftSelectedUserSettingId,
      draftSelectedPresetId: widget.draftSelectedPresetId,
      draftSelectedWorldBookIds: widget.draftSelectedWorldBookIds,
      initialDraftOpeningMessages: widget.draftOpeningAssistantMessages,
    );
    _textController.addListener(_onTextChanged);
    _viewModel.onSessionReloaded = _clearInputIfNonEmpty;
    _viewModel.initialize();
  }

  void _onTextChanged() {
    if (_inputText == _textController.text) {
      return;
    }
    setState(() {
      _inputText = _textController.text;
    });
  }

  /// 会话重新加载后清空输入框（匹配原 _loadSession 末尾行为）。
  void _clearInputIfNonEmpty() {
    if (_textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _dismissInputKeyboard() {
    _inputFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  // --- 侧边栏 / 会话切换 ---

  void _onChatListPressed() {
    _dismissInputKeyboard();
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _selectSessionFromSidebar(ChatSessionSummary summary) async {
    _dismissInputKeyboard();
    if (_viewModel.isSending || _viewModel.isImpersonating) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('回复生成中，稍后再切换聊天')));
      return;
    }
    final started = _viewModel.selectSession(summary.id);
    if (started) {
      _textController.clear();
    }
  }

  // --- API 状态 / 配置 ---

  Future<void> _openApiConfigPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenAICompatibleConfigPage()),
    );
    await _viewModel.onApiConfigsChanged();
  }

  Future<void> _openApiRequestLogPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ApiRequestLogPage()));
  }

  Future<void> _openMemoryManager() async {
    final session = _viewModel.activeSession;
    if (session == null) return;
    final activeLeafId = _viewModel.messages.isNotEmpty
        ? _viewModel.messages.last.id
        : null;
    final jumpedTo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MemoryTreePage(
          sessionId: session.id,
          activeLeafMessageId: activeLeafId,
        ),
      ),
    );
    if (!mounted) return;
    if (jumpedTo != null || _viewModel.activeSession?.id == session.id) {
      await _viewModel.onChatDatabaseChanged();
    }
  }

  Future<void> _showApiSelectorSheet() async {
    await showApiSelectorSheet(
      context: context,
      statusProvider: () => ApiStatusInfo(
        isChecking: _viewModel.isCheckingApiStatus,
        modelId: _viewModel.apiStatusModelId,
        result: _viewModel.apiStatusResult,
      ),
      useStreamingProvider: () => _viewModel.useStreaming,
      isSendingProvider: () => _viewModel.isSending,
      onStreamingChanged: _viewModel.setUseStreaming,
      onSelectModel: _viewModel.selectApiModel,
      onRefreshStatus: _viewModel.onApiConfigsChanged,
      onOpenConfigPage: _openApiConfigPage,
      onOpenRequestLogPage: _openApiRequestLogPage,
      onOpenMemoryManager: _openMemoryManager,
    );
  }

  // --- 标题 / 重置 ---

  Future<void> _renameChatTitle() async {
    final session = _viewModel.activeSession;
    if (session == null) {
      return;
    }

    final result = await showDialog<ChatTitleDialogResult>(
      context: context,
      builder: (_) => ChatTitleDialog(initialTitle: session.title),
    );

    if (!mounted || result == null) {
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

    await _viewModel.renameChatTitle(normalizedTitle);
  }

  Future<void> _confirmAndResetChat(String nextTitle) async {
    final session = _viewModel.activeSession;
    final character = _viewModel.activeCharacter;
    if (session == null || character == null || _viewModel.isSending) {
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

    if (!mounted || confirmed != true) {
      return;
    }

    _textController.clear();
    setState(() {
      _inputText = '';
    });

    try {
      await _viewModel.resetChat(nextTitle);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已按当前选择重置聊天')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // --- 选择菜单（用户设定 / 世界书 / 预设） ---

  Future<void> _onWorldBookEditPressed(String worldBookId) async {
    final worldBook = await WorldBookService.instance.loadById(worldBookId);
    if (worldBook == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldBookEditPage(worldBook: worldBook),
      ),
    );

    await _viewModel.loadWorldBooks();
  }

  Future<void> _onUserSettingEditPressed(String settingId) async {
    final settings = userSettingsNotifier.value;
    final setting = settings.firstWhere((s) => s.id == settingId);
    final result = await showEditUserSettingDialog(context, setting);
    if (result == null || !mounted) return;

    if (result.deleted) {
      await _viewModel.handleUserSettingDeleted(settingId);
    } else {
      await _viewModel.handleUserSettingUpdated(result.setting);
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
      await _viewModel.onPresetsChanged();
    }
  }

  void _onUserSettingsPressed(BuildContext context) {
    showUserSettingMenu(
      context: context,
      settings: userSettingsNotifier.value,
      selectedId: _viewModel.selectedUserSettingId,
      inputTapRegionGroupId: _inputTapRegionGroupId,
      onSelected: (value) async {
        await _viewModel.setSelectedUserSettingId(value);
      },
      onEdit: _onUserSettingEditPressed,
    );
  }

  void _onWorldBookPressed(BuildContext context) {
    showWorldBookMenu(
      context: context,
      worldBooks: _viewModel.worldBooks,
      selectedIds: _viewModel.selectedWorldBookIds,
      inputTapRegionGroupId: _inputTapRegionGroupId,
      onToggle: (id) => _viewModel.toggleWorldBook(id),
      onEdit: _onWorldBookEditPressed,
    );
  }

  Future<void> _onRegexRuleGroupEditPressed(String groupId) async {
    final group = await RegexRuleGroupService.instance.loadById(groupId);
    if (group == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegexRuleGroupEditPage(group: group)),
    );

    await _viewModel.loadRegexRuleGroups();
  }

  void _onRegexRuleGroupPressed(BuildContext context) {
    showRegexRuleGroupMenu(
      context: context,
      groups: _viewModel.regexRuleGroups,
      selectedIds: _viewModel.selectedRegexRuleGroupIds,
      inputTapRegionGroupId: _inputTapRegionGroupId,
      onToggle: (id) => _viewModel.toggleRegexRuleGroup(id),
      onEdit: _onRegexRuleGroupEditPressed,
    );
  }

  void _onPresetPressed(BuildContext context) {
    showPresetMenu(
      context: context,
      presets: _viewModel.presets,
      selectedId: _viewModel.selectedPresetId,
      inputTapRegionGroupId: _inputTapRegionGroupId,
      onSelected: (value) async {
        await _viewModel.setSelectedPresetId(value);
      },
      onEdit: _onPresetEditPressed,
    );
  }

  void _toggleGalMode() {
    _viewModel.setGalMode(!_viewModel.galModeEnabled);
  }

  // --- 发送 / 终止 ---

  /// 发送文本并统一处理错误提示（直接输入与点击 gal 选项共用）。
  Future<void> _sendText(String text, {int? replyToMessageIndex}) async {
    try {
      await _viewModel.sendMessage(
        text,
        replyToMessageIndex: replyToMessageIndex,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onSendPressed() async {
    final text = _inputText.trim();
    if (text.isEmpty ||
        _viewModel.isSwitchingSession ||
        _viewModel.isSending ||
        _viewModel.activeSession == null) {
      return;
    }

    // gal 模式下从当前展示的消息处回复；未浏览历史时保持追加到末尾。
    final replyToMessageIndex = _viewModel.galModeEnabled
        ? _viewModel.galBrowsingIndex
        : null;

    _textController.clear();
    await _sendText(text, replyToMessageIndex: replyToMessageIndex);
  }

  void _onStopGeneratingPressed() {
    _viewModel.stopStreaming();
  }

  // --- 消息操作 ---

  void _onCopyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _onEditMessage(int index) async {
    final character = _viewModel.activeCharacter;
    final message = index >= 0 && index < _viewModel.messages.length
        ? _viewModel.messages[index]
        : null;
    if (message == null || message.id == null || _viewModel.isSending) {
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

    if (result == null || !mounted) {
      return;
    }
    final normalizedText = result.text.trim();
    if (normalizedText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息不能为空')));
      return;
    }

    try {
      await _viewModel.editMessage(index, normalizedText, result.action);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onEditDraftOpeningMessage() async {
    if (!_viewModel.isDraftSession ||
        _viewModel.isSending ||
        _viewModel.draftOpeningAssistantMessages.isEmpty) {
      return;
    }

    final result = await showDialog<MessageEditDialogResult>(
      context: context,
      builder: (context) => MessageEditDialog(
        initialText:
            _viewModel.draftOpeningAssistantMessages[_viewModel
                .draftOpeningMessageIndex
                .clamp(0, _viewModel.draftOpeningAssistantMessages.length - 1)],
        title: '编辑角色消息',
        canSaveAndSend: false,
      ),
    );

    if (result == null || !mounted) {
      return;
    }
    final normalizedText = result.text.trim();
    if (normalizedText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息不能为空')));
      return;
    }

    await _viewModel.editDraftOpeningMessage(normalizedText);
  }

  Future<void> _onDeleteMessage(int index) async {
    final message = index >= 0 && index < _viewModel.messages.length
        ? _viewModel.messages[index]
        : null;
    if (message?.id == null || _viewModel.isSending) {
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

    await _viewModel.deleteMessage(index);
  }

  Future<void> _onRegenerateMessage(int assistantMessageIndex) async {
    try {
      await _viewModel.regenerateMessage(assistantMessageIndex);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onContinueMessage(int assistantMessageIndex) async {
    try {
      await _viewModel.continueAssistantMessage(assistantMessageIndex);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onImpersonate() async {
    try {
      final reply = await _viewModel.generateUserReply(
        onProgress: (text) {
          if (!mounted) return;
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        },
      );
      if (reply == null || reply.isEmpty || !mounted) {
        return;
      }
      _textController.text = reply;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: reply.length),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onRegenerateFromUserMessage(int userMessageIndex) async {
    try {
      await _viewModel.regenerateFromUserMessage(
        userMessageIndex: userMessageIndex,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onSwitchMessageVariant(ChatMessage message, int delta) async {
    await _viewModel.switchMessageVariant(message, delta);
  }

  // --- 构建 ---

  @override
  Widget build(BuildContext context) {
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
            activeSessionId: _viewModel.activeSession?.id,
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
        title: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final session = _viewModel.activeSession;
            return InkWell(
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
            );
          },
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return ApiStatusActionButton(
                status: ApiStatusInfo(
                  isChecking: _viewModel.isCheckingApiStatus,
                  modelId: _viewModel.apiStatusModelId,
                  result: _viewModel.apiStatusResult,
                ),
                onPressed: _showApiSelectorSheet,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: appSettingsNotifier,
        builder: (context, settings, _) {
          return ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final session = _viewModel.activeSession;
              final character = _viewModel.activeCharacter;
              final backgroundPath = character?.imagePath ?? '';
              final hasBackground = backgroundPath.isNotEmpty;
              if (_viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (session == null) {
                return const Center(child: Text('暂无聊天记录'));
              }
              final isSendEnabled =
                  !_viewModel.isSwitchingSession &&
                  !_viewModel.isSending &&
                  !_viewModel.isImpersonating &&
                  _inputText.trim().isNotEmpty;
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
                          // gal 模式下减半遮罩，让角色立绘更突出。
                          alpha: _viewModel.galModeEnabled
                              ? settings.backgroundOpacity * 0.5
                              : settings.backgroundOpacity,
                        ),
                      ),
                    ),
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: topContentPadding),
                          child: Builder(
                            builder: (context) {
                              final messageViewParams = MessageViewParams(
                                visibleMessages: _viewModel.visibleMessages,
                                inputTapRegionGroupId: _inputTapRegionGroupId,
                                isSending: _viewModel.isSending,
                                isImpersonating: _viewModel.isImpersonating,
                                regeneratingUserMessageId:
                                    _viewModel.regeneratingUserMessageId,
                                isDraftSession: _viewModel.isDraftSession,
                                activeCharacter: _viewModel.activeCharacter,
                                currentUserSetting: _viewModel
                                    .currentUserSetting(),
                                sessionId: session.id,
                                selectedRegexRuleGroupIds:
                                    _viewModel.selectedRegexRuleGroupIds,
                                onCopyMessage: _onCopyMessage,
                                onEditMessage: _onEditMessage,
                                onEditDraftOpeningMessage:
                                    _onEditDraftOpeningMessage,
                                onDeleteMessage: _onDeleteMessage,
                                onRegenerateFromUserMessage:
                                    _onRegenerateFromUserMessage,
                                onRegenerateMessage: _onRegenerateMessage,
                                onContinueMessage: _onContinueMessage,
                                onImpersonate: _onImpersonate,
                                onSwitchMessageVariant: _onSwitchMessageVariant,
                              );
                              if (!_viewModel.galModeEnabled) {
                                return ChatMessageList(
                                  params: messageViewParams,
                                  scrollController: _scrollController,
                                );
                              }
                              return GalMessageView(
                                params: messageViewParams,
                                updatesListenable: _viewModel,
                                visibleMessagesProvider: () =>
                                    _viewModel.visibleMessages,
                                browsingIndex: _viewModel.galBrowsingIndex,
                                onBrowsingIndexChanged:
                                    _viewModel.setGalBrowsingIndex,
                                galChoices: _viewModel.galChoices,
                                isGeneratingGalChoices:
                                    _viewModel.isGeneratingGalChoices,
                                galChoicesMessageId:
                                    _viewModel.galChoicesMessageId,
                                galChoicesError: _viewModel.galChoicesError,
                                onPickGalChoice: (choice) => _sendText(choice),
                                onRefreshGalChoices:
                                    _viewModel.refreshGalChoices,
                              );
                            },
                          ),
                        ),
                      ),
                      ChatInputArea(
                        textController: _textController,
                        focusNode: _inputFocusNode,
                        inputTapRegionGroupId: _inputTapRegionGroupId,
                        sessionKey: ValueKey(_viewModel.activeSession?.id),
                        isSendEnabled: isSendEnabled,
                        isSending: _viewModel.isSending,
                        hasBackground: hasBackground,
                        settings: settings,
                        worldBooks: _viewModel.worldBooks,
                        selectedWorldBookIds: _viewModel.selectedWorldBookIds,
                        regexRuleGroups: _viewModel.regexRuleGroups,
                        selectedRegexRuleGroupIds:
                            _viewModel.selectedRegexRuleGroupIds,
                        currentUserSetting: _viewModel.currentUserSetting(),
                        onUserSettingsPressed: _onUserSettingsPressed,
                        onWorldBookPressed: _onWorldBookPressed,
                        onRegexRuleGroupPressed: _onRegexRuleGroupPressed,
                        onPresetPressed: _onPresetPressed,
                        galModeEnabled: _viewModel.galModeEnabled,
                        onGalModeToggle: _toggleGalMode,
                        onSendPressed: _onSendPressed,
                        onStopGeneratingPressed: _onStopGeneratingPressed,
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
