import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/world_book.dart';
import 'package:pocket_inn/pages/world_book_edit_page.dart';

void main() {
  for (final duplicateId in ['', 'entry-1']) {
    testWidgets('重复 ID（$duplicateId）的同名条目可以独立切换开关', (tester) async {
      await _pumpDuplicateEntries(tester, duplicateId);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<Switch>(find.byType(Switch))
            .map((item) => item.value),
        [false, true],
      );
      expect(find.text('第一条内容'), findsOneWidget);
      expect(find.text('第二条内容'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('重复 ID 的同名条目可以独立编辑', (tester) async {
    await _pumpDuplicateEntries(tester, 'entry-1');

    await tester.tap(find.text('第一条内容'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '备注'), '只修改第一条');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('只修改第一条'), findsOneWidget);
    expect(find.text('同名条目'), findsOneWidget);
    expect(find.text('第一条内容'), findsOneWidget);
    expect(find.text('第二条内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('删除重复 ID 的条目不会删除另一条', (tester) async {
    await _pumpDuplicateEntries(tester, 'entry-1');

    await tester.tap(find.byTooltip('删除').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.text('第一条内容'), findsNothing);
    expect(find.text('第二条内容'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('条目从非常驻切换为常驻不会抛异常', (tester) async {
    final book = WorldBook(
      id: 'wb-1',
      name: '测试世界书',
      description: '',
      colorValue: 0xFF000000,
      entries: [
        WorldBookEntry(
          id: 'entry-1',
          key: const ['龙'],
          content: '龙的设定',
          comment: '龙',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: WorldBookEditPage(worldBook: book)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('新建'));
    await tester.pumpAndSettle();
    expect(find.text('编辑条目'), findsOneWidget);

    final constantTile = find.text('常驻激活');
    await tester.ensureVisible(constantTile);
    await tester.pumpAndSettle();
    await tester.tap(constantTile);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('已有条目切换常驻并保存不会抛异常', (tester) async {
    final book = WorldBook(
      id: 'wb-1',
      name: '测试世界书',
      description: '',
      colorValue: 0xFF000000,
      entries: [
        WorldBookEntry(
          id: 'entry-1',
          key: const ['龙'],
          content: '龙的设定',
          comment: '龙',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: WorldBookEditPage(worldBook: book)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('龙'));
    await tester.pumpAndSettle();
    expect(find.text('编辑条目'), findsOneWidget);

    final constantTile = find.text('常驻激活');
    await tester.ensureVisible(constantTile);
    await tester.pumpAndSettle();
    await tester.tap(constantTile);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 再打开一次并切回非常驻
    await tester.tap(find.text('龙'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(constantTile);
    await tester.pumpAndSettle();
    await tester.tap(constantTile);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('空条目时显示占位提示', (tester) async {
    final book = WorldBook(
      id: 'wb-empty',
      name: '空世界书',
      description: '',
      colorValue: 0xFF2E7D6B,
      entries: const [],
    );
    await _pumpBook(tester, book);

    expect(find.text('暂无条目'), findsOneWidget);
    expect(find.text('点击右上角「新建」添加第一条条目'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('窄屏浏览条目列表无布局溢出', (tester) async {
    final book = WorldBook(
      id: 'wb-narrow',
      name: '窄屏世界书',
      description: '简短描述',
      colorValue: 0xFF2E7D6B,
      entries: [
        for (var i = 0; i < 8; i++)
          WorldBookEntry(
            id: 'e$i',
            key: ['关键词$i'],
            content: '第 $i 条条目的内容，用于测试窄屏下的换行与溢出表现。',
            comment: '条目 $i',
          ),
      ],
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: WorldBookEditPage(worldBook: book)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      await tester.drag(scrollable, const Offset(0, -260));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _pumpBook(WidgetTester tester, WorldBook book) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: WorldBookEditPage(worldBook: book)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDuplicateEntries(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final book = WorldBook(
    id: 'wb-duplicates',
    name: '同名条目测试',
    description: '',
    colorValue: 0xFF4B6CB7,
    entries: [
      WorldBookEntry(id: id, content: '第一条内容', comment: '同名条目', constant: true),
      WorldBookEntry(id: id, content: '第二条内容', comment: '同名条目', constant: true),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(home: WorldBookEditPage(worldBook: book)),
  );
  await tester.pumpAndSettle();
}
