import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_sidebar_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final service = ChatSidebarService.instance;
  final db = ChatDatabaseService.instance;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await CharacterService.instance.initialize();
    await db.initialize();
  });

  tearDownAll(() async {
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await db.clearAllData();
  });

  test('数据源未变时复用缓存快照（抽屉每次打开不再重新加载）', () async {
    await db.createSession(characterId: 'char-1', title: '会话 A');
    await db.createSession(characterId: 'char-1', title: '会话 B');

    await service.refresh();
    final first = service.dataNotifier.value;
    expect(first, isNotNull);
    expect(first!.chats, hasLength(2));

    // 模拟“抽屉关闭后再次打开”：命中未过期快照即复用同一实例。
    await service.ensureFresh();
    expect(
      identical(service.dataNotifier.value, first),
      isTrue,
      reason: '数据源未变化时应复用缓存快照，避免每次打开抽屉都重新加载',
    );
  });

  test('数据源变化后再次打开会刷新快照', () async {
    await db.createSession(characterId: 'char-1', title: '会话 A');
    await service.refresh();
    final before = service.dataNotifier.value;
    expect(before!.chats, hasLength(1));

    await db.createSession(characterId: 'char-1', title: '会话 B');
    await service.ensureFresh();
    final after = service.dataNotifier.value;
    expect(identical(after, before), isFalse, reason: '数据变化后应重新加载');
    expect(after!.chats, hasLength(2));
  });
}
