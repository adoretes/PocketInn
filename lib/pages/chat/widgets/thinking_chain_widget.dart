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
