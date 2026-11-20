import 'package:flutter/material.dart';

import '../models/world_book.dart';
import '../services/world_book_service.dart';
import '../widgets/expanded_text_editor_field.dart';

// ===========================================================================
// 通用视觉组件
//
// 与「通用设置」「主题配置」页保持一致的 Material 3 分组卡片风格：
// 主题色分区小标题 + 圆角分组卡片 + 缩进分隔线 + 行首图标徽标。
// ===========================================================================

/// 分区小标题，采用 M3 设置页常见的主题色 label；可带右侧操作。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, trailing == null ? 16 : 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 分组卡片：圆角容器内承载一组内容行。
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// 分组内相邻行之间的分隔线，缩进与文字对齐。
Widget _groupDivider(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    thickness: 1,
    indent: 72,
    endIndent: 16,
    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
  );
}

/// 行首的圆角图标徽标。
class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: colorScheme.primary),
    );
  }
}

/// 基本信息中的文本输入行：左侧图标 + 上方标题 + 无边框输入框。
class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.icon,
    required this.controller,
    required this.label,
    this.hintText,
    this.maxLines = 1,
    this.textInputAction,
  });

  final IconData icon;
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeadingIcon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  textInputAction: textInputAction,
                  style: const TextStyle(fontSize: 15, height: 1.35),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 世界书编辑页
// ===========================================================================

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
  late WorldBook _baseline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worldBook.name);
    _descriptionController = TextEditingController(
      text: widget.worldBook.description,
    );
    _entries = widget.worldBook.withUniqueEntryIds().entries.toList();
    _baseline = widget.worldBook;
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
    if (_nameController.text != _baseline.name) return true;
    if (_descriptionController.text != _baseline.description) {
      return true;
    }
    if (_entries.length != _baseline.entries.length) return true;
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i] != _baseline.entries[i]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedBook = _baseline.copyWith(
        name: _nameController.text.trim().isEmpty
            ? _baseline.name
            : _nameController.text.trim(),
        description: _descriptionController.text,
        entries: List<WorldBookEntry>.from(_entries),
        updatedAt: DateTime.now(),
      );

      await WorldBookService.instance.save(updatedBook);
      _baseline = updatedBook;

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

    // 直接打开编辑对话框；用户取消时撤销这条占位条目
    final saved = await _openEntryDialog(newEntry);
    if (!saved && mounted) {
      setState(() {
        _entries = _entries.where((e) => e.id != newEntry.id).toList();
      });
    }
  }

  Future<void> _onToggleEntry(WorldBookEntry entry, bool value) async {
    setState(() {
      _entries = _entries.map((e) {
        return e.id == entry.id ? e.copyWith(isEnabled: value) : e;
      }).toList();
    });
  }

  /// 拖拽调整条目顺序。注入顺序与导出顺序均以列表顺序为准。
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, entry);
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

  /// 打开条目编辑弹窗；返回是否保存。
  Future<bool> _openEntryDialog(WorldBookEntry entry) async {
    final updated = await showDialog<WorldBookEntry>(
      context: context,
      builder: (_) => _EntryEditorDialog(entry: entry),
    );

    if (updated == null || !mounted) {
      return false;
    }

    setState(() {
      _entries = _entries
          .map((e) => e.id == entry.id ? updated : e)
          .toList();
    });
    return true;
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
              icon: const Icon(Icons.save_outlined),
              onPressed: _save,
              tooltip: '保存',
            ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
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
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('基本信息'),
            _SettingsGroup(
              children: [
                _TextFieldRow(
                  icon: Icons.menu_book_outlined,
                  controller: _nameController,
                  label: '名称',
                  hintText: '请输入世界书名称',
                  textInputAction: TextInputAction.next,
                ),
                _groupDivider(context),
                _TextFieldRow(
                  icon: Icons.subject_outlined,
                  controller: _descriptionController,
                  label: '描述',
                  hintText: '请输入世界书描述',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              '条目',
              trailing: FilledButton.tonalIcon(
                onPressed: _onCreateEntry,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_entries.isEmpty) const _EmptyEntries(),
          ],
        ),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Padding(
            key: ValueKey(entry.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: _EntryRow(
                index: index,
                entry: entry,
                onTap: () => _openEntryDialog(entry),
                onToggle: (value) => _onToggleEntry(entry, value),
                onDelete: () => _onDeleteEntry(entry),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 条目为空时的占位卡片。
class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 38,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              '暂无条目',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '点击右上角「新建」添加第一条条目',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单条条目的列表行：拖拽手柄 + 标题/预览 + 启用开关 + 删除。
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.index,
    required this.entry,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final int index;
  final WorldBookEntry entry;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 8, 8),
        child: Row(
          children: [
            // 拖拽手柄：仅此处按下才进入排序，避免与整行点击编辑冲突。
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (entry.constant) const _ConstantTag(),
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: entry.isEnabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.content.isEmpty ? '（无内容）' : entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Switch(value: entry.isEnabled, onChanged: onToggle),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '删除',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

/// 「常驻」小标签。
class _ConstantTag extends StatelessWidget {
  const _ConstantTag();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '常驻',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ===========================================================================
// 条目编辑弹窗
// ===========================================================================

/// 下拉选择框选项。
class _SelectOption {
  const _SelectOption({required this.label, required this.value});

  final String label;
  final int value;
}

/// 标签输入框组件 - 支持输入多个关键词。
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
        .split(RegExp(r'[,，]'))
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

/// 数字输入框组件 - 带范围限制。
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

/// 下拉选择框组件。
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

/// 弹窗内的分区小标题。
class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// 字段下方的说明文字。
class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 字段下方的校验提示（红色）。
class _ValidationHint extends StatelessWidget {
  const _ValidationHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

/// 条目编辑弹窗：自持表单状态，保存后通过 [Navigator.pop] 返回更新后的条目。
class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({required this.entry});

  final WorldBookEntry entry;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  static const _selectiveLogicOptions = [
    _SelectOption(label: '仅使用主要关键词', value: -1),
    _SelectOption(label: '命中任一次要关键词', value: 0),
    _SelectOption(label: '未命中全部次要关键词', value: 1),
    _SelectOption(label: '未命中任何次要关键词', value: 2),
    _SelectOption(label: '命中全部次要关键词', value: 3),
  ];

  static const _positionOptions = [
    _SelectOption(label: '角色定义之前', value: 0),
    _SelectOption(label: '角色定义之后', value: 1),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late final TextEditingController _contentController;

  late bool _enabled;
  late List<String> _key;
  late List<String> _keysecondary;
  late bool _constant;
  late int _selectiveLogic;
  late int _depth;
  late int _position;
  late int _order;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _commentController = TextEditingController(text: entry.comment);
    _contentController = TextEditingController(text: entry.content);
    _enabled = entry.isEnabled;
    _key = List<String>.from(entry.key);
    _keysecondary = List<String>.from(entry.keysecondary);
    _constant = entry.constant;
    _selectiveLogic = _displaySelectiveLogic(entry);
    _depth = entry.depth;
    // 历史数据可能带有不支持的 ST 注入位置（2/3/4），统一按「之后」展示
    _position = entry.position == 0 ? 0 : 1;
    _order = entry.order;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 历史数据中的 -1 / 越界值统一映射为「仅使用主要关键词」或默认逻辑。
  int _displaySelectiveLogic(WorldBookEntry entry) {
    if (!entry.selective) {
      return -1;
    }
    final logic = entry.selectiveLogic;
    return logic >= 0 && logic <= 3 ? logic : 0;
  }

  void _setConstant(bool value) {
    setState(() {
      _constant = value;
      if (value) {
        _selectiveLogic = -1;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_constant && _key.isEmpty) {
      _showMessage('请输入至少一个关键词');
      return;
    }
    if (!_constant && _selectiveLogic != -1 && _keysecondary.isEmpty) {
      _showMessage('请填写次要关键词，或改为仅使用主要关键词');
      return;
    }

    final useSecondary = !_constant && _selectiveLogic != -1;
    final updated = widget.entry.copyWith(
      key: _key,
      keysecondary: _keysecondary,
      content: _contentController.text,
      comment: _commentController.text,
      constant: _constant,
      selective: useSecondary,
      selectiveLogic: useSecondary ? _selectiveLogic : 0,
      depth: _depth,
      position: _position,
      order: _order,
      isEnabled: _enabled,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '编辑条目',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '启用',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== 基础信息 ==========
                const _DialogSectionLabel('基础信息'),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '仅用于内部管理，如“战斗风格描述”',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                _TagInputField(
                  tags: _key,
                  label: '关键词',
                  hintText: '输入触发关键词',
                  enabled: !_constant,
                  onChanged: (tags) => setState(() => _key = tags),
                ),
                if (_key.isEmpty && !_constant)
                  const _ValidationHint('请输入至少一个关键词'),
                const SizedBox(height: 14),
                ExpandedTextEditorField(
                  controller: _contentController,
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
                ),

                // ========== 触发条件 ==========
                const _DialogSectionLabel('触发条件'),
                CheckboxListTile(
                  value: _constant,
                  onChanged: (value) => _setConstant(value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('常驻激活'),
                ),
                const SizedBox(height: 8),
                if (!_constant) ...[
                  _SelectField(
                    value: _selectiveLogic,
                    label: '次要关键词逻辑',
                    options: _selectiveLogicOptions,
                    width: double.infinity,
                    onChanged: (value) =>
                        setState(() => _selectiveLogic = value),
                  ),
                  const _FieldHint('先命中主要关键词，再按此逻辑判断次要关键词'),
                  const SizedBox(height: 14),
                ],
                if (!_constant && _selectiveLogic != -1) ...[
                  _TagInputField(
                    tags: _keysecondary,
                    label: '次要关键词',
                    hintText: '命中主要关键词后再判断这些词',
                    onChanged: (tags) => setState(() => _keysecondary = tags),
                  ),
                  if (_keysecondary.isEmpty)
                    const _ValidationHint('请填写次要关键词，或把逻辑改为「仅使用主要关键词」'),
                  const SizedBox(height: 14),
                ],
                if (!_constant) ...[
                  _NumberInputField(
                    value: _depth,
                    label: '扫描深度',
                    minValue: 0,
                    maxValue: 20,
                    width: double.infinity,
                    onChanged: (value) => setState(() => _depth = value),
                  ),
                  const _FieldHint('扫描最近多少条聊天消息，0 表示只扫描当前输入'),
                  const SizedBox(height: 8),
                ],

                // ========== 注入控制 ==========
                const _DialogSectionLabel('注入控制'),
                _SelectField(
                  value: _position,
                  label: '注入位置',
                  options: _positionOptions,
                  width: double.infinity,
                  onChanged: (value) => setState(() => _position = value),
                ),
                const SizedBox(height: 14),
                _NumberInputField(
                  value: _order,
                  label: '优先级',
                  minValue: 0,
                  maxValue: 999,
                  width: double.infinity,
                  onChanged: (value) => setState(() => _order = value),
                ),
                const _FieldHint('同一注入位置时，数值越小越先注入'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
