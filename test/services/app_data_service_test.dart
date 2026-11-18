import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/services/api_config_service.dart';
import 'package:pocket_inn/services/app_data_service.dart';
import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_sidebar_service.dart';
import 'package:pocket_inn/services/preset_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // reloadAppState 会读取 API 配置；测试里不接安全存储，读操作返回空即可。
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late Directory tempDir;
  final db = ChatDatabaseService.instance;
  final sidebar = ChatSidebarService.instance;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secureStorageChannel,
          (call) async => null,
        );
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await CharacterService.instance.initialize();
    await PresetService.instance.initialize();
    await ApiConfigService.instance.initialize();
    await db.initialize();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await db.clearAllData();
    sidebar.setSelectedRoleIds(const <String>{});
  });

  test('reloadAppState 广播会话与记忆变更，使聊天列表缓存失效', () async {
    await db.createSession(characterId: 'char-1', title: '旧会话');
    await sidebar.refresh();
    final before = sidebar.dataNotifier.value;
    expect(before, isNotNull);
    expect(before!.chats, hasLength(1));

    var chatNotifications = 0;
    var memoryNotifications = 0;
    void onChatChanged() => chatNotifications++;
    void onMemoryChanged() => memoryNotifications++;
    db.changeNotifier.addListener(onChatChanged);
    db.memoryChangeNotifier.addListener(onMemoryChanged);
    addTearDown(() {
      db.changeNotifier.removeListener(onChatChanged);
      db.memoryChangeNotifier.removeListener(onMemoryChanged);
    });

    // 模拟恢复备份后走的重载路径：磁盘数据已被替换，需要重新加载内存状态。
    await AppDataService.instance.reloadAppState();

    expect(
      chatNotifications,
      greaterThan(0),
      reason: '整体重载后必须广播会话数据变更，否则聊天列表会一直复用旧快照',
    );
    expect(
      memoryNotifications,
      greaterThan(0),
      reason: '记忆求值缓存以 memoryChangeNotifier 为版本号，重载后必须自增',
    );

    await sidebar.ensureFresh();
    expect(
      identical(sidebar.dataNotifier.value, before),
      isFalse,
      reason: '数据重载后重新打开抽屉应重新读取，而不是复用重载前的快照',
    );
  });
}
