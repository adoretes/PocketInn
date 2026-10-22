import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/chat_sidebar_service.dart';
import '../../../widgets/role_avatar.dart';

const double _panelRadius = 20;
const double _itemRadius = 14;
const double _menuGap = 8;
const double _screenMargin = 12;
const double _menuMaxHeight = 420;
const double _menuMinHeight = 120;

/// 在 [anchorContext] 对应控件上方弹出角色筛选面板。
///
/// 视觉与设置页的「颜色模式 / 预设主题」卡片保持一致：
/// `surfaceContainerLow` 底色 + 20 圆角 + `outlineVariant` 细描边。
///
/// 面板支持多选：点击条目只切换选中状态并通过 [onSelectionChanged] 立即回写，
/// 不关闭面板；点面板外关闭。「全部角色」用于一键清空筛选。
Future<void> showRoleFilterMenu({
  required BuildContext anchorContext,
  required List<ChatSidebarRole> roles,
  required Set<String> selectedIds,
  required ValueChanged<Set<String>> onSelectionChanged,
}) {
  if (roles.isEmpty) {
    return Future<void>.value();
  }

  final anchorBox = anchorContext.findRenderObject() as RenderBox?;
  final overlayState = Overlay.of(anchorContext, rootOverlay: true);
  final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
  if (anchorBox == null ||
      overlayBox == null ||
      !anchorBox.hasSize ||
      !overlayBox.hasSize) {
    return Future<void>.value();
  }

  // 以根 Overlay 为坐标系，与 useRootNavigator 的浮层保持一致。
  final anchorRect = Rect.fromPoints(
    anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox),
    anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    ),
  );
  final overlaySize = overlayBox.size;

  final width = math.min(
    math.max(anchorRect.width, 180.0),
    math.max(180.0, overlaySize.width - _screenMargin * 2),
  );
  final maxLeft = math.max(
    _screenMargin,
    overlaySize.width - width - _screenMargin,
  );
  final left = anchorRect.left.clamp(_screenMargin, maxLeft).toDouble();

  // 面板贴着触发卡片上沿往上展开，空间不足时收缩并内部滚动。
  final available = math.max(
    0.0,
    anchorRect.top - _menuGap - _screenMargin,
  );
  final height = math.min(_menuMaxHeight, math.max(_menuMinHeight, available));
  final top = math.max(_screenMargin, anchorRect.top - _menuGap - height);

  return showGeneralDialog<void>(
    context: anchorContext,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: '关闭角色筛选',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: width,
            child: _RoleFilterPanel(
              roles: roles,
              selectedIds: selectedIds,
              onSelectionChanged: onSelectionChanged,
              maxHeight: height,
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final opacity = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      final scale = animation.drive(
        Tween<double>(begin: 0.94, end: 1).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      );
      return FadeTransition(
        opacity: opacity,
        child: ScaleTransition(
          scale: scale,
          alignment: Alignment.bottomLeft,
          child: child,
        ),
      );
    },
  );
}

class _RoleFilterPanel extends StatefulWidget {
  const _RoleFilterPanel({
    required this.roles,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.maxHeight,
  });

  final List<ChatSidebarRole> roles;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final double maxHeight;

  @override
  State<_RoleFilterPanel> createState() => _RoleFilterPanelState();
}

class _RoleFilterPanelState extends State<_RoleFilterPanel> {
  final GlobalKey _initialFocusKey = GlobalKey();

  /// 面板内的选中集合，只服务本层即时渲染；真源始终是 service 里的集合。
  late Set<String> _selectedIds = Set<String>.of(widget.selectedIds);

  @override
  void initState() {
    super.initState();
    // 角色较多时把首个选中项滚到面板中部，避免默认停在顶部。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _initialFocusKey.currentContext;
      if (targetContext == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// 点击未选中的角色是单选：直接替换选中项并关闭面板，保持“选完就走”的习惯；
  /// 点击已选中的角色只把它取消掉（面板不关），取消不该比选中更费力。
  void _handleTap(ChatSidebarRole role) {
    final id = role.id;
    if (id != null && _selectedIds.contains(id)) {
      _applySelection(Set<String>.of(_selectedIds)..remove(id));
      return;
    }
    _applySelection(id == null ? const <String>{} : <String>{id});
    Navigator.of(context).pop();
  }

  /// 长按是多选：切换该项的选中状态并保持面板打开，方便连续勾选多个角色。
  void _handleLongPress(ChatSidebarRole role) {
    final id = role.id;
    final next = Set<String>.of(_selectedIds);
    if (id == null) {
      next.clear();
    } else if (!next.remove(id)) {
      next.add(id);
    }
    _applySelection(next);
  }

  void _applySelection(Set<String> next) {
    // 集合没变就不麻烦 service，避免整页无意义重建。
    if (next.length == _selectedIds.length && next.containsAll(_selectedIds)) {
      return;
    }
    setState(() {
      _selectedIds = next;
    });
    widget.onSelectionChanged(Set<String>.unmodifiable(next));
  }

  bool _isSelected(ChatSidebarRole role) {
    final id = role.id;
    // 空集等价于“全部角色”，此时高亮首项表达“当前未筛选”。
    return id == null ? _selectedIds.isEmpty : _selectedIds.contains(id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 首项固定为“全部角色”，钉在面板顶部，不随下方列表滚动。
    final allRole = widget.roles.first;
    final scrollRoles = widget.roles.skip(1).toList();
    final focusIndex = scrollRoles.indexWhere(
      (role) => _selectedIds.contains(role.id),
    );

    return Material(
      key: const Key('role-filter-panel'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(_panelRadius),
      clipBehavior: Clip.antiAlias,
      // 用 DecoratedBox 画描边，避免 Border 额外撑高（容器要严格贴合限高）。
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_panelRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight - 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoleFilterItem(
                  role: allRole,
                  selected: _isSelected(allRole),
                  onTap: () => _handleTap(allRole),
                  onLongPress: () => _handleLongPress(allRole),
                ),
                if (scrollRoles.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var index = 0;
                            index < scrollRoles.length;
                            index++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: index == scrollRoles.length - 1
                                    ? 0
                                    : 2,
                              ),
                              child: _RoleFilterItem(
                                key: index == focusIndex
                                    ? _initialFocusKey
                                    : null,
                                role: scrollRoles[index],
                                selected: _isSelected(scrollRoles[index]),
                                onTap: () => _handleTap(scrollRoles[index]),
                                onLongPress: () =>
                                    _handleLongPress(scrollRoles[index]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleFilterItem extends StatelessWidget {
  const _RoleFilterItem({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatSidebarRole role;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(_itemRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(_itemRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              RoleAvatar(
                fallbackText: role.avatarText,
                radius: 14,
                imagePath: role.imagePath,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
