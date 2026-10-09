import 'package:flutter/material.dart';

/// 思考链组件 - 文字加展开符样式，无底板
class ThinkingChainWidget extends StatefulWidget {
  const ThinkingChainWidget({
    super.key,
    required this.thinkingChain,
    required this.colorScheme,
    this.initiallyExpanded = false,
  });

  final String thinkingChain;
  final ColorScheme colorScheme;
  final bool initiallyExpanded;

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
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 6),
          ThinkingChainBody(
            thinkingChain: widget.thinkingChain,
            colorScheme: widget.colorScheme,
          ),
        ],
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
  });

  final ColorScheme colorScheme;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '思考过程',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
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
