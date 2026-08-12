import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';
import '../../../models/chat_message.dart';
import '../../../models/user_setting.dart';
import '../../../services/chat_character_resolver.dart';
import '../../../widgets/chat_markdown_body.dart';
import '../utils/pseudo_thinking_chain.dart';
import 'chat_message_list.dart';
import 'thinking_chain_widget.dart';

/// Gal 模式消息视图（ADV 风格）。
///
/// 一次展示一条消息：底部对话框（名牌 + 正文），回看历史时点击画面
/// 逐条推进，默认跟随最新消息（流式生成实时刷新）。长按对话框或点
/// 工具栏「更多」弹出与气泡一致的消息操作菜单；「记录」按钮打开内嵌
/// [ChatMessageList] 的历史弹层。
///
/// 参数与 [ChatMessageList] 对齐，便于在聊天页中直接互换。
class GalMessageView extends StatefulWidget {
  const GalMessageView({
    super.key,
    required this.visibleMessages,
    required this.updatesListenable,
    required this.visibleMessagesProvider,
    required this.inputTapRegionGroupId,
    required this.isSending,
    required this.isImpersonating,
    required this.regeneratingUserMessageId,
    required this.isDraftSession,
    required this.activeCharacter,
    required this.currentUserSetting,
    required this.sessionId,
    required this.selectedRegexRuleGroupIds,
    required this.onCopyMessage,
    required this.onEditMessage,
    required this.onEditDraftOpeningMessage,
    required this.onDeleteMessage,
    required this.onRegenerateFromUserMessage,
    required this.onRegenerateMessage,
    required this.onContinueMessage,
    required this.onImpersonate,
    required this.onSwitchMessageVariant,
  });

  final List<ChatMessage> visibleMessages;

  /// 历史弹层内监听消息变化用（传入 ChatViewModel 即可）。
  final Listenable updatesListenable;

  /// 历史弹层内重新读取最新可见消息列表。
  final List<ChatMessage> Function() visibleMessagesProvider;

  final Object inputTapRegionGroupId;
  final bool isSending;
  final bool isImpersonating;
  final String? regeneratingUserMessageId;
  final bool isDraftSession;
  final ResolvedChatCharacter? activeCharacter;
  final UserSetting? currentUserSetting;
  final String? sessionId;
  final Set<String> selectedRegexRuleGroupIds;

  final void Function(ChatMessage msg) onCopyMessage;
  final void Function(int index) onEditMessage;
  final VoidCallback onEditDraftOpeningMessage;
  final void Function(int index) onDeleteMessage;
  final void Function(int index) onRegenerateFromUserMessage;
  final void Function(int index) onRegenerateMessage;
  final void Function(int index) onContinueMessage;
  final VoidCallback onImpersonate;
  final void Function(ChatMessage message, int delta) onSwitchMessageVariant;

  @override
  State<GalMessageView> createState() => _GalMessageViewState();
}

class _GalMessageViewState extends State<GalMessageView> {
  /// 正在浏览的历史消息索引；null 表示跟随最新消息。
  int? _browsingIndex;

  @override
  void didUpdateWidget(covariant GalMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _browsingIndex = null;
      return;
    }
    // 消息变少（删除等）导致索引越界时回退到跟随最新。
    if (_browsingIndex != null &&
        _browsingIndex! >= widget.visibleMessages.length) {
      _browsingIndex = null;
    }
  }

  int _effectiveIndex(int length) {
    var index = _browsingIndex ?? length - 1;
    if (index >= length) index = length - 1;
    if (index < 0) index = 0;
    return index;
  }

  void _retreat() {
    final length = widget.visibleMessages.length;
    if (length < 2) return;
    setState(() {
      final current = _browsingIndex ?? length - 1;
      if (current > 0) {
        _browsingIndex = current - 1;
      }
    });
  }

  void _advance() {
    final length = widget.visibleMessages.length;
    final browsing = _browsingIndex;
    if (browsing == null) return;
    setState(() {
      // 推进到最新一条后恢复跟随。
      _browsingIndex = browsing < length - 1 ? browsing + 1 : null;
      if (_browsingIndex != null && _browsingIndex! >= length - 1) {
        _browsingIndex = null;
      }
    });
  }

  void _jumpToLatest() {
    setState(() => _browsingIndex = null);
  }

  // --- 消息操作菜单 ---

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    bool enabled = true,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _showMessageActions(
    Offset globalPosition, {
    required int messageIndex,
    required ChatMessage message,
  }) async {
    // 与 ChatMessageList 一致的操作可用性判断。
    final isLastMessage = messageIndex == widget.visibleMessages.length - 1;
    final isLastUserMessageWithoutReply = isLastMessage && message.isMe;
    final isLastCharacterMessage = isLastMessage && !message.isMe;
    final isRegeneratingUserMessage =
        widget.regeneratingUserMessageId != null &&
        message.id == widget.regeneratingUserMessageId;
    final hasPersistedMessage = message.id != null;
    final hasDraftOpeningActions =
        widget.isDraftSession && !hasPersistedMessage && !message.isMe;
    final showActions =
        (hasPersistedMessage || hasDraftOpeningActions) &&
        (!widget.isSending || isRegeneratingUserMessage);
    if (!showActions) return;
    final canEdit =
        (hasPersistedMessage || hasDraftOpeningActions) && !widget.isSending;
    final canDelete = hasPersistedMessage && !widget.isSending;

    final overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition.translate(1, 1)),
      Offset.zero & overlayBox.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        _buildMenuItem('copy', Icons.copy_outlined, '复制'),
        if (canEdit) _buildMenuItem('edit', Icons.edit_outlined, '编辑'),
        if (canDelete) _buildMenuItem('delete', Icons.delete_outline, '删除'),
        if (isLastUserMessageWithoutReply && !isRegeneratingUserMessage)
          _buildMenuItem('generate', Icons.auto_awesome, '生成回复'),
        if (isLastCharacterMessage && !widget.isImpersonating)
          _buildMenuItem('regenerate', Icons.refresh, '重新生成'),
        if (isLastCharacterMessage && !widget.isImpersonating)
          _buildMenuItem('continue', Icons.arrow_forward, '继续推进'),
        if (isLastCharacterMessage)
          _buildMenuItem(
            'impersonate',
            Icons.lightbulb_outline,
            '助手帮答',
            enabled: !widget.isImpersonating,
          ),
      ],
    );
    if (!mounted || action == null) return;

    if (action == 'copy') {
      widget.onCopyMessage(message);
    } else if (action == 'edit') {
      if (hasDraftOpeningActions) {
        widget.onEditDraftOpeningMessage();
      } else {
        widget.onEditMessage(messageIndex);
      }
    } else if (action == 'delete') {
      widget.onDeleteMessage(messageIndex);
    } else if (action == 'generate') {
      widget.onRegenerateFromUserMessage(messageIndex);
    } else if (action == 'regenerate') {
      widget.onRegenerateMessage(messageIndex);
    } else if (action == 'continue') {
      widget.onContinueMessage(messageIndex);
    } else if (action == 'impersonate') {
      widget.onImpersonate();
    }
  }

  // --- 历史记录弹层 ---

  Future<void> _openBacklog() async {
    final scrollController = ScrollController(keepScrollOffset: false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: ListenableBuilder(
            listenable: widget.updatesListenable,
            builder: (context, _) {
              return ChatMessageList(
                visibleMessages: widget.visibleMessagesProvider(),
                scrollController: scrollController,
                inputTapRegionGroupId: widget.inputTapRegionGroupId,
                isSending: widget.isSending,
                isImpersonating: widget.isImpersonating,
                regeneratingUserMessageId: widget.regeneratingUserMessageId,
                isDraftSession: widget.isDraftSession,
                activeCharacter: widget.activeCharacter,
                currentUserSetting: widget.currentUserSetting,
                sessionId: widget.sessionId,
                selectedRegexRuleGroupIds: widget.selectedRegexRuleGroupIds,
                onCopyMessage: widget.onCopyMessage,
                onEditMessage: widget.onEditMessage,
                onEditDraftOpeningMessage: widget.onEditDraftOpeningMessage,
                onDeleteMessage: widget.onDeleteMessage,
                onRegenerateFromUserMessage: widget.onRegenerateFromUserMessage,
                onRegenerateMessage: widget.onRegenerateMessage,
                onContinueMessage: widget.onContinueMessage,
                onImpersonate: widget.onImpersonate,
                onSwitchMessageVariant: widget.onSwitchMessageVariant,
              );
            },
          ),
        );
      },
    );
    scrollController.dispose();
  }

  // --- 构建 ---

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildToolbar(
    ColorScheme colorScheme,
    int messageIndex,
    ChatMessage message,
    bool isBrowsing,
    bool showActions,
  ) {
    final total = widget.visibleMessages.length;
    final positionStyle = TextStyle(
      fontSize: 12,
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        _buildToolButton(
          icon: Icons.chevron_left,
          tooltip: '上一条',
          onPressed: messageIndex > 0 ? _retreat : null,
          colorScheme: colorScheme,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('${messageIndex + 1}/$total', style: positionStyle),
        ),
        _buildToolButton(
          icon: Icons.chevron_right,
          tooltip: '下一条',
          onPressed: isBrowsing ? _advance : null,
          colorScheme: colorScheme,
        ),
        if (isBrowsing)
          _buildToolButton(
            icon: Icons.skip_next,
            tooltip: '跳回最新',
            onPressed: _jumpToLatest,
            colorScheme: colorScheme,
          ),
        const Spacer(),
        if (message.hasMultiple) ...[
          _buildToolButton(
            icon: Icons.chevron_left,
            tooltip: '上一版本',
            onPressed: message.index > 1
                ? () => widget.onSwitchMessageVariant(message, -1)
                : null,
            colorScheme: colorScheme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '${message.index}/${message.total}',
              style: positionStyle,
            ),
          ),
          _buildToolButton(
            icon: Icons.chevron_right,
            tooltip: '下一版本',
            onPressed: message.index < message.total
                ? () => widget.onSwitchMessageVariant(message, 1)
                : null,
            colorScheme: colorScheme,
          ),
        ],
        _buildToolButton(
          icon: Icons.history,
          tooltip: '聊天记录',
          onPressed: _openBacklog,
          colorScheme: colorScheme,
        ),
        if (showActions)
          Builder(
            builder: (buttonContext) => _buildToolButton(
              icon: Icons.more_horiz,
              tooltip: '消息操作',
              onPressed: () {
                final box = buttonContext.findRenderObject()! as RenderBox;
                final origin = box.localToGlobal(Offset.zero);
                _showMessageActions(
                  origin.translate(box.size.width / 2, 0),
                  messageIndex: messageIndex,
                  message: message,
                );
              },
              colorScheme: colorScheme,
            ),
          ),
      ],
    );
  }

  Widget _buildDialogBox(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettings settings,
    Size mediaSize,
    int messageIndex,
    ChatMessage message,
    bool isBrowsing,
    bool showActions,
  ) {
    final isMe = message.isMe;
    final (pseudoChain, cleanedText, pseudoChainComplete) = isMe
        ? (null, message.text, true)
        : extractPseudoThinkingChain(message.text);

    final userSettingName = widget.currentUserSetting?.name ?? '';
    final speakerName = isMe
        ? (userSettingName.isNotEmpty ? userSettingName : '我')
        : (widget.activeCharacter?.name ?? '角色');
    final speakerColor = isMe
        ? (widget.currentUserSetting?.color ?? colorScheme.primary)
        : colorScheme.primary;

    return GestureDetector(
      onTap: isBrowsing ? _advance : null,
      onLongPressStart: showActions
          ? (details) => _showMessageActions(
              details.globalPosition,
              messageIndex: messageIndex,
              message: message,
            )
          : null,
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaSize.height * 0.42),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: speakerColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                speakerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: speakerColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && message.hasThinkingChain)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ThinkingChainWidget(
                          thinkingChain: message.thinkingChain!,
                          colorScheme: colorScheme,
                        ),
                      ),
                    if (!isMe && pseudoChain != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ThinkingChainWidget(
                          thinkingChain: pseudoChain,
                          colorScheme: colorScheme,
                          initiallyExpanded: !pseudoChainComplete,
                        ),
                      ),
                    // 对话框内不启用文本选择，避免与长按菜单手势冲突；
                    // 复制可走操作菜单，选择复制可在历史弹层中完成。
                    ChatMarkdownBody(
                      text: cleanedText,
                      settings: settings,
                      textColor: colorScheme.onSurface,
                      inlineCodeColor: colorScheme.surfaceContainerHigh,
                      codeBlockColor: colorScheme.surfaceContainerLow,
                      selectable: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 工具栏区域屏蔽点击推进：禁用态按钮与页码区域不注册手势，
            // 点击会穿透到对话框/全屏点击层误触「推进」（如 <1/n> 时点
            // 已禁用的「上一条」却跳到下一条），这里以不透明空点击层吞掉。
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _buildToolbar(
                colorScheme,
                messageIndex,
                message,
                isBrowsing,
                showActions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.visibleMessages;
    if (messages.isEmpty) {
      return const Center(child: Text('这段聊天还没有消息'));
    }
    final colorScheme = Theme.of(context).colorScheme;
    final settings = appSettingsNotifier.value;
    final mediaSize = MediaQuery.sizeOf(context);
    final messageIndex = _effectiveIndex(messages.length);
    final message = messages[messageIndex];
    final isBrowsing = _browsingIndex != null;

    // 与 ChatMessageList 一致的操作可用性判断。
    final isRegeneratingUserMessage =
        widget.regeneratingUserMessageId != null &&
        message.id == widget.regeneratingUserMessageId;
    final hasPersistedMessage = message.id != null;
    final hasDraftOpeningActions =
        widget.isDraftSession && !hasPersistedMessage && !message.isMe;
    final showActions =
        (hasPersistedMessage || hasDraftOpeningActions) &&
        (!widget.isSending || isRegeneratingUserMessage);

    return Stack(
      children: [
        // 全屏点击层：回看历史时点击推进一条。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: isBrowsing ? _advance : null,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 4,
          child: _buildDialogBox(
            context,
            colorScheme,
            settings,
            mediaSize,
            messageIndex,
            message,
            isBrowsing,
            showActions,
          ),
        ),
      ],
    );
  }
}
