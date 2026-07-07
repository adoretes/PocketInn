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
  late final TextEditingController _continueNudgeController;
  late final TextEditingController _impersonationController;
  late final TextEditingController _newChatPromptController;
  late final TextEditingController _newExampleChatController;
  String _fixedRole = 'system';
  bool _enableReasoning = false;
  String _reasoningEffort = 'medium';

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
    _continueNudgeController = TextEditingController(
      text:
          (_preset.extra['continue_nudge_prompt'] as String?) ??
          '[Continue your last message without repeating its original content.]',
    );
    _impersonationController = TextEditingController(
      text:
          (_preset.extra['impersonation_prompt'] as String?) ??
          '[Write your next reply from the point of view of {{user}}, using the chat history so far as a guideline for the writing style of {{user}}. Don\'t write as {{char}} or system. Don\'t describe actions of {{char}}.]',
    );
    _newChatPromptController = TextEditingController(
      text:
          (_preset.extra['new_chat_prompt'] as String?) ?? '[Start a new Chat]',
    );
    _newExampleChatController = TextEditingController(
      text:
          (_preset.extra['new_example_chat_prompt'] as String?) ??
          '[Example Chat]',
    );
    _fixedRole = _preset.extra['fixed_prompts_role'] as String? ?? 'system';
    _enableReasoning = _preset.extra['enable_reasoning'] as bool? ?? false;
    _reasoningEffort = _preset.extra['reasoning_effort'] as String? ?? 'medium';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _temperatureController.dispose();
    _contextController.dispose();
    _maxTokensController.dispose();
    _continueNudgeController.dispose();
    _impersonationController.dispose();
    _newChatPromptController.dispose();
    _newExampleChatController.dispose();
    super.dispose();
  }

  void _updateExtraField(String key, String value) {
    setState(() {
      _preset = _preset.copyWith(extra: {..._preset.extra, key: value});
    });
  }

  Future<void> _onSave() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('预设名称不能为空')));
      return;
    }

    _preset = _preset.copyWith(
      name: trimmedName,
      temperature:
          double.tryParse(_temperatureController.text) ?? _preset.temperature,
      openaiMaxContext:
          int.tryParse(_contextController.text) ?? _preset.openaiMaxContext,
      openaiMaxTokens:
          int.tryParse(_maxTokensController.text) ?? _preset.openaiMaxTokens,
      extra: {
        ..._preset.extra,
        'continue_nudge_prompt': _continueNudgeController.text,
        'impersonation_prompt': _impersonationController.text,
        'new_chat_prompt': _newChatPromptController.text,
        'new_example_chat_prompt': _newExampleChatController.text,
        'fixed_prompts_role': _fixedRole,
        'enable_reasoning': _enableReasoning,
        'reasoning_effort': _reasoningEffort,
      },
      updatedAt: DateTime.now(),
    );

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
      injectionOrder: 100,
    );
    setState(() {
      _preset = _preset.copyWith(prompts: [..._preset.prompts, prompt]);
      _expandedPrompts.add(prompt.identifier);
    });
  }

  void _deletePrompt(PresetPrompt prompt) {
    setState(() {
      _preset = _preset.copyWith(
        prompts: _preset.prompts
            .where((item) => item.identifier != prompt.identifier)
            .toList(),
      );
      _expandedPrompts.remove(prompt.identifier);
    });
  }

  void _togglePromptEnabled(PresetPrompt prompt, bool value) {
    _updatePrompt(prompt.copyWith(enabled: value));
  }

  void _updatePrompt(PresetPrompt updated) {
    setState(() {
      _preset = _preset.copyWith(
        prompts: _preset.prompts
            .map((p) => p.identifier == updated.identifier ? updated : p)
            .toList(),
      );
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
      _preset = _preset.copyWith(prompts: items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '预设名称',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            setState(() {
              _preset = _preset.copyWith(name: value);
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '高级参数',
            onPressed: _showAdvancedSettingsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建条目',
            onPressed: _addNewPrompt,
          ),
          TextButton(onPressed: _onSave, child: const Text('保存')),
        ],
      ),
      body: _buildPromptList(),
    );
  }

  void _showAdvancedSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('思考开关：', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Switch(
                            value: _enableReasoning,
                            onChanged: (value) {
                              setModalState(() {
                                _enableReasoning = value;
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          const Text('思考层级：', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_reasoningEffort),
                              initialValue: _reasoningEffort,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'auto',
                                  child: Text('自动'),
                                ),
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text('低'),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('中'),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('高'),
                                ),
                                DropdownMenuItem(
                                  value: 'xhigh',
                                  child: Text('超高'),
                                ),
                                DropdownMenuItem(
                                  value: 'max',
                                  child: Text('最大'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(() {
                                    _reasoningEffort = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('注入身份：', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'system',
                                  label: Text('系统'),
                                ),
                                ButtonSegment(value: 'user', label: Text('用户')),
                                ButtonSegment(
                                  value: 'assistant',
                                  label: Text('助手'),
                                ),
                              ],
                              selected: {_fixedRole},
                              onSelectionChanged: (selection) {
                                setModalState(() {
                                  _fixedRole = selection.first;
                                });
                                _updateExtraField(
                                  'fixed_prompts_role',
                                  _fixedRole,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newChatPromptController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          labelText: '新对话标记',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) =>
                            _updateExtraField('new_chat_prompt', value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newExampleChatController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          labelText: '示例对话标记',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) =>
                            _updateExtraField('new_example_chat_prompt', value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _continueNudgeController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '继续推进提示',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) =>
                            _updateExtraField('continue_nudge_prompt', value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _impersonationController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '助手帮答提示',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) =>
                            _updateExtraField('impersonation_prompt', value),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromptList() {
    return _preset.prompts.isEmpty
        ? const Center(child: Text('暂无条目，点击右上角 + 新建'))
        : ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _preset.prompts.length,
            onReorder: _reorderPrompts,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Material(
                    color: Colors.transparent,
                    shadowColor: Colors.transparent,
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final prompt = _preset.prompts[index];
              return _PromptCard(
                key: ValueKey(prompt.identifier),
                prompt: prompt,
                index: index,
                isExpanded: _expandedPrompts.contains(prompt.identifier),
                onToggleExpanded: () => _toggleExpanded(prompt.identifier),
                onToggleEnabled: (value) => _togglePromptEnabled(prompt, value),
                onDelete: prompt.isDefault ? null : () => _deletePrompt(prompt),
                onUpdatePrompt: _updatePrompt,
              );
            },
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
    required this.onUpdatePrompt,
  });

  final PresetPrompt prompt;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback? onDelete;
  final ValueChanged<PresetPrompt> onUpdatePrompt;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  late final TextEditingController _depthController;
  late final TextEditingController _orderController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prompt.name);
    _contentController = TextEditingController(text: widget.prompt.content);
    _depthController = TextEditingController(
      text: widget.prompt.injectionDepth.toString(),
    );
    _orderController = TextEditingController(
      text: widget.prompt.injectionOrder.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _PromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt.name != widget.prompt.name &&
        _nameController.text != widget.prompt.name) {
      _nameController.text = widget.prompt.name;
    }
    if (oldWidget.prompt.content != widget.prompt.content &&
        _contentController.text != widget.prompt.content) {
      _contentController.text = widget.prompt.content;
    }
    if (oldWidget.prompt.injectionDepth != widget.prompt.injectionDepth &&
        _depthController.text != widget.prompt.injectionDepth.toString()) {
      _depthController.text = widget.prompt.injectionDepth.toString();
    }
    if (oldWidget.prompt.injectionOrder != widget.prompt.injectionOrder &&
        _orderController.text != widget.prompt.injectionOrder.toString()) {
      _orderController.text = widget.prompt.injectionOrder.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _depthController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
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
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
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
                        color: prompt.marker
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.72,
                              )
                            : colorScheme.onSurface,
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
                      widget.onUpdatePrompt(prompt.copyWith(name: value));
                    },
                  ),
                  const SizedBox(height: 12),
                  ExpandedTextEditorField(
                    controller: _contentController,
                    maxLines: 8,
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
                      widget.onUpdatePrompt(prompt.copyWith(content: value));
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
                            widget.onUpdatePrompt(
                              prompt.copyWith(role: selection.first),
                            );
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
                            widget.onUpdatePrompt(
                              prompt.copyWith(
                                injectionPosition: selection.first,
                              ),
                            );
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
                      widget.onUpdatePrompt(
                        prompt.copyWith(
                          injectionDepth:
                              int.tryParse(value) ?? prompt.injectionDepth,
                        ),
                      );
                    },
                  ),
                  if (prompt.injectionPosition ==
                      PresetInjectionPosition.inChat) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '注入顺序',
                        helperText: '同深度时数值越小越靠前',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        widget.onUpdatePrompt(
                          prompt.copyWith(
                            injectionOrder:
                                int.tryParse(value) ?? prompt.injectionOrder,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
