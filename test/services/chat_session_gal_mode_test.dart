import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/services/chat_database_service.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pocket_inn_gal_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
          return tempDir.path;
        });

    await ChatDatabaseService.instance.initialize();
  });

  tearDownAll(() async {
    await ChatDatabaseService.instance.deleteDatabaseFiles();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } on FileSystemException {
      // Windows 下文件句柄可能延迟释放，临时目录留给系统清理即可。
    }
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

    expect(bundleA?.session.galModeEnabled, isTrue,
        reason: '开启过 gal 模式的会话应保存状态');
    expect(bundleB?.session.galModeEnabled, isFalse,
        reason: '未开启的会话保持关闭');
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

  test('旧会话（无 gal 列数据）加载时视为关闭', () async {
    final db = ChatDatabaseService.instance;
    final session = await db.createSession(characterId: 'char-1', title: '旧');

    // 模拟旧版本写入的行：gal_mode_enabled 由列默认值兜底为 0。
    final bundle = await db.loadSessionBundle(session.id);
    expect(bundle?.session.galModeEnabled, isFalse);
  });
}
