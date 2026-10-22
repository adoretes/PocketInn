import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_sidebar_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';

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
    await WorldBookService.instance.initialize();
    await CharacterService.instance.initialize();
    await db.initialize();
  });

  tearDownAll(() async {
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await WorldBookService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await db.clearAllData();
    service.setSelectedRoleIds(const <String>{});
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

  test('筛选项只包含确实有会话的角色', () async {
    final chatting = await CharacterService.instance.createFromCard(
      cardJson: _buildCard('有会话'),
    );
    await CharacterService.instance.createFromCard(
      cardJson: _buildCard('没会话'),
    );
    await db.createSession(characterId: chatting.id, title: '会话 A');

    await service.refresh();

    final data = service.dataNotifier.value!;
    expect(data.roles.first.id, isNull, reason: '首项固定为“全部角色”');
    expect(data.roles.map((role) => role.name), contains('有会话'));
    expect(
      data.roles.map((role) => role.name),
      isNot(contains('没会话')),
      reason: '从未聊过天的角色卡不应出现在筛选项里',
    );
  });

  test('选中集合跨刷新保留，角色失去会话后被剪枝', () async {
    final chatty = await CharacterService.instance.createFromCard(
      cardJson: _buildCard('有会话'),
    );
    final session = await db.createSession(
      characterId: chatty.id,
      title: '会话 A',
    );
    await service.refresh();

    service.setSelectedRoleIds({chatty.id});
    // 模拟抽屉关闭后重新打开：快照与选中集合都应复用。
    await service.ensureFresh();
    expect(service.selectedRoleIdsNotifier.value, {chatty.id});

    await db.deleteSession(session.id);
    await service.refresh();
    expect(
      service.selectedRoleIdsNotifier.value,
      isEmpty,
      reason: '角色已无会话，残留的选中 id 会让触发卡片显示筛不出内容的角色',
    );
  });

  test('选中集合内容不变时不广播', () {
    var notified = 0;
    void listener() => notified++;
    service.selectedRoleIdsNotifier.addListener(listener);
    addTearDown(() => service.selectedRoleIdsNotifier.removeListener(listener));

    service.setSelectedRoleIds({'a', 'b'});
    expect(notified, 1);

    service.setSelectedRoleIds({'b', 'a'});
    expect(notified, 1, reason: '顺序不同但内容相同，不应触发整页重建');

    service.setSelectedRoleIds(const <String>{});
    expect(notified, 2);
  });
}

Map<String, dynamic> _buildCard(String name) {
  final card = CharacterService.instance.buildEmptyCard();
  final data = Map<String, dynamic>.from(card['data'] as Map);
  data['name'] = name;
  return {...card, 'data': data};
}
