import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/world_book.dart';
import 'package:pocket_inn/pages/world_book_edit_page.dart';

void main() {
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
}
