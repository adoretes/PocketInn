import 'package:flutter/material.dart';

import '../models/chat_variables.dart';
import '../models/variable_panel.dart';
import '../widgets/variable_panel_grid.dart';

/// 变量面板布局编辑页。
///
/// 内部维护组件草稿列表，只有点击保存才返回新配置；取消不污染角色卡。
/// 拖动只改变组件顺序，视觉位置由网格重新装箱决定。
class VariablePanelEditorPage extends StatefulWidget {
  const VariablePanelEditorPage({
    super.key,
    required this.variables,
    this.initialConfig,
  });

  /// 角色卡声明的初始变量。
  final List<ChatVariable> variables;

  /// 卡里已有的布局；null 表示尚未配置（进入时按变量生成默认布局）。
  final VariablePanelConfig? initialConfig;

  @override
  State<VariablePanelEditorPage> createState() =>
      _VariablePanelEditorPageState();
}

class _VariablePanelEditorPageState extends State<VariablePanelEditorPage> {
  late List<VariablePanelItem> _items;

  /// 进入页面时的布局快照，用于判断是否有未保存的改动。
  late final List<VariablePanelItem> _initialItems;
  late final VariableState _previewState = VariableState.fromCardVariables(
    widget.variables,
  );
  int _idSeed = 0;

  @override
  void initState() {
    super.initState();
    final base =
        widget.initialConfig ??
        VariablePanelConfig.defaultForVariables(widget.variables);
    final sanitized = _sanitize(base);
    _items = List<VariablePanelItem>.from(sanitized.items);
    _initialItems = List<VariablePanelItem>.unmodifiable(_items);
  }

  /// 组件顺序、尺寸或绑定任一项变化都算未保存改动。
  bool get _hasUnsavedChanges {
    if (_initialItems.length != _items.length) {
      return true;
    }
    for (var index = 0; index < _items.length; index++) {
      final before = _initialItems[index];
      final after = _items[index];
      if (before.id != after.id ||
          before.type != after.type ||
          before.columnSpan != after.columnSpan ||
          before.rowSpan != after.rowSpan ||
          before.variableName != after.variableName ||
          before.showTitle != after.showTitle ||
          before.title != after.title) {
        return true;
      }
    }
    return false;
  }

  /// 补齐/清理与当前变量列表不一致的组件，避免编辑页出现死绑定。
  VariablePanelConfig _sanitize(VariablePanelConfig config) {
    final byName = {
      for (final variable in widget.variables)
        variable.name.trim().toLowerCase(): variable,
    };
    final items = <VariablePanelItem>[];
    for (final item in config.items) {
      if (!item.isBound) {
        items.add(item);
        continue;
      }
      final variable = byName[item.variableName!.trim().toLowerCase()];
      if (variable == null) {
        continue;
      }
      items.add(
        item.type.accepts(variable.type)
            ? item
            : item.copyWith(type: VariablePanelItem.defaultTypeFor(variable)),
      );
    }
    return config.copyWith(items: List<VariablePanelItem>.unmodifiable(items));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('变量面板布局'),
          actions: [
            TextButton(
              onPressed: widget.variables.isEmpty ? null : _resetToDefault,
              child: const Text('恢复默认'),
            ),
            const SizedBox(width: 4),
            FilledButton(onPressed: _save, child: const Text('保存')),
            const SizedBox(width: 12),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              '固定 $kVariablePanelColumns 列方形网格，组件宽高可在 '
              '$kVariablePanelMinSpan~$kVariablePanelMaxWidth 列、'
              '$kVariablePanelMinSpan~$kVariablePanelMaxHeight 行内调整。'
              '长按卡片拖动可调整顺序，网格会自动重排。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildPreview(context, colorScheme),
            const SizedBox(height: 24),
            Text('添加组件', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '文本组件按纯文本展示，不支持 Markdown。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in VariablePanelComponentType.values)
                  _ComponentChip(type: type, onTap: () => _addComponent(type)),
              ],
            ),
            if (widget.variables.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '角色卡尚未声明初始状态变量，请先在「初始状态变量」中添加变量。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 有未保存改动时拦截返回，二次确认后才放弃。
  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }
    final discard = await _confirmDiscard();
    if (!discard || !mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃修改？'),
        content: const Text('面板布局的改动尚未保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildPreview(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('预览', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              // 与聊天抽屉的内宽保持一致，预览即所得。
              constraints: const BoxConstraints(maxWidth: 304),
              child: _items.isEmpty
                  ? _buildEmptyPreview(context, colorScheme)
                  : VariablePanelGridView(
                      items: _items,
                      itemBuilder: (context, item) =>
                          _buildDraggableItem(context, item),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        '还没有组件，从下方添加',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildDraggableItem(BuildContext context, VariablePanelItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 80.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 80.0;

        Widget buildTile({required bool highlighted}) {
          return VariablePanelTile(
            item: item,
            variable: resolvePanelVariable(_previewState, item.variableName),
            editing: true,
            selected: highlighted,
          );
        }

        return DragTarget<VariablePanelItem>(
          onWillAcceptWithDetails: (details) => details.data.id != item.id,
          onAcceptWithDetails: (details) {
            _moveItem(details.data.id, item.id);
          },
          builder: (context, candidate, rejected) {
            final highlighted = candidate.isNotEmpty;
            return LongPressDraggable<VariablePanelItem>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: buildTile(highlighted: true),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.32,
                child: buildTile(highlighted: false),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editItem(item),
                child: buildTile(highlighted: highlighted),
              ),
            );
          },
        );
      },
    );
  }

  /// 拖拽排序统一走 [VariablePanelConfig.moveItem]，
  /// 避免模型与页面各维护一份移动逻辑。
  void _moveItem(String sourceId, String targetId) {
    final from = _items.indexWhere((item) => item.id == sourceId);
    final to = _items.indexWhere((item) => item.id == targetId);
    if (from < 0 || to < 0) {
      return;
    }
    final current = VariablePanelConfig(items: _items);
    final moved = current.moveItem(from, to);
    if (identical(moved, current)) {
      return;
    }
    setState(() => _items = List<VariablePanelItem>.from(moved.items));
  }

  Future<void> _addComponent(VariablePanelComponentType type) async {
    if (type == VariablePanelComponentType.blank) {
      _appendItem(
        VariablePanelItem(
          id: _newItemId(),
          type: type,
          width: _defaultWidthFor(type),
          height: _defaultHeightFor(type),
          showTitle: false,
        ),
      );
      return;
    }

    final candidates = [
      for (final variable in widget.variables)
        if (type.accepts(variable.type)) variable,
    ];
    if (candidates.isEmpty) {
      _showHint(_noVariableHint(type));
      return;
    }

    final variable = candidates.length == 1
        ? candidates.first
        : await _pickVariable(type, candidates);
    if (variable == null || !mounted) {
      return;
    }

    _appendItem(
      VariablePanelItem(
        id: _newItemId(),
        type: type,
        width: _defaultWidthFor(type),
        height: _defaultHeightFor(type),
        variableName: variable.name,
      ),
    );
  }

  void _appendItem(VariablePanelItem item) {
    setState(() => _items = [..._items, item]);
  }

  Future<ChatVariable?> _pickVariable(
    VariablePanelComponentType type,
    List<ChatVariable> candidates,
  ) {
    return showModalBottomSheet<ChatVariable>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '选择要绑定的变量（${type.label}）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final variable in candidates)
                ListTile(
                  title: Text(variable.name),
                  subtitle: Text(
                    '${variable.type.label} · ${variable.value}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(variable),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editItem(VariablePanelItem item) async {
    final result = await showModalBottomSheet<_ItemEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _VariablePanelItemSheet(item: item, variables: widget.variables),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (result.deleted) {
        _items = [
          for (final existing in _items)
            if (existing.id != item.id) existing,
        ];
      } else if (result.item != null) {
        _items = [
          for (final existing in _items)
            if (existing.id == item.id) result.item! else existing,
        ];
      }
    });
  }

  void _resetToDefault() {
    setState(() {
      _items = List<VariablePanelItem>.from(
        VariablePanelConfig.defaultForVariables(widget.variables).items,
      );
    });
  }

  void _save() {
    Navigator.of(context).pop(
      VariablePanelConfig(items: List<VariablePanelItem>.unmodifiable(_items)),
    );
  }

  String _newItemId() {
    final seed = _idSeed++;
    return 'item_${DateTime.now().microsecondsSinceEpoch}_$seed';
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _noVariableHint(VariablePanelComponentType type) {
    switch (type) {
      case VariablePanelComponentType.capsule:
        return '没有可用的枚举变量：请先添加枚举类型变量';
      case VariablePanelComponentType.progress:
      case VariablePanelComponentType.cursor:
        return '没有可用的数值变量：请先添加数值类型变量';
      case VariablePanelComponentType.multilineText:
        return '没有可用的文本变量：请先添加文本类型变量';
      case VariablePanelComponentType.text:
      case VariablePanelComponentType.blank:
        return '暂无可绑定的变量';
    }
  }
}

int _defaultWidthFor(VariablePanelComponentType type) {
  switch (type) {
    case VariablePanelComponentType.capsule:
    case VariablePanelComponentType.progress:
    case VariablePanelComponentType.multilineText:
      return 2;
    case VariablePanelComponentType.text:
    case VariablePanelComponentType.cursor:
    case VariablePanelComponentType.blank:
      return 1;
  }
}

int _defaultHeightFor(VariablePanelComponentType type) {
  return type == VariablePanelComponentType.multilineText ? 2 : 1;
}

class _ComponentChip extends StatelessWidget {
  const _ComponentChip({required this.type, required this.onTap});

  final VariablePanelComponentType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(_iconFor(type), size: 16, color: colorScheme.primary),
      label: Text(type.label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

IconData _iconFor(VariablePanelComponentType type) {
  switch (type) {
    case VariablePanelComponentType.capsule:
      return Icons.label_outline;
    case VariablePanelComponentType.text:
      return Icons.text_fields;
    case VariablePanelComponentType.multilineText:
      return Icons.notes;
    case VariablePanelComponentType.progress:
      return Icons.linear_scale;
    case VariablePanelComponentType.cursor:
      return Icons.adjust;
    case VariablePanelComponentType.blank:
      return Icons.crop_square;
  }
}

class _ItemEditResult {
  const _ItemEditResult({this.item, this.deleted = false});

  final VariablePanelItem? item;
  final bool deleted;
}

/// 单个组件的编辑弹窗。
class _VariablePanelItemSheet extends StatefulWidget {
  const _VariablePanelItemSheet({required this.item, required this.variables});

  final VariablePanelItem item;
  final List<ChatVariable> variables;

  @override
  State<_VariablePanelItemSheet> createState() =>
      _VariablePanelItemSheetState();
}

class _VariablePanelItemSheetState extends State<_VariablePanelItemSheet> {
  late VariablePanelComponentType _type;
  late int _width;
  late int _height;
  late bool _showTitle;
  late final TextEditingController _titleController;
  String? _variableName;

  @override
  void initState() {
    super.initState();
    _type = widget.item.type;
    _width = widget.item.columnSpan;
    _height = widget.item.rowSpan;
    _showTitle = widget.item.showTitle;
    _titleController = TextEditingController(text: widget.item.title ?? '');
    _variableName = widget.item.variableName;
    _ensureCompatibleVariable();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<ChatVariable> get _compatibleVariables => [
    for (final variable in widget.variables)
      if (_type.accepts(variable.type)) variable,
  ];

  void _ensureCompatibleVariable() {
    if (!_type.bindsVariable) {
      _variableName = null;
      return;
    }
    final current = _variableName;
    final exists =
        current != null &&
        _compatibleVariables.any((variable) => variable.name == current);
    if (!exists) {
      _variableName = _compatibleVariables.isEmpty
          ? null
          : _compatibleVariables.first.name;
    }
  }

  bool get _canSave => !_type.bindsVariable || _variableName != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compatible = _compatibleVariables;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('组件设置', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildTypeField(),
            if (_type.bindsVariable) ...[
              const SizedBox(height: 12),
              _buildVariableField(compatible),
            ],
            const SizedBox(height: 12),
            Text('尺寸', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildSpanControl(
                    label: '宽（列）',
                    name: '宽度',
                    value: _width,
                    max: kVariablePanelMaxWidth,
                    onChanged: (value) => setState(() => _width = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSpanControl(
                    label: '高（行）',
                    name: '高度',
                    value: _height,
                    max: kVariablePanelMaxHeight,
                    onChanged: (value) => setState(() => _height = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('显示标题'),
              subtitle: Text(
                '标题留空时使用变量名',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: _showTitle,
              onChanged: (value) => setState(() => _showTitle = value),
            ),
            if (_showTitle)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '自定义标题（可选）',
                  hintText: _variableName ?? '标题',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(const _ItemEditResult(deleted: true));
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除组件'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave ? _submit : null,
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpanControl({
    required String label,
    required String name,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '减少$name',
            onPressed: value > kVariablePanelMinSpan
                ? () => onChanged(value - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: '增加$name',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '组件类型',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VariablePanelComponentType>(
          isExpanded: true,
          value: _type,
          items: [
            for (final type in VariablePanelComponentType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _type = value;
              _ensureCompatibleVariable();
            });
          },
        ),
      ),
    );
  }

  Widget _buildVariableField(List<ChatVariable> compatible) {
    if (compatible.isEmpty) {
      return Text(
        '没有可绑定的变量，请先声明对应类型的变量。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '绑定变量',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: compatible.any((variable) => variable.name == _variableName)
              ? _variableName
              : null,
          hint: const Text('请选择变量'),
          items: [
            for (final variable in compatible)
              DropdownMenuItem(
                value: variable.name,
                child: Text(
                  '${variable.name}（${variable.type.label}）',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _variableName = value),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    Navigator.of(context).pop(
      _ItemEditResult(
        item: widget.item.copyWith(
          type: _type,
          width: _width,
          height: _height,
          variableName: _type.bindsVariable ? _variableName : null,
          showTitle: _showTitle,
          title: title.isEmpty ? null : title,
        ),
      ),
    );
  }
}
