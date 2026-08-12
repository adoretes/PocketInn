import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/regex_rule_group.dart';
import '../services/regex_rule_group_service.dart';
import '../widgets/expanded_text_editor_field.dart';

class RegexRuleGroupEditPage extends StatefulWidget {
  const RegexRuleGroupEditPage({
    super.key,
    required this.group,
    this.isNewGroup = false,
  });

  final RegexRuleGroup group;
  final bool isNewGroup;

  @override
  State<RegexRuleGroupEditPage> createState() => _RegexRuleGroupEditPageState();
}

class _RegexRuleGroupEditPageState extends State<RegexRuleGroupEditPage> {
  late RegexRuleGroup _group;
  final Set<String> _expandedRules = {};

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _group = widget.group.copyWith();
    _nameController = TextEditingController(text: _group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('规则组名称不能为空')));
      return;
    }

    for (final rule in _group.rules) {
      if (!rule.enabled) continue;
      final error = rule.validateRegex();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('规则「${rule.name}」保存失败：$error')),
        );
        setState(() {
          _expandedRules.add(rule.id);
        });
        return;
      }
    }

    _group = _group.copyWith(name: trimmedName, updatedAt: DateTime.now());

    await RegexRuleGroupService.instance.save(_group);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('规则组已保存')));
    Navigator.pop(context, true);
  }

  void _addNewRule() {
    final rule = RegexRule(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      name: '新规则',
      findRegex: '',
      replaceString: '',
      applyToUser: true,
      applyToAssistant: true,
      enabled: true,
    );
    setState(() {
      _group = _group.copyWith(rules: [..._group.rules, rule]);
      _expandedRules.add(rule.id);
    });
  }

  Future<void> _onImportStRules() async {
    try {
      final result = await RegexRuleGroupService.instance
          .importStRulesFromFile();
      if (result.rules.isEmpty || !mounted) return;

      setState(() {
        _group = _group.copyWith(rules: [..._group.rules, ...result.rules]);
        for (final rule in result.rules) {
          _expandedRules.add(rule.id);
        }
      });

      if (!mounted) return;
      final warning = result.warningText;
      final message = warning.isEmpty
          ? '已导入 ${result.rules.length} 条规则'
          : '已导入 ${result.rules.length} 条规则\n$warning';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  void _deleteRule(RegexRule rule) {
    setState(() {
      _group = _group.copyWith(
        rules: _group.rules
            .where((item) => item.id != rule.id)
            .toList(),
      );
      _expandedRules.remove(rule.id);
    });
  }

  void _toggleRuleEnabled(RegexRule rule, bool value) {
    _updateRule(rule.copyWith(enabled: value));
  }

  void _updateRule(RegexRule updated) {
    setState(() {
      _group = _group.copyWith(
        rules: _group.rules
            .map((r) => r.id == updated.id ? updated : r)
            .toList(),
      );
    });
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedRules.contains(id)) {
        _expandedRules.remove(id);
      } else {
        _expandedRules.add(id);
      }
    });
  }

  void _reorderRules(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = [..._group.rules];
      final rule = items.removeAt(oldIndex);
      items.insert(newIndex, rule);
      _group = _group.copyWith(rules: items);
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
            hintText: '规则组名称',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            setState(() {
              _group = _group.copyWith(name: value);
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '从文件导入规则（兼容 ST 正则脚本）',
            onPressed: _onImportStRules,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建规则',
            onPressed: _addNewRule,
          ),
          TextButton(onPressed: _onSave, child: const Text('保存')),
        ],
      ),
      body: _group.rules.isEmpty
          ? const Center(child: Text('暂无规则，点击右上角 + 新建'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _group.rules.length,
              onReorder: _reorderRules,
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
                final rule = _group.rules[index];
                return _RuleCard(
                  key: ValueKey(rule.id),
                  rule: rule,
                  index: index,
                  isExpanded: _expandedRules.contains(rule.id),
                  onToggleExpanded: () => _toggleExpanded(rule.id),
                  onToggleEnabled: (value) => _toggleRuleEnabled(rule, value),
                  onDelete: () => _deleteRule(rule),
                  onUpdateRule: _updateRule,
                );
              },
            ),
    );
  }
}

class _RuleCard extends StatefulWidget {
  const _RuleCard({
    super.key,
    required this.rule,
    required this.index,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleEnabled,
    required this.onDelete,
    required this.onUpdateRule,
  });

  final RegexRule rule;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onDelete;
  final ValueChanged<RegexRule> onUpdateRule;

  @override
  State<_RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<_RuleCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _findRegexController;
  late final TextEditingController _replaceStringController;
  late final TextEditingController _minDepthController;
  late final TextEditingController _maxDepthController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule.name);
    _findRegexController = TextEditingController(text: widget.rule.findRegex);
    _replaceStringController = TextEditingController(
      text: widget.rule.replaceString,
    );
    _minDepthController = TextEditingController(
      text: widget.rule.minDepth?.toString() ?? '',
    );
    _maxDepthController = TextEditingController(
      text: widget.rule.maxDepth?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _RuleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.name != widget.rule.name &&
        _nameController.text != widget.rule.name) {
      _nameController.text = widget.rule.name;
    }
    if (oldWidget.rule.findRegex != widget.rule.findRegex &&
        _findRegexController.text != widget.rule.findRegex) {
      _findRegexController.text = widget.rule.findRegex;
    }
    if (oldWidget.rule.replaceString != widget.rule.replaceString &&
        _replaceStringController.text != widget.rule.replaceString) {
      _replaceStringController.text = widget.rule.replaceString;
    }
    if (oldWidget.rule.minDepth != widget.rule.minDepth &&
        _minDepthController.text !=
            (widget.rule.minDepth?.toString() ?? '')) {
      _minDepthController.text = widget.rule.minDepth?.toString() ?? '';
    }
    if (oldWidget.rule.maxDepth != widget.rule.maxDepth &&
        _maxDepthController.text !=
            (widget.rule.maxDepth?.toString() ?? '')) {
      _maxDepthController.text = widget.rule.maxDepth?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _findRegexController.dispose();
    _replaceStringController.dispose();
    _minDepthController.dispose();
    _maxDepthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
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
            onTap: widget.onToggleExpanded,
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
                      rule.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: rule.enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.72,
                              ),
                      ),
                    ),
                  ),
                  ..._stageIconEntries(rule, context),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
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
                      value: rule.enabled,
                      onChanged: widget.onToggleEnabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '规则名称',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onUpdateRule(rule.copyWith(name: value));
                    },
                  ),
                  const SizedBox(height: 12),
                  ExpandedTextEditorField(
                    controller: _findRegexController,
                    maxLines: 3,
                    dialogTitle: '编辑查找正则',
                    decoration: const InputDecoration(
                      labelText: '查找正则表达式',
                      hintText: '例如：<CoT>[\\n\\s\\S]*</CoT>',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onUpdateRule(rule.copyWith(findRegex: value));
                    },
                  ),
                  const SizedBox(height: 12),
                  ExpandedTextEditorField(
                    controller: _replaceStringController,
                    maxLines: 4,
                    dialogTitle: '编辑替换字符串',
                    decoration: const InputDecoration(
                      labelText: '替换字符串',
                      hintText: r'支持 $1、$2 等捕获组引用，留空表示删除匹配内容',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onUpdateRule(
                        rule.copyWith(replaceString: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('作用范围：', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('用户'),
                        selected: rule.applyToUser,
                        onSelected: (value) {
                          widget.onUpdateRule(
                            rule.copyWith(applyToUser: value),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('助手'),
                        selected: rule.applyToAssistant,
                        onSelected: (value) {
                          widget.onUpdateRule(
                            rule.copyWith(applyToAssistant: value),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DepthField(
                          label: '最小深度',
                          hint: '从最新向前计数，留空不限',
                          controller: _minDepthController,
                          onChanged: (value) {
                            widget.onUpdateRule(
                              rule.copyWith(
                                minDepth: value,
                                clearMinDepth: value == null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DepthField(
                          label: '最大深度',
                          hint: '从最新向前计数，留空不限',
                          controller: _maxDepthController,
                          onChanged: (value) {
                            widget.onUpdateRule(
                              rule.copyWith(
                                maxDepth: value,
                                clearMaxDepth: value == null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStageSelector(rule),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _stageIconEntries(RegexRule rule, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = <(IconData, String)>[
      if (rule.applyOnWrite) (Icons.edit_note, '写入'),
      if (rule.applyOnDisplay) (Icons.visibility_outlined, '显示'),
      if (rule.applyOnSend) (Icons.send_outlined, '发送'),
    ];
    return [
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: '${entry.$2}时替换',
            child: Icon(
              entry.$1,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
        ),
    ];
  }

  Widget _buildStageSelector(RegexRule rule) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = <String>{
      if (rule.applyOnWrite) 'write',
      if (rule.applyOnDisplay) 'display',
      if (rule.applyOnSend) 'send',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('生效时机：', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'write',
                label: Text('写入'),
                icon: Icon(Icons.edit_note),
              ),
              ButtonSegment(
                value: 'display',
                label: Text('显示'),
                icon: Icon(Icons.visibility_outlined),
              ),
              ButtonSegment(
                value: 'send',
                label: Text('发送'),
                icon: Icon(Icons.send_outlined),
              ),
            ],
            selected: selected,
            multiSelectionEnabled: true,
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              widget.onUpdateRule(
                rule.copyWith(
                  applyOnWrite: selection.contains('write'),
                  applyOnDisplay: selection.contains('display'),
                  applyOnSend: selection.contains('send'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          selected.isEmpty
              ? '未选择任何时机，规则不会生效'
              : '写入：替换聊天记录；显示：仅替换界面渲染；发送：仅替换送往模型的请求',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DepthField extends StatelessWidget {
  const _DepthField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      onChanged: (value) {
        if (value.trim().isEmpty) {
          onChanged(null);
          return;
        }
        final parsed = int.tryParse(value);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}
