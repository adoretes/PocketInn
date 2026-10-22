import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 旧版数据库文件路径（与 [ChatDatabaseService] 使用的位置一致）。
Future<String> legacyDatabasePath() async {
  final appDir = await getApplicationSupportDirectory();
  return p.join(appDir.path, 'pocket_inn_data', 'pocket_inn_chat.db');
}

/// 按历史 schema 建库并写入一条旧会话，供升级迁移测试共用。
///
/// [version] 支持 1~5（6 为当前版本，不属于"旧库"夹具）：
/// - v2 起有 `chat_memories`
/// - v4 起有 `chat_session_regex_rule_groups`
/// - v5 起 `chat_sessions` 有 `gal_mode_enabled`
///
/// 调用前需先初始化过 [ChatDatabaseService]（或 sqfliteFfi），
/// 否则全局 [databaseFactory] 未指向当前平台的实现。
Future<void> createLegacyDatabase({
  required int version,
  String sessionId = 'legacy-1',
}) async {
  assert(version >= 1 && version <= 5, '仅支持 v1~v5 旧库夹具');

  final dbPath = await legacyDatabasePath();
  Directory(p.dirname(dbPath)).createSync(recursive: true);

  final raw = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE chat_sessions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            character_id TEXT NOT NULL,
            selected_user_setting_id TEXT,
            selected_preset_id TEXT,
            ${version >= 5 ? 'gal_mode_enabled INTEGER NOT NULL DEFAULT 0,' : ''}
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
        if (version >= 2) {
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
        }
        if (version >= 4) {
          await db.execute('''
            CREATE TABLE chat_session_regex_rule_groups (
              session_id TEXT NOT NULL,
              regex_rule_group_id TEXT NOT NULL,
              PRIMARY KEY (session_id, regex_rule_group_id)
            )
          ''');
        }
      },
    ),
  );

  await raw.insert('chat_sessions', {
    'id': sessionId,
    'title': '旧会话',
    'character_id': 'char-1',
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  });
  await raw.close();
}
