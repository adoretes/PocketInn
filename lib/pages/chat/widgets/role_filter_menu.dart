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
/// 选中条目通过 `Navigator.pop` 返回，取消则返回 null。
Future<ChatSidebarRole?> showRoleFilterMenu({
  required BuildContext anchorContext,
  required List<ChatSidebarRole> roles,
  required String? selectedId,
}) {
  if (roles.isEmpty) {
    return Future<ChatSidebarRole?>.value();
  }

  final anchorBox = anchorContext.findRenderObject() as RenderBox?;
  final overlayState = Overlay.of(anchorContext, rootOverlay: true);
  final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
  if (anchorBox == null ||
      overlayBox == null ||
      !anchorBox.hasSize ||
      !overlayBox.hasSize) {
    return Future<ChatSidebarRole?>.value();
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

  return showGeneralDialog<ChatSidebarRole>(
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
              selectedId: selectedId,
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
    required this.selectedId,
    required this.maxHeight,
  });

  final List<ChatSidebarRole> roles;
  final String? selectedId;
  final double maxHeight;

  @override
  State<_RoleFilterPanel> createState() => _RoleFilterPanelState();
}

class _RoleFilterPanelState extends State<_RoleFilterPanel> {
  final GlobalKey _initialFocusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 角色较多时把当前选中项滚到面板中部，避免默认停在顶部。
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = widget.roles.indexWhere(
      (role) => role.id == widget.selectedId,
    );
    final focusIndex = selectedIndex < 0 ? 0 : selectedIndex;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < widget.roles.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.roles.length - 1 ? 0 : 2,
                      ),
                      child: _RoleFilterItem(
                        key: index == focusIndex ? _initialFocusKey : null,
                        role: widget.roles[index],
                        selected: index == selectedIndex,
                        onTap: () =>
                            Navigator.of(context).pop(widget.roles[index]),
                      ),
                    ),
                ],
              ),
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
  });

  final ChatSidebarRole role;
  final bool selected;
  final VoidCallback onTap;

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
