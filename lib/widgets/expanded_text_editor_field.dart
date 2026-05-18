import 'package:flutter/material.dart';

class ExpandedTextEditorField extends StatelessWidget {
  const ExpandedTextEditorField({
    super.key,
    required this.controller,
    required this.decoration,
    this.dialogTitle,
    this.maxLines,
    this.minLines,
    this.style,
    this.textAlignVertical,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.contentMaxLines = 24,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final String? dialogTitle;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final TextAlignVertical? textAlignVertical;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final int contentMaxLines;

  Future<void> _openExpandedEditor(BuildContext context) async {
    if (!enabled) return;

    final result = await showDialog<String>(
      context: context,
      useSafeArea: false,
      builder: (context) => _ExpandedTextEditorDialog(
        initialText: controller.text,
        title: dialogTitle ?? decoration.labelText ?? '编辑内容',
        hintText: decoration.hintText,
        style: style,
      ),
    );

    if (!context.mounted) return;
    if (result == null || result == controller.text) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
      composing: TextRange.empty,
    );
    onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: style,
          textAlignVertical: textAlignVertical,
          validator: validator,
          onChanged: onChanged,
          decoration: decoration,
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: IconButton(
            onPressed: enabled ? () => _openExpandedEditor(context) : null,
            icon: const Icon(Icons.open_in_full, size: 16),
            tooltip: '展开编辑',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _ExpandedTextEditorDialog extends StatefulWidget {
  const _ExpandedTextEditorDialog({
    required this.initialText,
    required this.title,
    this.hintText,
    this.style,
  });

  final String initialText;
  final String title;
  final String? hintText;
  final TextStyle? style;

  @override
  State<_ExpandedTextEditorDialog> createState() =>
      _ExpandedTextEditorDialogState();
}

class _ExpandedTextEditorDialogState extends State<_ExpandedTextEditorDialog> {
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

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: () => Navigator.of(context).pop()),
          title: Text(widget.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              child: const Text('完成'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: widget.style,
            decoration: InputDecoration(
              hintText: widget.hintText,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
