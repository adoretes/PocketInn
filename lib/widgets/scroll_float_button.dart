import 'dart:async';

import 'package:flutter/material.dart';

class ScrollFloatButton extends StatefulWidget {
  const ScrollFloatButton({
    super.key,
    required this.scrollController,
    this.isReversed = false,
  });

  final ScrollController scrollController;
  final bool isReversed;

  @override
  State<ScrollFloatButton> createState() => _ScrollFloatButtonState();
}

class _ScrollFloatButtonState extends State<ScrollFloatButton> {
  bool _isVisible = false;
  Timer? _hideTimer;
  bool _showTop = false;
  bool _showBottom = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final pos = widget.scrollController.position;
    final maxExtent = pos.maxScrollExtent;
    final minExtent = pos.minScrollExtent;
    final offset = pos.pixels;
    final canScrollFurther = maxExtent - minExtent > 0;

    bool showTop;
    bool showBottom;
    if (widget.isReversed) {
      showTop = canScrollFurther && offset < maxExtent - 1;
      showBottom = canScrollFurther && offset > minExtent + 1;
    } else {
      showTop = canScrollFurther && offset > minExtent + 1;
      showBottom = canScrollFurther && offset < maxExtent - 1;
    }

    final changed = showTop != _showTop || showBottom != _showBottom;

    if (changed) {
      setState(() {
        _showTop = showTop;
        _showBottom = showBottom;
      });
    }

    if (changed && (showTop || showBottom)) {
      setState(() {
        _isVisible = true;
      });
      _resetHideTimer();
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _scrollToVisualTop() {
    final target = widget.isReversed
        ? widget.scrollController.position.maxScrollExtent
        : widget.scrollController.position.minScrollExtent;
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToVisualBottom() {
    final target = widget.isReversed
        ? widget.scrollController.position.minScrollExtent
        : widget.scrollController.position.maxScrollExtent;
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showTop)
            _buildButton(
              icon: Icons.arrow_upward,
              tooltip: '到顶',
              onTap: _scrollToVisualTop,
              colorScheme: colorScheme,
            ),
          if (_showBottom) ...[
            const SizedBox(height: 8),
            _buildButton(
              icon: Icons.arrow_downward,
              tooltip: '到底',
              onTap: _scrollToVisualBottom,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: colorScheme.surface.withValues(alpha: 0.55),
      surfaceTintColor: colorScheme.surfaceTint,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
