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
    this.contentMaxLines = 16,
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

    final dialogController = TextEditingController(text: controller.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dialogTitle ?? decoration.labelText ?? '编辑内容',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: TextField(
                    controller: dialogController,
                    autofocus: true,
                    maxLines: contentMaxLines,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: style,
                    decoration: InputDecoration(
                      hintText: decoration.hintText,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(dialogController.text),
                      child: const Text('完成'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    dialogController.dispose();

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
          child: Material(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.82),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () => _openExpandedEditor(context),
              icon: const Icon(Icons.open_in_full, size: 16),
              tooltip: '展开编辑',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
