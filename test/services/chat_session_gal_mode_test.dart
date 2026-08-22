import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pocket_inn/services/chat_database_service.dart';

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
    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'pocket_inn_data', 'pocket_inn_chat.db');
    Directory(p.dirname(dbPath)).createSync(recursive: true);
    final raw = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE chat_sessions (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              character_id TEXT NOT NULL,
              selected_user_setting_id TEXT,
              selected_preset_id TEXT,
              current_leaf_message_id TEXT,
              last_message_preview TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_session_world_books (
              session_id TEXT NOT NULL,
              world_book_id TEXT NOT NULL,
              PRIMARY KEY (session_id, world_book_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_session_regex_rule_groups (
              session_id TEXT NOT NULL,
              regex_rule_group_id TEXT NOT NULL,
              PRIMARY KEY (session_id, regex_rule_group_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_messages (
              id TEXT PRIMARY KEY,
              session_id TEXT NOT NULL,
              parent_id TEXT,
              role TEXT NOT NULL,
              text TEXT NOT NULL,
              thinking_chain TEXT,
              created_at TEXT NOT NULL,
              sibling_order INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_branch_state (
              parent_message_id TEXT PRIMARY KEY,
              active_child_message_id TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE chat_memories (
              id TEXT PRIMARY KEY,
              session_id TEXT NOT NULL,
              branch_leaf_id TEXT NOT NULL,
              content TEXT NOT NULL,
              source_message_ids TEXT NOT NULL DEFAULT '[]',
              is_user_edited INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await raw.insert('chat_sessions', {
      'id': 'legacy-1',
      'title': '旧会话',
      'character_id': 'char-1',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    });
    await raw.close();

    // 服务初始化触发 v4 -> v5 迁移，旧行由列默认值兜底为关闭。
    await service.initialize();
    final bundle = await service.loadSessionBundle('legacy-1');
    expect(bundle, isNotNull, reason: '旧会话升级后仍可加载');
    expect(bundle!.session.galModeEnabled, isFalse);
  });
}
