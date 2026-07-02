import 'package:flutter/material.dart';

import '../../../data/mock_user_settings.dart';
import '../../../models/preset.dart';
import '../../../models/user_setting.dart';
import '../../../models/world_book.dart';
import '../utils/popup_menu_position.dart';

/// 显示用户设定选择菜单。选中后回调 [onSelected]，编辑图标回调 [onEdit]。
Future<void> showUserSettingMenu({
  required BuildContext context,
  required List<UserSetting> settings,
  required String? selectedId,
  required Object inputTapRegionGroupId,
  required ValueChanged<String> onSelected,
  required ValueChanged<String> onEdit,
}) async {
  final value = await showMenu<String>(
    context: context,
    requestFocus: false,
    position: PopupMenuPositioning.positionAbove(context, settings.length),
    constraints: PopupMenuPositioning.constraintsAbove(context),
    items: settings.map((setting) {
      final isSelected = setting.id == selectedId;
      return PopupMenuItem<String>(
        value: setting.id,
        padding: EdgeInsets.zero,
        child: _TapRegionWrap(
          groupId: inputTapRegionGroupId,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(color: setting.color.withValues(alpha: 0.12))
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: setting.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    setting.avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(setting.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(setting.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
  if (value != null) {
    onSelected(value);
  }
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
  final colorScheme = Theme.of(context).colorScheme;
  await showMenu<String>(
    context: context,
    requestFocus: false,
    position: PopupMenuPositioning.positionAbove(context, worldBooks.length),
    constraints: PopupMenuPositioning.constraintsAbove(context),
    items: worldBooks.map((worldBook) {
      final isSelected = selectedIds.contains(worldBook.id);
      return PopupMenuItem<String>(
        value: worldBook.id,
        padding: EdgeInsets.zero,
        onTap: () => onToggle(worldBook.id),
        child: _TapRegionWrap(
          groupId: inputTapRegionGroupId,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(worldBook.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(worldBook.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
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
  final colorScheme = Theme.of(context).colorScheme;
  final value = await showMenu<String>(
    context: context,
    requestFocus: false,
    position: PopupMenuPositioning.positionAbove(context, presets.length),
    constraints: PopupMenuPositioning.constraintsAbove(context),
    items: presets.map((preset) {
      final isSelected = preset.id == selectedId;
      return PopupMenuItem<String>(
        value: preset.id,
        padding: EdgeInsets.zero,
        child: _TapRegionWrap(
          groupId: inputTapRegionGroupId,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(preset.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: preset.isBuiltin
                      ? null
                      : () {
                          Navigator.pop(context);
                          onEdit(preset.id);
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: preset.isBuiltin
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
  if (value != null) {
    onSelected(value);
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
