import 'package:flutter/material.dart';

/// 思考链组件 - 文字加展开符样式，无底板
class ThinkingChainWidget extends StatefulWidget {
  const ThinkingChainWidget({
    super.key,
    required this.thinkingChain,
    required this.colorScheme,
    this.initiallyExpanded = false,
    this.isStreaming = false,
  });

  final String thinkingChain;
  final ColorScheme colorScheme;
  final bool initiallyExpanded;

  /// 是否正在流式接收思考链（标题显示扫光动画）。
  final bool isStreaming;

  @override
  State<ThinkingChainWidget> createState() => _ThinkingChainWidgetState();
}

class _ThinkingChainWidgetState extends State<ThinkingChainWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ThinkingChainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded && !widget.initiallyExpanded) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThinkingChainHeader(
          colorScheme: widget.colorScheme,
          isExpanded: _isExpanded,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          isStreaming: widget.isStreaming,
          streamingText: widget.isStreaming ? widget.thinkingChain : null,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ThinkingChainBody(
                    thinkingChain: widget.thinkingChain,
                    colorScheme: widget.colorScheme,
                  ),
                )
              // 收起时保持全宽，避免宽度参与动画造成抖动。
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// 思考链标题行：「思考过程」文字 + 展开/收起箭头，无底板。
///
/// 状态由调用方持有，便于把标题放到自定义位置（如 Gal 视图的名字右侧）。
class ThinkingChainHeader extends StatelessWidget {
  const ThinkingChainHeader({
    super.key,
    required this.colorScheme,
    required this.isExpanded,
    required this.onTap,
    this.isStreaming = false,
    this.streamingText,
  });

  final ColorScheme colorScheme;
  final bool isExpanded;
  final VoidCallback onTap;

  /// 是否正在流式接收思考链（收起时标题旁显示逐行滚动的接收预览）。
  final bool isStreaming;

  /// 流式接收中的完整思维链文本，预览只展示最新一行。
  final String? streamingText;

  @override
  Widget build(BuildContext context) {
    final labelColor = colorScheme.onSurfaceVariant;
    final streamingText = this.streamingText;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '思考过程',
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: labelColor,
            ),
          ),
          if (isStreaming && !isExpanded && streamingText != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: _StreamingLineTicker(
                streamingText: streamingText,
                color: labelColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 流式接收预览：只显示最新一行，换行时向上滚动切换，
/// 单行放不下以省略号截断。
class _StreamingLineTicker extends StatelessWidget {
  const _StreamingLineTicker({required this.streamingText, required this.color});

  final String streamingText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lines = streamingText.split('\n');
    // 取最后一个非空行：部分模型（如 Gemini）按段落推送、chunk 以换行
    // 结尾，直接取末行会拿到空串导致全程无显示。以该行号为 key：
    // 同一行追加字符时原地更新，出现新的非空行时才触发滚动切换。
    var lineIndex = lines.length - 1;
    while (lineIndex > 0 && lines[lineIndex].trim().isEmpty) {
      lineIndex--;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // 新行自下方滚入、旧行向上滚出，形成逐行滚动效果。
        final isIncoming = child.key == ValueKey<int>(lineIndex);
        final begin = isIncoming ? const Offset(0, 1) : const Offset(0, -1);
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey<int>(lineIndex),
        width: double.infinity,
        child: Text(
          lines[lineIndex],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: color, height: 1.4),
        ),
      ),
    );
  }
}

/// 思考链正文：左侧竖线 + 端点方块的缩进排版。
class ThinkingChainBody extends StatelessWidget {
  const ThinkingChainBody({
    super.key,
    required this.thinkingChain,
    required this.colorScheme,
  });

  final String thinkingChain;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final accentColor = colorScheme.outline;

    return IntrinsicHeight(
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
              thinkingChain,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
