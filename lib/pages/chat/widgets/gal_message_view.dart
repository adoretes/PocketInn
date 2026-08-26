import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/chat_markdown_body.dart';
import '../utils/pseudo_thinking_chain.dart';
import 'chat_message_list.dart';
import 'message_action_availability.dart';
import 'message_view_params.dart';
import 'regex_display_text.dart';
import 'thinking_chain_widget.dart';

/// Gal 模式消息视图（ADV 风格）。
///
/// 一次展示一条消息：底部对话框（名牌 + 正文），回看历史时点击画面
/// 逐条推进，默认跟随最新消息（流式生成实时刷新）。长按对话框或点
/// 工具栏「更多」弹出与气泡一致的消息操作菜单；「记录」按钮打开内嵌
/// [ChatMessageList] 的历史弹层。
///
/// 公共参数见 [params]；浏览索引由外部（ChatViewModel）持有，
/// 通过 [browsingIndex]/[onBrowsingIndexChanged] 受控传入。
class GalMessageView extends StatefulWidget {
  const GalMessageView({
    super.key,
    required this.params,
    required this.updatesListenable,
    required this.visibleMessagesProvider,
    required this.browsingIndex,
    required this.onBrowsingIndexChanged,
    required this.galChoices,
    required this.isGeneratingGalChoices,
    required this.galChoicesMessageId,
    required this.galChoicesError,
    required this.onPickGalChoice,
    required this.onRefreshGalChoices,
  });

  /// 与 ChatMessageList 共享的公共参数。
  final MessageViewParams params;

  /// 历史弹层内监听消息变化用（传入 ChatViewModel 即可）。
  final Listenable updatesListenable;

  /// 历史弹层内重新读取最新可见消息列表。
  final List<ChatMessage> Function() visibleMessagesProvider;

  /// 正在浏览的历史消息索引；null 表示跟随最新消息。
  final int? browsingIndex;

  /// 浏览索引变化时回写（由 ChatViewModel 持有该状态）。
  final ValueChanged<int?> onBrowsingIndexChanged;

  /// 当前可点击的 gal 选项；空列表表示不显示。
  final List<String> galChoices;

  /// 选项是否正在通过子 API 生成。
  final bool isGeneratingGalChoices;

  /// 选项归属的角色消息 ID；与当前展示消息不一致时不显示。
  final String? galChoicesMessageId;

  /// 上一次选项生成是否失败；失败时显示重试入口。
  final bool galChoicesError;

  /// 点击选项：以选项文本作为用户消息发送。
  final void Function(String choice) onPickGalChoice;

  /// 手动（重新）生成选项：供「生成选项」按钮与失败重试使用。
  final VoidCallback onRefreshGalChoices;

  @override
  State<GalMessageView> createState() => _GalMessageViewState();
}

class _GalMessageViewState extends State<GalMessageView>
    with RegexDisplayTextMixin<GalMessageView> {
  /// 当前生效的浏览索引；越界（如消息被删除）时视为跟随最新。
  int? get _browsingIndex {
    final index = widget.browsingIndex;
    if (index == null ||
        index < 0 ||
        index >= widget.params.visibleMessages.length) {
      return null;
    }
    return index;
  }

  int _effectiveIndex(int length) {
    var index = _browsingIndex ?? length - 1;
    if (index >= length) index = length - 1;
    if (index < 0) index = 0;
    return index;
  }

  void _retreat() {
    final length = widget.params.visibleMessages.length;
    if (length < 2) return;
    final current = _browsingIndex ?? length - 1;
    if (current > 0) {
      widget.onBrowsingIndexChanged(current - 1);
    }
  }

  void _advance() {
    final length = widget.params.visibleMessages.length;
    final browsing = _browsingIndex;
    if (browsing == null) return;
    // 推进到最新一条后恢复跟随。
    final next = browsing + 1 >= length - 1 ? null : browsing + 1;
    widget.onBrowsingIndexChanged(next);
  }

  void _jumpToLatest() {
    widget.onBrowsingIndexChanged(null);
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
    final availability = evaluateMessageActions(
      message: message,
      messageIndex: messageIndex,
      messageCount: widget.params.visibleMessages.length,
      isSending: widget.params.isSending,
      isDraftSession: widget.params.isDraftSession,
      regeneratingUserMessageId: widget.params.regeneratingUserMessageId,
    );
    if (!availability.showActions) return;

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
        if (availability.canEdit)
          _buildMenuItem('edit', Icons.edit_outlined, '编辑'),
        if (availability.canDelete)
          _buildMenuItem('delete', Icons.delete_outline, '删除'),
        if (availability.isLastUserMessageWithoutReply &&
            !availability.isRegeneratingUserMessage)
          _buildMenuItem('generate', Icons.auto_awesome, '生成回复'),
        if (availability.isLastCharacterMessage &&
            !widget.params.isImpersonating)
          _buildMenuItem('regenerate', Icons.refresh, '重新生成'),
        if (availability.isLastCharacterMessage &&
            !widget.params.isImpersonating)
          _buildMenuItem('continue', Icons.arrow_forward, '继续推进'),
        if (availability.isLastCharacterMessage)
          _buildMenuItem(
            'impersonate',
            Icons.lightbulb_outline,
            '助手帮答',
            enabled: !widget.params.isImpersonating,
          ),
      ],
    );
    if (!mounted || action == null) return;

    if (action == 'copy') {
      widget.params.onCopyMessage(message);
    } else if (action == 'edit') {
      if (availability.hasDraftOpeningActions) {
        widget.params.onEditDraftOpeningMessage();
      } else {
        widget.params.onEditMessage(messageIndex);
      }
    } else if (action == 'delete') {
      widget.params.onDeleteMessage(messageIndex);
    } else if (action == 'generate') {
      widget.params.onRegenerateFromUserMessage(messageIndex);
    } else if (action == 'regenerate') {
      widget.params.onRegenerateMessage(messageIndex);
    } else if (action == 'continue') {
      widget.params.onContinueMessage(messageIndex);
    } else if (action == 'impersonate') {
      widget.params.onImpersonate();
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
                // 弹层背景与页面不同，不绘制背景副本，避免角色立绘透出
                // 干扰阅读。
                params: widget.params
                    .withVisibleMessages(widget.visibleMessagesProvider())
                    .withoutBackgroundCopy(),
                scrollController: scrollController,
              );
            },
          ),
        );
      },
    );
    scrollController.dispose();
  }

  // --- Gal 选项 ---

  /// 选项区：跟随最新、非发送中、当前为角色消息时显示。
  ///
  /// 依次呈现：生成中指示器 → 失败重试入口 → 选项列表；
  /// 无选项且未在生成时给出手动生成入口（供关闭自动生成时使用）。
  Widget? _buildGalChoicesPanel(
    ColorScheme colorScheme,
    ChatMessage message,
    bool isBrowsing,
  ) {
    if (isBrowsing || widget.params.isSending || message.isMe) return null;
    final messageId = message.id;
    if (messageId == null) return null;
    final useGlassEffect =
        widget.params.hasBackground &&
        appSettingsNotifier.value.bubbleGlassEffect;

    if (widget.isGeneratingGalChoices) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '正在生成选项…',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.galChoicesError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onRefreshGalChoices,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  '选项生成失败，点击重试',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (messageId != widget.galChoicesMessageId || widget.galChoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onRefreshGalChoices,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '生成选项',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, choice) in widget.galChoices.indexed)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
              child: useGlassEffect
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: _buildGalChoice(
                          colorScheme,
                          choice,
                          backgroundAlpha: 0.4,
                        ),
                      ),
                    )
                  : _buildGalChoice(
                      colorScheme,
                      choice,
                      backgroundAlpha: 0.82,
                    ),
            ),
        ],
      ),
    );
  }

  /// Gal 选项按钮：毛玻璃开启时由调用方外包 ClipRRect + BackdropFilter。
  Widget _buildGalChoice(
    ColorScheme colorScheme,
    String choice, {
    required double backgroundAlpha,
  }) {
    return Material(
      color: colorScheme.surface.withValues(alpha: backgroundAlpha),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onPickGalChoice(choice),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.chevron_right,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  choice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final total = widget.params.visibleMessages.length;
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
                ? () => widget.params.onSwitchMessageVariant(message, -1)
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
                ? () => widget.params.onSwitchMessageVariant(message, 1)
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
    ColorScheme colorScheme,
    AppSettings settings,
    Size mediaSize,
    int messageIndex,
    ChatMessage message,
    bool isBrowsing,
    bool showActions,
  ) {
    final isMe = message.isMe;
    // 与 ChatMessageList 一致：先做正则显示替换，再做伪思维链提取。
    final displayText = displayTextFor(
      message,
      widget.params.visibleMessages.length - 1 - messageIndex,
      widget.params.selectedRegexRuleGroupIds,
    );
    final (pseudoChain, cleanedText, pseudoChainComplete) = isMe
        ? (null, displayText, true)
        : extractPseudoThinkingChain(displayText);

    final userSettingName = widget.params.currentUserSetting?.name ?? '';
    final speakerName = isMe
        ? (userSettingName.isNotEmpty ? userSettingName : '我')
        : (widget.params.activeCharacter?.name ?? '角色');
    final speakerColor = isMe
        ? (widget.params.currentUserSetting?.color ?? colorScheme.primary)
        : colorScheme.primary;

    final useGlassEffect =
        widget.params.hasBackground && settings.bubbleGlassEffect;
    Widget dialogBox = Container(
      constraints: BoxConstraints(maxHeight: mediaSize.height * 0.42),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: useGlassEffect ? 0.4 : 0.88,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        boxShadow: useGlassEffect
            ? null
            : [
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
      );
    if (useGlassEffect) {
      dialogBox = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: dialogBox,
        ),
      );
    }
    return GestureDetector(
      onTap: isBrowsing ? _advance : null,
      onLongPressStart: showActions
          ? (details) => _showMessageActions(
              details.globalPosition,
              messageIndex: messageIndex,
              message: message,
            )
          : null,
      child: dialogBox,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.params.visibleMessages;
    if (messages.isEmpty) {
      return const Center(child: Text('这段聊天还没有消息'));
    }
    final colorScheme = Theme.of(context).colorScheme;
    final settings = appSettingsNotifier.value;
    final mediaSize = MediaQuery.sizeOf(context);
    final messageIndex = _effectiveIndex(messages.length);
    final message = messages[messageIndex];
    final isBrowsing = _browsingIndex != null;

    final availability = evaluateMessageActions(
      message: message,
      messageIndex: messageIndex,
      messageCount: messages.length,
      isSending: widget.params.isSending,
      isDraftSession: widget.params.isDraftSession,
      regeneratingUserMessageId: widget.params.regeneratingUserMessageId,
    );

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGalChoicesPanel(colorScheme, message, isBrowsing) ??
                  const SizedBox.shrink(),
              _buildDialogBox(
                colorScheme,
                settings,
                mediaSize,
                messageIndex,
                message,
                isBrowsing,
                availability.showActions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
