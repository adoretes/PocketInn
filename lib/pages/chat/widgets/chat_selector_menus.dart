import 'package:flutter/material.dart';

import '../../../models/preset.dart';
import '../../../models/user_setting.dart';
import '../../../models/world_book.dart';
import '../../../services/regex_rule_group_service.dart';

/// 菜单项描述数据，由各公开菜单函数把业务模型映射而来。
class _MenuEntry {
  const _MenuEntry({
    required this.id,
    required this.name,
    required this.isSelected,
    required this.highlightColor,
    required this.accentColor,
    this.leading,
    this.canEdit = true,
  });

  final String id;
  final String name;
  final bool isSelected;
  final Color highlightColor;

  /// 选中时的描边与文字颜色，默认取主题主色；
  /// 用户设定则用其自身颜色，保证描边与填充色协调。
  final Color accentColor;
  final Widget? leading;
  final bool canEdit;
}

/// 统一的选择菜单实现（底部抽屉 + 流式胶囊）：
/// - 传入 [onSelected]（单选模式）：点击胶囊后抽屉关闭，以选中项 value 回调；
/// - 传入 [onToggle]（多选模式）：点击仅触发切换，抽屉保持打开并实时更新选中态；
/// - 传入 [onCreateEntry]：标题栏显示「新建」按钮，回调返回新项后追加到抽屉中。
Future<void> _showItemsSheet({
  required BuildContext context,
  required String title,
  required List<_MenuEntry> entries,
  required ValueChanged<String> onEdit,
  ValueChanged<String>? onSelected,
  ValueChanged<String>? onToggle,
  Future<_MenuEntry?> Function(BuildContext context)? onCreateEntry,
}) async {
  assert(onSelected != null || onToggle != null);

  // 抽屉作为模态层弹出，先收起输入法，避免键盘遮挡抽屉。
  FocusManager.instance.primaryFocus?.unfocus();

  final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _SelectorSheet(
            title: title,
            entries: entries,
            onSelected: onSelected,
            onToggle: onToggle,
            onEdit: onEdit,
            onCreateEntry: onCreateEntry,
          ),
        ),
      );
    },
  );
}

/// 显示用户设定选择菜单。选中后回调 [onSelected]，编辑图标回调 [onEdit]；
/// 传入 [onCreate] 时标题栏显示「新建」按钮，创建成功后新项会追加到菜单中。
Future<void> showUserSettingMenu({
  required BuildContext context,
  required List<UserSetting> settings,
  required String? selectedId,
  required ValueChanged<String> onSelected,
  required ValueChanged<String> onEdit,
  Future<UserSetting?> Function(BuildContext context)? onCreate,
}) async {
  _MenuEntry buildEntry(UserSetting setting) => _MenuEntry(
    id: setting.id,
    name: setting.name,
    isSelected: setting.id == selectedId,
    highlightColor: setting.color.withValues(alpha: 0.12),
    accentColor: setting.color,
    leading: _MenuAvatar(color: setting.color, text: setting.avatarText),
  );

  await _showItemsSheet(
    context: context,
    title: '用户设定',
    entries: [for (final setting in settings) buildEntry(setting)],
    onSelected: onSelected,
    onEdit: onEdit,
    onCreateEntry: onCreate == null
        ? null
        : (sheetContext) async {
            final created = await onCreate(sheetContext);
            return created == null ? null : buildEntry(created);
          },
  );
}

/// 显示世界书选择菜单。切换选中状态后回调 [onToggle]，编辑图标回调 [onEdit]。
Future<void> showWorldBookMenu({
  required BuildContext context,
  required List<WorldBook> worldBooks,
  required Set<String> selectedIds,
  required ValueChanged<String> onToggle,
  required ValueChanged<String> onEdit,
}) async {
  final primaryColor = Theme.of(context).colorScheme.primary;
  final highlightColor = primaryColor.withValues(alpha: 0.12);
  await _showItemsSheet(
    context: context,
    title: '世界书',
    entries: [
      for (final worldBook in worldBooks)
        _MenuEntry(
          id: worldBook.id,
          name: worldBook.name,
          isSelected: selectedIds.contains(worldBook.id),
          highlightColor: highlightColor,
          accentColor: primaryColor,
        ),
    ],
    onToggle: onToggle,
    onEdit: onEdit,
  );
}

/// 显示正则规则组选择菜单。切换选中状态后回调 [onToggle]，编辑图标回调 [onEdit]。
Future<void> showRegexRuleGroupMenu({
  required BuildContext context,
  required List<RegexRuleGroupSummary> groups,
  required Set<String> selectedIds,
  required ValueChanged<String> onToggle,
  required ValueChanged<String> onEdit,
}) async {
  final primaryColor = Theme.of(context).colorScheme.primary;
  final highlightColor = primaryColor.withValues(alpha: 0.12);
  await _showItemsSheet(
    context: context,
    title: '正则替换',
    entries: [
      for (final group in groups)
        _MenuEntry(
          id: group.id,
          name: group.name,
          isSelected: selectedIds.contains(group.id),
          highlightColor: highlightColor,
          accentColor: primaryColor,
        ),
    ],
    onToggle: onToggle,
    onEdit: onEdit,
  );
}

/// 显示预设选择菜单。选中后回调 [onSelected]，编辑图标回调 [onEdit]。
Future<void> showPresetMenu({
  required BuildContext context,
  required List<PresetSummary> presets,
  required String? selectedId,
  required ValueChanged<String> onSelected,
  required ValueChanged<String> onEdit,
}) async {
  final primaryColor = Theme.of(context).colorScheme.primary;
  final highlightColor = primaryColor.withValues(alpha: 0.12);
  await _showItemsSheet(
    context: context,
    title: '预设',
    entries: [
      for (final preset in presets)
        _MenuEntry(
          id: preset.id,
          name: preset.name,
          isSelected: preset.id == selectedId,
          highlightColor: highlightColor,
          accentColor: primaryColor,
          canEdit: !preset.isBuiltin,
        ),
    ],
    onSelected: onSelected,
    onEdit: onEdit,
  );
}

/// 底部抽屉内容：拖拽把手 + 标题 + 流式胶囊列表。
class _SelectorSheet extends StatefulWidget {
  const _SelectorSheet({
    required this.title,
    required this.entries,
    required this.onSelected,
    required this.onToggle,
    required this.onEdit,
    required this.onCreateEntry,
  });

  final String title;
  final List<_MenuEntry> entries;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onToggle;
  final ValueChanged<String> onEdit;
  final Future<_MenuEntry?> Function(BuildContext context)? onCreateEntry;

  @override
  State<_SelectorSheet> createState() => _SelectorSheetState();
}

class _SelectorSheetState extends State<_SelectorSheet> {
  /// 抽屉打开期间的本地条目列表，新建后追加，无需重开抽屉。
  late final List<_MenuEntry> _entries = List.of(widget.entries);

  /// 抽屉打开期间的本地选中态，保证多选切换时胶囊实时刷新。
  late final Set<String> _selectedIds = {
    for (final entry in widget.entries)
      if (entry.isSelected) entry.id,
  };

  final ScrollController _scrollController = ScrollController();

  bool _isCreating = false;

  bool get _isMultiSelect => widget.onToggle != null;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final onCreateEntry = widget.onCreateEntry;
    if (onCreateEntry == null || _isCreating) return;

    setState(() => _isCreating = true);
    try {
      final entry = await onCreateEntry(context);
      if (entry == null || !mounted) return;
      setState(() => _entries.add(entry));
      // 新项追加在末尾，滚动到底部让其可见。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _onTap(_MenuEntry entry) {
    if (_isMultiSelect) {
      setState(() {
        if (!_selectedIds.remove(entry.id)) {
          _selectedIds.add(entry.id);
        }
      });
      widget.onToggle!(entry.id);
      return;
    }

    final onSelected = widget.onSelected;
    if (onSelected != null) {
      Navigator.of(context).pop();
      onSelected(entry.id);
    }
  }

  void _onEdit(_MenuEntry entry) {
    Navigator.of(context).pop();
    widget.onEdit(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Text(
                widget.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isMultiSelect)
                Text(
                  '已选 ${_selectedIds.length}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (widget.onCreateEntry != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isCreating ? null : _onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _entries)
                  _CapsuleChip(
                    entry: entry,
                    isSelected: _selectedIds.contains(entry.id),
                    onTap: () => _onTap(entry),
                    onEditTap: entry.canEdit ? () => _onEdit(entry) : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 流式胶囊：胶囊形状的选项，选中时高亮并描边。
class _CapsuleChip extends StatelessWidget {
  const _CapsuleChip({
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onEditTap,
  });

  final _MenuEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? entry.highlightColor
        : colorScheme.surfaceContainerHighest;
    final borderColor = isSelected
        ? entry.accentColor
        : colorScheme.outlineVariant;
    final textColor = isSelected ? entry.accentColor : colorScheme.onSurface;

    final leading = entry.leading;

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: StadiumBorder(
        side: BorderSide(color: borderColor, width: isSelected ? 1.2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 无编辑按钮时左右内边距对称；有编辑按钮时右侧由按钮自身内边距补齐。
          padding: EdgeInsets.fromLTRB(12, 6, onEditTap != null ? 6 : 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (onEditTap != null) ...[
                const SizedBox(width: 2),
                _CapsuleEditButton(onTap: onEditTap!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 胶囊尾部的编辑按钮，独立于胶囊主体的点击区域。
class _CapsuleEditButton extends StatelessWidget {
  const _CapsuleEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.edit_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 用户设定菜单项行首的头像（显示名字首字）。
///
/// 用户自选的颜色饱和度较高，直接实色填充会在胶囊里显得突兀，
/// 这里改为低透明度色块 + 加深的同色文字（柔和徽章风格）。
class _MenuAvatar extends StatelessWidget {
  const _MenuAvatar({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Color.lerp(color, Colors.black, 0.35),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
