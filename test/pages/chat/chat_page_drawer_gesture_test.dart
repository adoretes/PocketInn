import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 聊天页两个抽屉的滑动手势契约。
///
/// [ChatPage] 的左抽屉（聊天列表）与右抽屉（记忆与状态）共用
/// `Scaffold.drawerEdgeDragWidth`，两侧拖拽区必须对称且互不重叠，
/// 否则从屏幕一侧滑动会打开另一侧的抽屉。这里用与 ChatPage 完全
/// 相同的参数复刻 Scaffold 配置（整页 ChatPage 需要整套服务与数据库，
/// 不适合放进 widget 测试）。
void main() {
  /// 与 ChatPage.build 中一致：45% 宽，各自不超过 320。
  double edgeDragWidth(double screenWidth) {
    return (screenWidth * 0.45).clamp(128.0, 320.0);
  }

  Future<void> pumpReplica(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawerEnableOpenDragGesture: true,
          endDrawerEnableOpenDragGesture: true,
          drawerEdgeDragWidth: edgeDragWidth(width),
          drawer: const Drawer(child: Center(child: Text('左侧聊天列表'))),
          endDrawer: const Drawer(child: Center(child: Text('右侧记忆与状态'))),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('右缘向左滑打开右侧抽屉，且不会误开左抽屉', (tester) async {
    await pumpReplica(tester, 360);

    // 起点落在右缘拖拽区（360 - 162 = 198 之后），向左拖过半屏宽。
    await tester.dragFrom(const Offset(350, 320), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('右侧记忆与状态'), findsOneWidget);
    expect(find.text('左侧聊天列表'), findsNothing);
  });

  testWidgets('左缘向右滑仍打开左抽屉', (tester) async {
    await pumpReplica(tester, 360);

    await tester.dragFrom(const Offset(10, 320), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('左侧聊天列表'), findsOneWidget);
    expect(find.text('右侧记忆与状态'), findsNothing);
  });

  testWidgets('常见手机宽度下两侧拖拽区不重叠', (tester) async {
    for (final width in [320.0, 360.0, 393.0, 412.0, 480.0, 800.0]) {
      expect(
        edgeDragWidth(width) * 2,
        lessThanOrEqualTo(width),
        reason: '$width 逻辑像素宽时左右拖拽区不应重叠',
      );
    }
  });
}
