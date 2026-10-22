import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/pages/chat/widgets/role_filter_menu.dart';
import 'package:pocket_inn/services/chat_sidebar_service.dart';
import 'package:pocket_inn/widgets/role_avatar.dart';

ChatSidebarRole _role(String? id, String name) {
  return ChatSidebarRole(
    id: id,
    name: name,
    avatarText: name.isEmpty ? '?' : name.substring(0, 1),
    isRealCharacter: id != null,
  );
}

List<ChatSidebarRole> _roles([int count = 3]) {
  return [
    const ChatSidebarRole(id: null, name: '全部角色', avatarText: '全'),
    for (var index = 1; index < count; index++)
      _role('c$index', '角色$index'),
  ];
}

Widget _harness({
  required List<ChatSidebarRole> roles,
  required String? selectedId,
  required void Function(ChatSidebarRole?) onResult,
}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE76F51)),
    ),
    home: Scaffold(
      body: Column(
        children: [
          const Spacer(),
          Builder(
            builder: (context) => TextButton(
              key: const Key('role-filter-anchor'),
              onPressed: () async {
                final result = await showRoleFilterMenu(
                  anchorContext: context,
                  roles: roles,
                  selectedId: selectedId,
                );
                onResult(result);
              },
              child: const Text('打开角色筛选'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('role-filter-anchor')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('渲染角色条目与头像', (tester) async {
    await tester.pumpWidget(
      _harness(roles: _roles(), selectedId: null, onResult: (_) {}),
    );
    await _openMenu(tester);

    final panel = find.byKey(const Key('role-filter-panel'));
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('全部角色')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('角色1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.byType(RoleAvatar)),
      findsNWidgets(3),
    );
    // 选中态只用底色区分，不再出现勾图标。
    expect(
      find.descendant(of: panel, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );
  });

  testWidgets('点击条目回传选中角色并关闭面板', (tester) async {
    ChatSidebarRole? result;
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedId: null,
        onResult: (role) => result = role,
      ),
    );
    await _openMenu(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('role-filter-panel')),
        matching: find.text('角色2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(result?.id, 'c2');
    expect(find.byKey(const Key('role-filter-panel')), findsNothing);
  });

  testWidgets('点击面板外关闭且不回传选中项', (tester) async {
    var called = false;
    ChatSidebarRole? result;
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedId: null,
        onResult: (role) {
          called = true;
          result = role;
        },
      ),
    );
    await _openMenu(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
    expect(find.byKey(const Key('role-filter-panel')), findsNothing);
  });

  testWidgets('角色较多时面板限高并可内部滚动', (tester) async {
    await tester.pumpWidget(
      _harness(roles: _roles(20), selectedId: 'c19', onResult: (_) {}),
    );
    await _openMenu(tester);

    final panel = find.byKey(const Key('role-filter-panel'));
    expect(tester.getSize(panel).height, lessThanOrEqualTo(420));

    // 打开时自动滚动到选中项，顶部条目应被滚出面板可见区域。
    final firstItemTop = tester.getTopLeft(
      find.descendant(of: panel, matching: find.text('全部角色')),
    );
    expect(firstItemTop.dy, lessThan(tester.getTopLeft(panel).dy));

    // 反向拖回顶部，确认内部 ScrollView 可滚动。
    await tester.drag(panel, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(
            find.descendant(of: panel, matching: find.text('全部角色')),
          )
          .dy,
      greaterThan(firstItemTop.dy),
    );
  });

  testWidgets('窄屏与超长角色名不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const longName = '这是一个非常非常长的角色名称用来验证省略号截断是否生效';
    await tester.pumpWidget(
      _harness(
        roles: [
          const ChatSidebarRole(id: null, name: '全部角色', avatarText: '全'),
          _role('c1', longName),
        ],
        selectedId: 'c1',
        onResult: (_) {},
      ),
    );
    await _openMenu(tester);

    final panel = find.byKey(const Key('role-filter-panel'));
    final panelRect = tester.getRect(panel);
    expect(panelRect.left, greaterThanOrEqualTo(12));
    expect(panelRect.right, lessThanOrEqualTo(320 - 12));
    expect(tester.getSize(panel).height, lessThanOrEqualTo(420));
    // 长名称单行省略，不应产生布局溢出。
    expect(tester.takeException(), isNull);
  });
}
