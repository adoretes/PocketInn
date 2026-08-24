import 'package:flutter/material.dart';

import '../models/chat_variables.dart';

/// 弹出变量编辑对话框；确认返回编辑后的变量，取消返回 null。
Future<ChatVariable?> showVariableEditDialog(
  BuildContext context, {
  ChatVariable? initial,
}) {
  return showDialog<ChatVariable>(
    context: context,
    builder: (_) => _VariableEditDialog(initial: initial),
  );
}

class _VariableEditDialog extends StatefulWidget {
  const _VariableEditDialog({this.initial});

  final ChatVariable? initial;

  @override
  State<_VariableEditDialog> createState() => _VariableEditDialogState();
}

class _VariableEditDialogState extends State<_VariableEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _unitController;
  late final TextEditingController _enumOptionsController;
  ChatVariableType _type = ChatVariableType.number;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _valueController = TextEditingController(text: initial?.value ?? '');
    _minController = TextEditingController(
      text: initial?.metadata?.minValue?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: initial?.metadata?.maxValue?.toStringAsFixed(0) ?? '',
    );
    _unitController = TextEditingController(text: initial?.metadata?.unit ?? '');
    _enumOptionsController = TextEditingController(
      text: initial?.metadata?.enumOptions.join(',') ?? '',
    );
    _type = initial?.type ?? ChatVariableType.number;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _unitController.dispose();
    _enumOptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 窄窗口下收紧外边距，配合更宽的内容区，避免「数值」等
      // 分段按钮标签被挤成竖排。
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Expanded(
            child: Text(widget.initial == null ? '添加变量' : '编辑变量'),
          ),
          const SizedBox(width: 12),
          SegmentedButton<ChatVariableType>(
            showSelectedIcon: false,
            segments: [
              for (final type in ChatVariableType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_type},
            onSelectionChanged: (selection) {
              setState(() {
                _type = selection.first;
              });
            },
            style: const ButtonStyle(
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              minimumSize: WidgetStatePropertyAll(Size(0, 28)),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '变量名',
                  hintText: '如：好感度、生命、状态',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: '初始值',
                  hintText: '数值或文本',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_type == ChatVariableType.number) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        decoration: const InputDecoration(
                          labelText: '最小值',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        decoration: const InputDecoration(
                          labelText: '最大值',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: '单位（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_type == ChatVariableType.enumType) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _enumOptionsController,
                  decoration: const InputDecoration(
                    labelText: '枚举选项（逗号分隔）',
                    hintText: '如：平静,动摇,心动',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final metadata = ChatVariableMetadata(
      minValue: _type == ChatVariableType.number
          ? double.tryParse(_minController.text.trim())
          : null,
      maxValue: _type == ChatVariableType.number
          ? double.tryParse(_maxController.text.trim())
          : null,
      unit: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      enumOptions: _type == ChatVariableType.enumType
          ? _enumOptionsController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
    Navigator.of(context).pop(
      ChatVariable(
        name: name,
        type: _type,
        value: _valueController.text.trim(),
        metadata: metadata,
      ),
    );
  }
}
