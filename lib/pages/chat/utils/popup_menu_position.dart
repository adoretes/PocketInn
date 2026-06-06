import 'package:flutter/material.dart';

/// 计算在按钮上方弹出 [showMenu] 时的位置与约束。
class PopupMenuPositioning {
  const PopupMenuPositioning._();

  static const double anchorGap = 8.0;
  static const double screenPadding = 8.0;
  static const double verticalPadding = 16.0;
  static const double minWidth = 112.0;
  static const double maxWidth = 280.0;

  static RelativeRect positionAbove(BuildContext buttonContext, int itemCount) {
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlayRenderObject = Navigator.of(
      buttonContext,
    ).overlay?.context.findRenderObject();
    final overlay = overlayRenderObject is RenderBox
        ? overlayRenderObject
        : null;
    final overlaySize = overlay?.size ?? MediaQuery.sizeOf(buttonContext);
    final buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );
    final menuHeight = _heightAbove(buttonRect, itemCount);
    final top = (buttonRect.top - menuHeight - anchorGap)
        .clamp(screenPadding, double.infinity)
        .toDouble();

    return RelativeRect.fromRect(
      Rect.fromLTWH(buttonRect.left, top, buttonRect.width, buttonRect.height),
      Offset.zero & overlaySize,
    );
  }

  static BoxConstraints constraintsAbove(BuildContext buttonContext) {
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlayRenderObject = Navigator.of(
      buttonContext,
    ).overlay?.context.findRenderObject();
    final overlay = overlayRenderObject is RenderBox
        ? overlayRenderObject
        : null;
    final buttonTop = button.localToGlobal(Offset.zero, ancestor: overlay).dy;
    final maxHeight = (buttonTop - anchorGap - screenPadding)
        .clamp(kMinInteractiveDimension, double.infinity)
        .toDouble();

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static double _heightAbove(Rect buttonRect, int itemCount) {
    final estimatedHeight =
        itemCount * kMinInteractiveDimension + verticalPadding;
    final availableHeight = buttonRect.top - anchorGap - screenPadding;
    final maxHeight = availableHeight < kMinInteractiveDimension
        ? kMinInteractiveDimension
        : availableHeight;
    return estimatedHeight
        .clamp(kMinInteractiveDimension, maxHeight)
        .toDouble();
  }
}
