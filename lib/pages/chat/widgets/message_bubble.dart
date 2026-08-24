import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';
import '../../../models/chat_message.dart';
import '../../../models/user_setting.dart';
import '../../../services/chat_character_resolver.dart';
import '../../../widgets/chat_markdown_body.dart';
import 'thinking_chain_widget.dart';
import '../utils/pseudo_thinking_chain.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.userSetting,
    required this.character,
    required this.hasBackground,
    required this.inputTapRegionGroupId,
    required this.isLastUserMessageWithoutReply,
    required this.isLastCharacterMessage,
    required this.showActions,
    required this.canEdit,
    required this.canDelete,
    required this.isBusyRegenerating,
    required this.isBusyImpersonating,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    this.onGenerate,
    this.onRegenerate,
    this.onContinue,
    this.onImpersonate,
    this.onSelectPreviousVariant,
    this.onSelectNextVariant,
    this.displayText,
  });

  final ChatMessage message;
  final UserSetting? userSetting;
  final ResolvedChatCharacter? character;

  /// 当前会话是否设置了角色背景图（用于气泡毛玻璃效果）。
  final bool hasBackground;

  final Object inputTapRegionGroupId;
  final bool isLastUserMessageWithoutReply;
  final bool isLastCharacterMessage;
  final bool showActions;
  final bool canEdit;
  final bool canDelete;
  final bool isBusyRegenerating;
  final bool isBusyImpersonating;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onGenerate;
  final VoidCallback? onRegenerate;
  final VoidCallback? onContinue;
  final VoidCallback? onImpersonate;
  final VoidCallback? onSelectPreviousVariant;
  final VoidCallback? onSelectNextVariant;

  /// 「显示」规则处理后的渲染文本；为空时使用 [message.text] 原始文本。
  final String? displayText;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  static _MessageBubbleState? _currentPopupOwner;
  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

  @override
  void dispose() {
    _hideActionPopup();
    if (_currentPopupOwner == this) {
      _currentPopupOwner = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hideActionPopup();
    });
  }

  void _showActionPopup() {
    if (_currentPopupOwner != null && !_currentPopupOwner!.mounted) {
      _currentPopupOwner = null;
    }
    _currentPopupOwner?._hideActionPopup();
    _hideActionPopup();
    if (!mounted) return;
    _overlayPortalController.show();
    _currentPopupOwner = this;
  }

  void _hideActionPopup() {
    if (_overlayPortalController.isShowing) {
      _overlayPortalController.hide();
    }
    if (_currentPopupOwner == this) {
      _currentPopupOwner = null;
    }
  }

  Widget _buildPopupOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = widget.message.isMe;
    final Offset targetPos = Offset(
      info.childPaintTransform.getTranslation().x,
      info.childPaintTransform.getTranslation().y,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -targetPos.dx,
          top: -targetPos.dy,
          width: info.overlaySize.width,
          height: info.overlaySize.height,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _hideActionPopup(),
          ),
        ),
        Positioned(
          left: isMe ? null : targetPos.dx,
          right: isMe
              ? info.overlaySize.width - targetPos.dx - info.childSize.width
              : null,
          top: targetPos.dy + info.childSize.height + 4,
          child: TextFieldTapRegion(
            groupId: widget.inputTapRegionGroupId,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHigh,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

  Widget _buildUserBubble(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettings settings,
    bool showAvatar,
  ) {
    final bubbleColor = colorScheme.primaryContainer;
    final useGlassEffect = widget.hasBackground && settings.bubbleGlassEffect;
    const bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(4),
    );
    final textColor = colorScheme.onPrimaryContainer;
    final inlineCodeColor = colorScheme.primary.withValues(alpha: 0.12);
    final codeBlockColor = colorScheme.primary.withValues(alpha: 0.08);
    final displayText = widget.displayText ?? widget.message.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OverlayPortal.overlayChildLayoutBuilder(
                controller: _overlayPortalController,
                overlayChildBuilder: _buildPopupOverlay,
                  child: GestureDetector(
                    onTapDown: widget.showActions
                        ? (_) => _showActionPopup()
                        : null,
                    child: _buildBubbleBox(
                      useGlassEffect: useGlassEffect,
                      bubbleRadius: bubbleRadius,
                      bubbleColor: bubbleColor,
                      colorScheme: colorScheme,
                      settings: settings,
                      displayText: displayText,
                      textColor: textColor,
                      inlineCodeColor: inlineCodeColor,
                      codeBlockColor: codeBlockColor,
                    ),
                  ),
              ),
              if (widget.showActions) _buildActionButtons(context, colorScheme),
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

  /// 用户气泡主体：开启毛玻璃时用半透明底色 + 背景模糊 + 细描边。
  Widget _buildBubbleBox({
    required bool useGlassEffect,
    required BorderRadius bubbleRadius,
    required Color bubbleColor,
    required ColorScheme colorScheme,
    required AppSettings settings,
    required String displayText,
    required Color textColor,
    required Color inlineCodeColor,
    required Color codeBlockColor,
  }) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: useGlassEffect
            ? bubbleColor.withValues(alpha: 0.55)
            : bubbleColor,
        borderRadius: bubbleRadius,
        border: useGlassEffect
            ? Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 0.5,
              )
            : null,
      ),
      child: Semantics(
        container: true,
        child: ChatMarkdownBody(
          text: displayText,
          settings: settings,
          textColor: textColor,
          inlineCodeColor: inlineCodeColor,
          codeBlockColor: codeBlockColor,
          applyBodyTextColor: false,
        ),
      ),
    );
    if (!useGlassEffect) return bubble;
    return ClipRRect(
      borderRadius: bubbleRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: bubble,
      ),
    );
  }

  Widget _buildCharacterBubble(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettings settings,
    bool showAvatar,
  ) {
    final textColor = colorScheme.onSurface;
    final inlineCodeColor = colorScheme.surfaceContainerHigh;
    final codeBlockColor = colorScheme.surfaceContainerLow;
    final rawText = widget.displayText ?? widget.message.text;
    final (pseudoChain, cleanedText, pseudoChainComplete) =
        extractPseudoThinkingChain(rawText);

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
              child: OverlayPortal.overlayChildLayoutBuilder(
                controller: _overlayPortalController,
                overlayChildBuilder: _buildPopupOverlay,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.hasThinkingChain)
                      _buildThinkingChain(context, colorScheme),
                    if (pseudoChain != null)
                      ThinkingChainWidget(
                        thinkingChain: pseudoChain,
                        colorScheme: colorScheme,
                        initiallyExpanded: !pseudoChainComplete,
                      ),
                    GestureDetector(
                      onTapDown: widget.showActions
                          ? (_) => _showActionPopup()
                          : null,
                      child: Semantics(
                        container: true,
                        child: ChatMarkdownBody(
                          text: cleanedText,
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

  Widget _buildThinkingChain(BuildContext context, ColorScheme colorScheme) {
    return ThinkingChainWidget(
      thinkingChain: widget.message.thinkingChain!,
      colorScheme: colorScheme,
    );
  }

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

  Widget _buildCharacterAvatar(ColorScheme colorScheme) {
    final imagePath =
        widget.character?.thumbnailPath ?? widget.character?.imagePath;
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
      if (widget.isLastCharacterMessage &&
          widget.onRegenerate != null &&
          !widget.isBusyImpersonating)
        _buildActionButton(
          icon: Icons.refresh,
          tooltip: '重新生成',
          onPressed: widget.onRegenerate!,
          colorScheme: colorScheme,
        ),
      if (widget.isLastCharacterMessage &&
          widget.onContinue != null &&
          !widget.isBusyImpersonating)
        _buildActionButton(
          icon: Icons.arrow_forward,
          tooltip: '继续推进',
          onPressed: widget.onContinue!,
          colorScheme: colorScheme,
        ),
      if (widget.isLastCharacterMessage && widget.onImpersonate != null)
        _buildActionButton(
          icon: widget.isBusyImpersonating
              ? Icons.hourglass_top
              : Icons.lightbulb_outline,
          tooltip: widget.isBusyImpersonating ? '生成中' : '助手帮答',
          onPressed: widget.isBusyImpersonating ? null : widget.onImpersonate,
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

  Widget _buildIndexSelector(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSmallActionButton(
          icon: Icons.chevron_left,
          tooltip: '上一条',
          onPressed: widget.message.index > 1
              ? widget.onSelectPreviousVariant
              : null,
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
          onPressed: widget.message.index < widget.message.total
              ? widget.onSelectNextVariant
              : null,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

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

  Widget _buildActionButton({
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
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
