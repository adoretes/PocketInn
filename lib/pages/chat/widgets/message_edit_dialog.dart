import 'package:flutter/material.dart';

import '../../../widgets/expanded_text_editor_field.dart';

enum MessageEditAction { save, saveAndSend }

class MessageEditDialogResult {
  const MessageEditDialogResult({required this.action, required this.text});

  final MessageEditAction action;
  final String text;
}

class MessageEditDialog extends StatefulWidget {
  const MessageEditDialog({
    super.key,
    required this.initialText,
    required this.title,
    required this.canSaveAndSend,
  });

  final String initialText;
  final String title;
  final bool canSaveAndSend;

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeWith(MessageEditAction action) {
    Navigator.of(
      context,
    ).pop(MessageEditDialogResult(action: action, text: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardInset - 48;
    final dialogMaxHeight = availableHeight
        .clamp(240.0, mediaQuery.size.height)
        .toDouble();
    final keyboardVisible = keyboardInset > 0;
    final actionButtons = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      TextButton(
        onPressed: () => _closeWith(MessageEditAction.save),
        child: const Text('保存'),
      ),
      if (widget.canSaveAndSend)
        FilledButton(
          onPressed: () => _closeWith(MessageEditAction.saveAndSend),
          child: const Text('保存并发送'),
        ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: dialogMaxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ExpandedTextEditorField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: keyboardVisible ? 5 : 10,
                  minLines: keyboardVisible ? 3 : 5,
                  dialogTitle: widget.title,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入消息内容',
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actionButtons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actionButtons[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
