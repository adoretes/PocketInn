import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/pages/chat_sidebar_page.dart';
import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_sidebar_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';

import '../../helpers/test_env.dart';

final Finder _panel = find.byKey(const Key('role-filter-panel'));

Widget _app() {
  return const MaterialApp(home: Scaffold(body: ChatSidebarPage()));
}

String? _triggerLabel(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const Key('role-filter-trigger-label')))
      .data;
}

Map<String, dynamic> _buildCard(String name) {
  final card = CharacterService.instance.buildEmptyCard();
  final data = Map<String, dynamic>.from(card['data'] as Map);
  data['name'] = name;
  return {...card, 'data': data};
}

/// 页面里的加载指示是无限动画，`pumpAndSettle` 会一直等下去；
/// 改用固定次数 pump 推进弹层动画与布局。
Future<void> _settle(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('role-filter-trigger-label')));
  await _settle(tester);
}

Future<void> _longPressRole(WidgetTester tester, String name) async {
  await tester.longPress(
    find.descendant(of: _panel, matching: find.text(name)),
  );
  await _settle(tester);
}

Future<void> _closePanel(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final service = ChatSidebarService.instance;
  final db = ChatDatabaseService.instance;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await WorldBookService.instance.initialize();
    await CharacterService.instance.initialize();
    await db.initialize();
  });

  tearDownAll(() async {
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await db.close();
    await WorldBookService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await db.clearAllData();
    service.setSelectedRoleIds(const <String>{});
    await service.refresh();
  });

  testWidgets('只把有会话的角色放进筛选项', (tester) async {
    // widget 测试跑在 fake async 里，真实文件/数据库 I/O 需要 runAsync 才能完成。
    await tester.runAsync(() async {
      final chatting = await CharacterService.instance.createFromCard(
        cardJson: _buildCard('有会话'),
      );
      await CharacterService.instance.createFromCard(
        cardJson: _buildCard('没会话'),
      );
      await db.createSession(characterId: chatting.id, title: '一次聊天');
      await service.refresh();
    });

    await tester.pumpWidget(_app());
    await _settle(tester);
    expect(
      service.dataNotifier.value,
      isNotNull,
      reason: '快照应已就绪，否则页面只会显示加载指示',
    );
    await _openPanel(tester);

    expect(find.descendant(of: _panel, matching: find.text('有会话')), findsOneWidget);
    expect(find.descendant(of: _panel, matching: find.text('没会话')), findsNothing);
  });

  testWidgets('多选角色取并集，抽屉重建后筛选仍保留', (tester) async {
    await tester.runAsync(() async {
      final alice = await CharacterService.instance.createFromCard(
        cardJson: _buildCard('Alice'),
      );
      final bob = await CharacterService.instance.createFromCard(
        cardJson: _buildCard('Bob'),
      );
      await db.createSession(characterId: alice.id, title: 'Alice 的会话');
      await db.createSession(characterId: bob.id, title: 'Bob 的会话');
      await service.refresh();
    });

    await tester.pumpWidget(_app());
    await _settle(tester);

    // 长按多选两个角色：列表取并集，卡片概括数量。
    await _openPanel(tester);
    await _longPressRole(tester, 'Alice');
    await _longPressRole(tester, 'Bob');
    await _closePanel(tester);

    expect(_triggerLabel(tester), '已选 2 个角色');
    expect(find.text('Alice 的会话'), findsOneWidget);
    expect(find.text('Bob 的会话'), findsOneWidget);

    // 长按取消 Bob：只剩 Alice 的会话。
    await _openPanel(tester);
    await _longPressRole(tester, 'Bob');
    await _closePanel(tester);

    expect(_triggerLabel(tester), 'Alice');
    expect(find.text('Alice 的会话'), findsOneWidget);
    expect(find.text('Bob 的会话'), findsNothing);

    // 模拟抽屉关闭：整棵子树移出后重新挂载，ChatSidebarPage 的 State 会重建。
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(_triggerLabel(tester), 'Alice');
    expect(find.text('Alice 的会话'), findsOneWidget);
    expect(find.text('Bob 的会话'), findsNothing);
  });
}
