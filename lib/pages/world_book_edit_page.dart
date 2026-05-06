import 'package:flutter/material.dart';

import '../models/world_book.dart';
import '../services/world_book_service.dart';
import '../widgets/expanded_text_editor_field.dart';

/// 标签输入框组件 - 支持输入多个关键词
class _TagInputField extends StatefulWidget {
  const _TagInputField({
    required this.tags,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;

  @override
  State<_TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<_TagInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tags.join(', '));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _TagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags && !_focusNode.hasFocus) {
      _controller.text = widget.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final tags = value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    widget.onChanged(tags);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText ?? '多个关键词请用英文逗号分隔',
        border: const OutlineInputBorder(),
      ),
      onChanged: _onChanged,
    );
  }
}

/// 数字输入框组件 - 带范围限制
class _NumberInputField extends StatelessWidget {
  const _NumberInputField({
    required this.value,
    required this.onChanged,
    this.label,
    this.minValue = 0,
    this.maxValue = 999,
    this.width = 160,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;
  final int minValue;
  final int maxValue;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          final num = int.tryParse(text);
          if (num != null) {
            onChanged(num.clamp(minValue, maxValue));
          }
        },
      ),
    );
  }
}

/// 下拉选择框选项
class _SelectOption {
  const _SelectOption({required this.label, required this.value});

  final String label;
  final int value;
}

/// 下拉选择框组件
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.onChanged,
    required this.options,
    this.label,
    this.width = 200,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final List<_SelectOption> options;
  final String? label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (opt) =>
                  DropdownMenuItem(value: opt.value, child: Text(opt.label)),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}

/// 表单区域标题组件
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class WorldBookEditPage extends StatefulWidget {
  const WorldBookEditPage({super.key, required this.worldBook});

  final WorldBook worldBook;

  @override
  State<WorldBookEditPage> createState() => _WorldBookEditPageState();
}

class _WorldBookEditPageState extends State<WorldBookEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<WorldBookEntry> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worldBook.name);
    _descriptionController = TextEditingController(
      text: widget.worldBook.description,
    );
    _entries = widget.worldBook.entries.map((item) => item.copyWith()).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onBack() async {
    if (_hasChanges()) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('保存更改'),
            content: const Text('是否保存当前更改？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('不保存'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        await _save();
      } else if (shouldSave == null) {
        return;
      }
    }

    if (mounted) {
      await Navigator.maybePop(context);
    }
  }

  bool _hasChanges() {
    if (_nameController.text != widget.worldBook.name) return true;
    if (_descriptionController.text != widget.worldBook.description) {
      return true;
    }
    if (_entries.length != widget.worldBook.entries.length) return true;
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i] != widget.worldBook.entries[i]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedBook = widget.worldBook.copyWith(
        name: _nameController.text.trim().isEmpty
            ? widget.worldBook.name
            : _nameController.text.trim(),
        description: _descriptionController.text,
        entries: _entries,
        updatedAt: DateTime.now(),
      );

      await WorldBookService.instance.save(updatedBook);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _onCreateEntry() async {
    final newEntry = WorldBookService.instance.createEntry(comment: '新条目');

    setState(() {
      _entries = [..._entries, newEntry];
    });

    // 直接打开编辑对话框
    await _openEntryDialog(newEntry);
  }

  Future<void> _onToggleEntry(WorldBookEntry entry, bool value) async {
    setState(() {
      _entries = _entries.map((e) {
        return e.id == entry.id ? e.copyWith(isEnabled: value) : e;
      }).toList();
    });
  }

  Future<void> _onDeleteEntry(WorldBookEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除条目「${entry.title}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _entries = _entries.where((e) => e.id != entry.id).toList();
      });
    }
  }

  /// 打开条目编辑弹窗
  Future<void> _openEntryDialog(WorldBookEntry entry) async {
    final formKey = GlobalKey<FormState>();

    // 表单状态
    var enabled = entry.isEnabled;
    var key = List<String>.from(entry.key);
    var keysecondary = List<String>.from(entry.keysecondary);
    var content = entry.content;
    var comment = entry.comment;
    var constant = entry.constant;
    var selectiveLogic = entry.selectiveLogic;
    var depth = entry.depth;
    var position = entry.position;
    var order = entry.order;
    var sticky = entry.sticky;
    var cooldown = entry.cooldown;
    var delay = entry.delay;
    final contentController = TextEditingController(text: content);

    // 下拉选项 - selectiveLogic 包含 NONE 选项
    const selectiveLogicOptions = [
      _SelectOption(label: '无', value: -1),
      _SelectOption(label: '任一主要关键词匹配', value: 0),
      _SelectOption(label: '全部主要关键词匹配', value: 1),
      _SelectOption(label: '不包含任一主要关键词', value: 2),
      _SelectOption(label: '不包含全部主要关键词', value: 3),
    ];

    const positionOptions = [
      _SelectOption(label: '角色定义之前', value: 0),
      _SelectOption(label: '角色定义之后', value: 1),
    ];

    void syncConstantState(bool value) {
      constant = value;
      if (constant) {
        selectiveLogic = -1;
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '编辑条目',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                // 启用/禁用开关置于标题栏右侧
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '启用',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatefulBuilder(
                      builder: (context, setSwitchState) {
                        return Switch(
                          value: enabled,
                          onChanged: (value) {
                            setSwitchState(() {
                              enabled = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ========== 基础信息区域 ==========
                        const _SectionTitle(
                          title: '基础信息',
                          icon: Icons.info_outline,
                        ),

                        // comment - 单行文本框（移到前面）
                        TextFormField(
                          initialValue: comment,
                          decoration: const InputDecoration(
                            labelText: '备注',
                            hintText: '仅用于内部管理，如"战斗风格描述"',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            comment = value;
                          },
                        ),
                        const SizedBox(height: 16),

                        // key - 标签输入框
                        _TagInputField(
                          tags: key,
                          label: '关键词',
                          hintText: '输入触发关键词',
                          enabled: !constant,
                          onChanged: (tags) {
                            setDialogState(() {
                              key = tags;
                            });
                          },
                        ),
                        if (key.isEmpty && !constant)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '请输入至少一个关键词',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // content - 多行文本框
                        ExpandedTextEditorField(
                          controller: contentController,
                          maxLines: 8,
                          minLines: 6,
                          dialogTitle: '编辑世界书条目内容',
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            labelText: '内容',
                            hintText: '激活后注入的实际文本内容',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '内容不能为空';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            content = value;
                          },
                        ),
                        const SizedBox(height: 24),

                        // ========== 触发条件区域 ==========
                        const _SectionTitle(
                          title: '触发条件',
                          icon: Icons.settings_suggest_outlined,
                        ),

                        // constant - 复选框
                        CheckboxListTile(
                          value: constant,
                          onChanged: (value) {
                            setDialogState(() {
                              syncConstantState(value ?? false);
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('常驻激活'),
                        ),
                        const SizedBox(height: 12),

                        if (!constant) ...[
                          // selectiveLogic - 下拉选择
                          _SelectField(
                            value: selectiveLogic,
                            label: '匹配逻辑',
                            options: selectiveLogicOptions,
                            width: double.infinity,
                            onChanged: (value) {
                              setDialogState(() {
                                selectiveLogic = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // keysecondary - 标签输入框（仅当 selectiveLogic != -1 时显示）
                        if (!constant && selectiveLogic != -1)
                          Opacity(
                            opacity: constant ? 0.5 : 1.0,
                            child: IgnorePointer(
                              ignoring: constant,
                              child: _TagInputField(
                                tags: keysecondary,
                                label: '次要关键词',
                                hintText: '次要触发词',
                                onChanged: (tags) {
                                  setDialogState(() {
                                    keysecondary = tags;
                                  });
                                },
                              ),
                            ),
                          ),
                        if (!constant && selectiveLogic != -1)
                          const SizedBox(height: 16),

                        // depth - 数字输入框
                        if (!constant)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NumberInputField(
                                value: depth,
                                label: '扫描深度',
                                minValue: 0,
                                maxValue: 20,
                                width: double.infinity,
                                onChanged: (value) {
                                  depth = value;
                                },
                              ),
                              const _FieldHint('在当前消息之前多少条消息内扫描关键词'),
                            ],
                          ),
                        if (!constant) const SizedBox(height: 24),

                        // ========== 注入控制区域 ==========
                        const _SectionTitle(title: '注入控制', icon: Icons.tune),

                        // position - 下拉选择
                        _SelectField(
                          value: position,
                          label: '注入位置',
                          options: positionOptions,
                          width: double.infinity,
                          onChanged: (value) {
                            setDialogState(() {
                              position = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // order - 数字输入框
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NumberInputField(
                              value: order,
                              label: '优先级',
                              minValue: 0,
                              maxValue: 999,
                              width: double.infinity,
                              onChanged: (value) {
                                order = value;
                              },
                            ),
                            const _FieldHint('同一注入位置时，数值越小越先注入'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // sticky, cooldown, delay - 数字输入框组
                        Row(
                          children: [
                            Expanded(
                              child: _NumberInputField(
                                value: sticky,
                                label: '持续',
                                minValue: 0,
                                maxValue: 999,
                                width: double.infinity,
                                onChanged: (value) {
                                  sticky = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _NumberInputField(
                                value: cooldown,
                                label: '冷却',
                                minValue: 0,
                                maxValue: 999,
                                width: double.infinity,
                                onChanged: (value) {
                                  cooldown = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _NumberInputField(
                                value: delay,
                                label: '延迟',
                                minValue: 0,
                                maxValue: 999,
                                width: double.infinity,
                                onChanged: (value) {
                                  delay = value;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  if (key.isEmpty && !constant) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请输入至少一个关键词')));
                    return;
                  }
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    contentController.dispose();

    if (saved == true && mounted) {
      // 更新条目
      final updatedEntry = entry.copyWith(
        key: key,
        keysecondary: keysecondary,
        content: content,
        comment: comment,
        constant: constant,
        selective: !constant && selectiveLogic != -1,
        selectiveLogic: constant ? -1 : selectiveLogic,
        depth: depth,
        position: position,
        order: order,
        sticky: sticky,
        cooldown: cooldown,
        delay: delay,
        isEnabled: enabled,
      );

      setState(() {
        _entries = _entries.map((e) {
          return e.id == entry.id ? updatedEntry : e;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: const Text('世界书编辑'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: '保存',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '基本信息',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '请输入世界书名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '请输入世界书描述',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '条目',
            trailing: FilledButton.icon(
              onPressed: _onCreateEntry,
              icon: const Icon(Icons.add),
              label: const Text('新建'),
            ),
            child: _entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('暂无条目，点击「新建」添加')),
                  )
                : Column(
                    children: _entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WorldBookEntryTile(
                              entry: entry,
                              onTap: () => _openEntryDialog(entry),
                              onToggle: (value) => _onToggleEntry(entry, value),
                              onDelete: () => _onDeleteEntry(entry),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing ?? const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              trailingWidget,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WorldBookEntryTile extends StatelessWidget {
  const _WorldBookEntryTile({
    required this.entry,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final WorldBookEntry entry;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;

    return Material(
      color: color.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.16 : 0.08,
      ),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (entry.constant)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '常驻',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        height: 1.45,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: entry.isEnabled, onChanged: onToggle),
              const SizedBox(width: 4),
              _EntryActionButton(
                icon: Icons.delete_outline,
                tooltip: '删除',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryActionButton extends StatelessWidget {
  const _EntryActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 18)),
      ),
    );
  }
}
