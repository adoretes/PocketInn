import 'package:flutter/material.dart';

/// 在弹窗路由内部创建并持有 [TextEditingController]。
///
/// `showDialog` 的 future 在退场动画结束前就会完成；若在外部 `await` 后
/// 立即 dispose 控制器，动画期间仍会重建的输入框会访问已销毁的控制器，
/// 抛出 "A TextEditingController was used after being disposed"。
/// 用本组件包住弹窗内容，控制器会随路由子树一起销毁。
class DialogTextControllerBuilder extends StatefulWidget {
  const DialogTextControllerBuilder({
    super.key,
    required this.initialText,
    required this.builder,
  });

  final String initialText;
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<DialogTextControllerBuilder> createState() =>
      _DialogTextControllerBuilderState();
}

class _DialogTextControllerBuilderState
    extends State<DialogTextControllerBuilder> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
