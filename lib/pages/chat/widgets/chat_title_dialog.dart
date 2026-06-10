import 'package:flutter/material.dart';

enum ChatTitleDialogAction { save, reset }

class ChatTitleDialogResult {
  const ChatTitleDialogResult({required this.action, required this.title});

  final ChatTitleDialogAction action;
  final String title;
}

class ChatTitleDialog extends StatefulWidget {
  const ChatTitleDialog({super.key, required this.initialTitle});

  final String initialTitle;

  @override
  State<ChatTitleDialog> createState() => _ChatTitleDialogState();
}

class _ChatTitleDialogState extends State<ChatTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeWith(ChatTitleDialogAction action) {
    Navigator.of(
      context,
    ).pop(ChatTitleDialogResult(action: action, title: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改聊天名称'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '输入聊天名称'),
        onSubmitted: (_) => _closeWith(ChatTitleDialogAction.save),
      ),
      actions: [
        IconButton(
          onPressed: () => _closeWith(ChatTitleDialogAction.reset),
          icon: const Icon(Icons.refresh),
          tooltip: '按当前选择重置聊天',
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => _closeWith(ChatTitleDialogAction.save),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
