import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/preset.dart';
import '../services/preset_service.dart';
import '../widgets/expanded_text_editor_field.dart';

class PresetEditPage extends StatefulWidget {
  const PresetEditPage({
    super.key,
    required this.preset,
    this.isNewPreset = false,
  });

  final Preset preset;
  final bool isNewPreset;

  @override
  State<PresetEditPage> createState() => _PresetEditPageState();
}

class _PresetEditPageState extends State<PresetEditPage> {
  late Preset _preset;
  final Set<String> _expandedPrompts = {};

  late final TextEditingController _nameController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _contextController;
  late final TextEditingController _maxTokensController;

  @override
  void initState() {
    super.initState();
    _preset = widget.preset.copyWith();
    _nameController = TextEditingController(text: _preset.name);
    _temperatureController = TextEditingController(
      text: _preset.temperature.toStringAsFixed(2),
    );
    _contextController = TextEditingController(
      text: _preset.openaiMaxContext.toString(),
    );
    _maxTokensController = TextEditingController(
      text: _preset.openaiMaxTokens.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _temperatureController.dispose();
    _contextController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('预设名称不能为空')));
      return;
    }

    _preset
      ..name = trimmedName
      ..temperature =
          double.tryParse(_temperatureController.text) ?? _preset.temperature
      ..openaiMaxContext =
          int.tryParse(_contextController.text) ?? _preset.openaiMaxContext
      ..openaiMaxTokens =
          int.tryParse(_maxTokensController.text) ?? _preset.openaiMaxTokens
      ..updatedAt = DateTime.now();

    await PresetService.instance.save(_preset);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('预设已保存')));
    Navigator.pop(context, true);
  }

  void _addNewPrompt() {
    final prompt = PresetPrompt(
      identifier: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '新条目',
      content: '',
      role: 'system',
      systemPrompt: true,
      marker: false,
      enabled: true,
      injectionPosition: PresetInjectionPosition.relative,
      injectionDepth: 4,
    );
    setState(() {
      _preset.prompts = [..._preset.prompts, prompt];
      _expandedPrompts.add(prompt.identifier);
    });
  }

  void _deletePrompt(PresetPrompt prompt) {
    setState(() {
      _preset.prompts = _preset.prompts
          .where((item) => item.identifier != prompt.identifier)
          .toList();
      _expandedPrompts.remove(prompt.identifier);
    });
  }

  void _togglePromptEnabled(PresetPrompt prompt, bool value) {
    setState(() {
      prompt.enabled = value;
    });
  }

  void _toggleExpanded(String identifier) {
    setState(() {
      if (_expandedPrompts.contains(identifier)) {
        _expandedPrompts.remove(identifier);
      } else {
        _expandedPrompts.add(identifier);
      }
    });
  }

  void _reorderPrompts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = [..._preset.prompts];
      final prompt = items.removeAt(oldIndex);
      items.insert(newIndex, prompt);
      _preset.prompts = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(widget.isNewPreset ? '新建预设' : _preset.name),
        actions: [TextButton(onPressed: _onSave, child: const Text('保存'))],
      ),
      body: Column(
        children: [
          _buildBasicParams(),
          const Divider(height: 1),
          Expanded(child: _buildPromptList()),
        ],
      ),
    );
  }

  Widget _buildBasicParams() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '预设名称',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _preset.name = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NumericField(
                  label: '温度',
                  controller: _temperatureController,
                  allowDecimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumericField(
                  label: '上下文',
                  controller: _contextController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumericField(
                  label: '最大Token',
                  controller: _maxTokensController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addNewPrompt,
            icon: const Icon(Icons.add),
            label: const Text('新建条目'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _preset.prompts.isEmpty
              ? const Center(child: Text('暂无条目'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _preset.prompts.length,
                  onReorder: _reorderPrompts,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final prompt = _preset.prompts[index];
                    return _PromptCard(
                      key: ValueKey(prompt.identifier),
                      prompt: prompt,
                      index: index,
                      isExpanded: _expandedPrompts.contains(prompt.identifier),
                      onToggleExpanded: () =>
                          _toggleExpanded(prompt.identifier),
                      onToggleEnabled: (value) =>
                          _togglePromptEnabled(prompt, value),
                      onDelete: prompt.isDefault
                          ? null
                          : () => _deletePrompt(prompt),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.label,
    required this.controller,
    this.allowDecimal = false,
  });

  final String label;
  final TextEditingController controller;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowDecimal ? r'[0-9.]' : r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  const _PromptCard({
    super.key,
    required this.prompt,
    required this.index,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  final PresetPrompt prompt;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback? onDelete;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  late final TextEditingController _depthController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prompt.name);
    _contentController = TextEditingController(text: widget.prompt.content);
    _depthController = TextEditingController(
      text: widget.prompt.injectionDepth.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _PromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt.name != widget.prompt.name) {
      _nameController.text = widget.prompt.name;
    }
    if (oldWidget.prompt.content != widget.prompt.content) {
      _contentController.text = widget.prompt.content;
    }
    if (oldWidget.prompt.injectionDepth != widget.prompt.injectionDepth) {
      _depthController.text = widget.prompt.injectionDepth.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: prompt.marker ? null : widget.onToggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      prompt.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: prompt.marker ? Colors.grey[500] : null,
                      ),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: widget.onDelete,
                      tooltip: '删除',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: prompt.enabled,
                      onChanged: widget.onToggleEnabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded && !prompt.marker) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '名字',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        prompt.name = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ExpandedTextEditorField(
                    controller: _contentController,
                    maxLines: 5,
                    dialogTitle: '编辑预设条目内容',
                    decoration: const InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      prompt.content = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('角色：', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'system', label: Text('系统')),
                            ButtonSegment(value: 'user', label: Text('用户')),
                            ButtonSegment(
                              value: 'assistant',
                              label: Text('助手'),
                            ),
                          ],
                          selected: {prompt.role},
                          onSelectionChanged: (selection) {
                            setState(() {
                              prompt.role = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('注入位置：', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: PresetInjectionPosition.relative,
                              label: Text('相对'),
                            ),
                            ButtonSegment(
                              value: PresetInjectionPosition.inChat,
                              label: Text('对话中'),
                            ),
                          ],
                          selected: {prompt.injectionPosition},
                          onSelectionChanged: (selection) {
                            setState(() {
                              prompt.injectionPosition = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _depthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '注入深度',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      prompt.injectionDepth =
                          int.tryParse(value) ?? prompt.injectionDepth;
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
