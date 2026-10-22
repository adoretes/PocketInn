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

final Finder _panel = find.byKey(const Key('role-filter-panel'));

Widget _harness({
  required List<ChatSidebarRole> roles,
  required Set<String> selectedIds,
  required void Function(Set<String>) onSelectionChanged,
}) {
  // 闭包模拟 service 侧的集合：面板每次切换都会回写，重开时再读回。
  var current = Set<String>.of(selectedIds);
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
                await showRoleFilterMenu(
                  anchorContext: context,
                  roles: roles,
                  selectedIds: current,
                  onSelectionChanged: (ids) {
                    current = Set<String>.of(ids);
                    onSelectionChanged(ids);
                  },
                );
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

Future<void> _tapItem(WidgetTester tester, String name) async {
  await tester.tap(find.descendant(of: _panel, matching: find.text(name)));
  await tester.pumpAndSettle();
}

Future<void> _longPressItem(WidgetTester tester, String name) async {
  await tester.longPress(
    find.descendant(of: _panel, matching: find.text(name)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('渲染角色条目与头像', (tester) async {
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const <String>{},
        onSelectionChanged: (_) {},
      ),
    );
    await _openMenu(tester);

    expect(_panel, findsOneWidget);
    expect(
      find.descendant(of: _panel, matching: find.text('全部角色')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _panel, matching: find.text('角色1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _panel, matching: find.byType(RoleAvatar)),
      findsNWidgets(3),
    );
    // 选中态只用底色区分，不再出现勾图标。
    expect(
      find.descendant(of: _panel, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );
  });

  testWidgets('点击角色是单选：立即回写并关闭面板', (tester) async {
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const {'c1'},
        onSelectionChanged: selections.add,
      ),
    );
    await _openMenu(tester);

    await _tapItem(tester, '角色2');

    expect(selections.single, {'c2'});
    expect(_panel, findsNothing);
  });

  testWidgets('点击已选中角色即取消，不需要长按', (tester) async {
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const {'c1', 'c2'},
        onSelectionChanged: selections.add,
      ),
    );
    await _openMenu(tester);

    await _tapItem(tester, '角色1');

    expect(selections.single, {'c2'});
    expect(_panel, findsOneWidget);
  });

  testWidgets('长按角色多选累积，重复长按取消选中且面板不关闭', (tester) async {
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const <String>{},
        onSelectionChanged: selections.add,
      ),
    );
    await _openMenu(tester);

    await _longPressItem(tester, '角色1');
    await _longPressItem(tester, '角色2');
    await _longPressItem(tester, '角色1');

    expect(selections, [
      {'c1'},
      {'c1', 'c2'},
      {'c2'},
    ]);
    expect(_panel, findsOneWidget);
  });

  testWidgets('点击全部角色清空筛选并关闭面板', (tester) async {
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const {'c1', 'c2'},
        onSelectionChanged: selections.add,
      ),
    );
    await _openMenu(tester);

    await _tapItem(tester, '全部角色');

    expect(selections.single, isEmpty);
    expect(_panel, findsNothing);
  });

  testWidgets('长按全部角色清空筛选但保持面板打开', (tester) async {
    final selections = <Set<String>>[];
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const {'c1'},
        onSelectionChanged: selections.add,
      ),
    );
    await _openMenu(tester);

    await _longPressItem(tester, '全部角色');

    expect(selections.single, isEmpty);
    expect(_panel, findsOneWidget);
  });

  testWidgets('点击面板外关闭且不改动选中', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      _harness(
        roles: _roles(),
        selectedIds: const {'c1'},
        onSelectionChanged: (_) => changes++,
      ),
    );
    await _openMenu(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(changes, 0);
    expect(_panel, findsNothing);
  });

  testWidgets('角色较多时面板限高，“全部角色”固定在顶部不随滚动', (tester) async {
    await tester.pumpWidget(
      _harness(
        roles: _roles(20),
        selectedIds: const {'c19'},
        onSelectionChanged: (_) {},
      ),
    );
    await _openMenu(tester);

    expect(tester.getSize(_panel).height, lessThanOrEqualTo(420));

    final allRoleFinder = find.descendant(
      of: _panel,
      matching: find.text('全部角色'),
    );
    final allRoleTop = tester.getTopLeft(allRoleFinder).dy;
    // “全部角色”应是面板内的第一项。
    expect(allRoleTop, lessThan(tester.getTopLeft(_panel).dy + 20));
    // 打开时自动滚动到选中项，其他条目被滚到下面。
    final selectedTop = tester
        .getTopLeft(find.descendant(of: _panel, matching: find.text('角色19')))
        .dy;
    expect(selectedTop, greaterThan(allRoleTop));

    // 向下拖回列表顶部：其他条目会滚动，但“全部角色”位置不动。
    await tester.drag(
      find.descendant(of: _panel, matching: find.text('角色19')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(allRoleFinder).dy, allRoleTop);
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
        selectedIds: const {'c1'},
        onSelectionChanged: (_) {},
      ),
    );
    await _openMenu(tester);

    final panelRect = tester.getRect(_panel);
    expect(panelRect.left, greaterThanOrEqualTo(12));
    expect(panelRect.right, lessThanOrEqualTo(320 - 12));
    expect(tester.getSize(_panel).height, lessThanOrEqualTo(420));
    // 长名称单行省略，不应产生布局溢出。
    expect(tester.takeException(), isNull);
  });
}
