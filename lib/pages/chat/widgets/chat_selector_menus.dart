import 'package:flutter/material.dart';

import '../../../models/preset.dart';
import '../../../models/user_setting.dart';
import '../../../models/world_book.dart';
import '../../../services/regex_rule_group_service.dart';
import '../utils/popup_menu_position.dart';

/// 菜单项高度：与 [PopupMenuItem] 的默认最小高度保持一致，
/// 让 [ListTile] 恰好铺满整个菜单项，相邻选中项的色块可以无缝相连。
const double _menuTileHeight = kMinInteractiveDimension;

/// 菜单项左右内边距（选中背景色会铺满内边距区域）。
const EdgeInsets _menuTilePadding = EdgeInsets.symmetric(horizontal: 12);

/// 菜单项描述数据，由各公开菜单函数把业务模型映射而来。
class _MenuEntry {
  const _MenuEntry({
    required this.id,
    required this.name,
    required this.isSelected,
    required this.highlightColor,
    this.leading,
    this.canEdit = true,
  });

  final String id;
  final String name;
  final bool isSelected;
  final Color highlightColor;
  final Widget? leading;
  final bool canEdit;
}

/// 统一的选择菜单实现：
/// - 传入 [onSelected]（单选模式）：菜单关闭后以选中项 value 回调；
/// - 传入 [onToggle]（多选模式）：点击仅触发切换，菜单保持打开。
Future<void> _showItemsMenu({
  required BuildContext context,
  required List<_MenuEntry> entries,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onEdit,
  ValueChanged<String>? onSelected,
  ValueChanged<String>? onToggle,
}) async {
  assert(onSelected != null || onToggle != null);
  final colorScheme = Theme.of(context).colorScheme;
  final value = await showMenu<String>(
    context: context,
    requestFocus: false,
    position: PopupMenuPositioning.positionAbove(context, entries.length),
    constraints: PopupMenuPositioning.constraintsAbove(context),
    items: [
      for (final entry in entries)
        PopupMenuItem<String>(
          value: entry.id,
          padding: EdgeInsets.zero,
          onTap: onToggle == null ? null : () => onToggle(entry.id),
          child: _TapRegionWrap(
            groupId: inputTapRegionGroupId,
            child: ListTile(
              dense: true,
              minTileHeight: _menuTileHeight,
              contentPadding: _menuTilePadding,
              selected: entry.isSelected,
              selectedColor: colorScheme.onSurface,
              selectedTileColor: entry.highlightColor,
              leading: entry.leading,
              title: Text(entry.name, overflow: TextOverflow.ellipsis),
              trailing: _MenuEditButton(
                onTap: entry.canEdit
                    ? () {
                        Navigator.pop(context);
                        onEdit(entry.id);
                      }
                    : null,
              ),
            ),
          ),
        ),
    ],
  );
  if (value != null) {
    onSelected?.call(value);
  }
}

/// 显示用户设定选择菜单。选中后回调 [onSelected]，编辑图标回调 [onEdit]。
Future<void> showUserSettingMenu({
  required BuildContext context,
  required List<UserSetting> settings,
  required String? selectedId,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onSelected,
  required ValueChanged<String> onEdit,
}) async {
  await _showItemsMenu(
    context: context,
    entries: [
      for (final setting in settings)
        _MenuEntry(
          id: setting.id,
          name: setting.name,
          isSelected: setting.id == selectedId,
          highlightColor: setting.color.withValues(alpha: 0.12),
          leading: _MenuAvatar(color: setting.color, text: setting.avatarText),
        ),
    ],
    inputTapRegionGroupId: inputTapRegionGroupId,
    onSelected: onSelected,
    onEdit: onEdit,
  );
}

/// 显示世界书选择菜单。切换选中状态后回调 [onToggle]，编辑图标回调 [onEdit]。
Future<void> showWorldBookMenu({
  required BuildContext context,
  required List<WorldBook> worldBooks,
  required Set<String> selectedIds,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onToggle,
  required ValueChanged<String> onEdit,
}) async {
  final highlightColor =
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  await _showItemsMenu(
    context: context,
    entries: [
      for (final worldBook in worldBooks)
        _MenuEntry(
          id: worldBook.id,
          name: worldBook.name,
          isSelected: selectedIds.contains(worldBook.id),
          highlightColor: highlightColor,
        ),
    ],
    inputTapRegionGroupId: inputTapRegionGroupId,
    onToggle: onToggle,
    onEdit: onEdit,
  );
}

/// 显示正则规则组选择菜单。切换选中状态后回调 [onToggle]，编辑图标回调 [onEdit]。
Future<void> showRegexRuleGroupMenu({
  required BuildContext context,
  required List<RegexRuleGroupSummary> groups,
  required Set<String> selectedIds,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onToggle,
  required ValueChanged<String> onEdit,
}) async {
  final highlightColor =
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  await _showItemsMenu(
    context: context,
    entries: [
      for (final group in groups)
        _MenuEntry(
          id: group.id,
          name: group.name,
          isSelected: selectedIds.contains(group.id),
          highlightColor: highlightColor,
        ),
    ],
    inputTapRegionGroupId: inputTapRegionGroupId,
    onToggle: onToggle,
    onEdit: onEdit,
  );
}

/// 显示预设选择菜单。选中后回调 [onSelected]，编辑图标回调 [onEdit]。
Future<void> showPresetMenu({
  required BuildContext context,
  required List<PresetSummary> presets,
  required String? selectedId,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onSelected,
  required ValueChanged<String> onEdit,
}) async {
  final highlightColor =
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  await _showItemsMenu(
    context: context,
    entries: [
      for (final preset in presets)
        _MenuEntry(
          id: preset.id,
          name: preset.name,
          isSelected: preset.id == selectedId,
          highlightColor: highlightColor,
          canEdit: !preset.isBuiltin,
        ),
    ],
    inputTapRegionGroupId: inputTapRegionGroupId,
    onSelected: onSelected,
    onEdit: onEdit,
  );
}

/// 用户设定菜单项行首的头像（显示名字首字）。
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
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 菜单项尾部的编辑按钮，[onTap] 为 null 时显示为禁用样式。
class _MenuEditButton extends StatelessWidget {
  const _MenuEditButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.edit_outlined,
          size: 18,
          color: onTap == null ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _TapRegionWrap extends StatelessWidget {
  const _TapRegionWrap({required this.groupId, required this.child});

  final Object groupId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(groupId: groupId, child: child);
  }
}
