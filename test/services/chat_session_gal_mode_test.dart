import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/services/chat_database_service.dart';

import '../helpers/legacy_db.dart';
import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    await ChatDatabaseService.instance.initialize();
  });

  tearDownAll(() async {
    await ChatDatabaseService.instance.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await ChatDatabaseService.instance.clearAllData();
  });

  test('gal 状态按会话保存，切换会话互不影响', () async {
    final db = ChatDatabaseService.instance;
    final sessionA = await db.createSession(characterId: 'char-1', title: 'A');
    final sessionB = await db.createSession(characterId: 'char-1', title: 'B');

    await db.updateSessionConfig(
      sessionId: sessionA.id,
      selectedUserSettingId: null,
      selectedWorldBookIds: const [],
      selectedRegexRuleGroupIds: const [],
      selectedPresetId: null,
      galModeEnabled: true,
    );

    final bundleA = await db.loadSessionBundle(sessionA.id);
    final bundleB = await db.loadSessionBundle(sessionB.id);

    expect(
      bundleA?.session.galModeEnabled,
      isTrue,
      reason: '开启过 gal 模式的会话应保存状态',
    );
    expect(bundleB?.session.galModeEnabled, isFalse, reason: '未开启的会话保持关闭');
  });

  test('创建会话时可携带 gal 状态，默认关闭', () async {
    final db = ChatDatabaseService.instance;
    final defaultSession = await db.createSession(
      characterId: 'char-1',
      title: '默认',
    );
    final galSession = await db.createSession(
      characterId: 'char-1',
      title: 'gal',
      galModeEnabled: true,
    );

    final defaultBundle = await db.loadSessionBundle(defaultSession.id);
    final galBundle = await db.loadSessionBundle(galSession.id);

    expect(defaultBundle?.session.galModeEnabled, isFalse);
    expect(galBundle?.session.galModeEnabled, isTrue);
  });

  test('v4 旧库升级 v5 后 gal_mode_enabled 兜底为关闭', () async {
    final service = ChatDatabaseService.instance;
    await service.deleteDatabaseFiles();

    // 直接以 v4 schema（chat_sessions 无 gal_mode_enabled 列）建库，
    // 写入一条旧版本会话，模拟升级前遗留的数据库文件。
    await createLegacyDatabase(version: 4);

    // 服务初始化触发 v4 -> v5 迁移，旧行由列默认值兜底为关闭。
    await service.initialize();
    final bundle = await service.loadSessionBundle('legacy-1');
    expect(bundle, isNotNull, reason: '旧会话升级后仍可加载');
    expect(bundle!.session.galModeEnabled, isFalse);
  });
}
