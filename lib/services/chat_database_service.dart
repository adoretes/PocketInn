import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/chat_memory.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatDatabaseService {
  ChatDatabaseService._();

  static final ChatDatabaseService instance = ChatDatabaseService._();

  /// 会话 / 消息等聊天主体数据的变更信号；监听方通常会重载整条会话。
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// 记忆数据（`chat_memories`）的变更信号。
  ///
  /// 记忆不参与聊天消息渲染，[changeNotifier] 有意不广播记忆写入：
  /// 否则后台记忆提取落库会让聊天页整页重载一次。需要「记忆已更新」
  /// 精确信号的界面（如聊天侧边栏的记忆计数）监听这里。
  final ValueNotifier<int> memoryChangeNotifier = ValueNotifier<int>(0);

  static const int _dbVersion = 8;
  static const String _dbName = 'pocket_inn_chat.db';

  Database? _database;
  String? _dbPath;
  int _idSequence = 0;

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'pocket_inn_data', _dbName);
    _dbPath = dbPath;

    _database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _migrateSchema(db, oldVersion, newVersion);
        },
      ),
    );
  }

  Future<void> clearAllData() async {
    await deleteDatabaseFiles();
    _idSequence = 0;
    await initialize();
    _notifyChanged();
    // 数据库被整体重建，记忆求值缓存必须失效（否则会读到旧结果）。
    memoryChangeNotifier.value++;
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) {
      return;
    }
    await db.close();
    _database = null;
  }

  void resetIdSequence() {
    _idSequence = 0;
  }

  String? get databasePath => _dbPath;

  Future<void> deleteDatabaseFiles() async {
    await close();

    final dbPath = _dbPath;
    if (dbPath == null) {
      return;
    }
    await databaseFactory.deleteDatabase(dbPath);
  }

  Database get _db {
    final db = _database;
    if (db == null) {
      throw StateError('ChatDatabaseService 未初始化，请先调用 initialize()');
    }
    return db;
  }

  Future<void> _createMemoriesSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_memories (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        branch_leaf_id TEXT NOT NULL,
        content TEXT NOT NULL,
        source_message_ids TEXT NOT NULL DEFAULT '[]',
        is_user_edited INTEGER NOT NULL DEFAULT 0,
        importance INTEGER NOT NULL DEFAULT 3,
        type TEXT NOT NULL DEFAULT 'other',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_memories_session_branch '
      'ON chat_memories(session_id, branch_leaf_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_memories_created '
      'ON chat_memories(session_id, created_at DESC)',
    );
    await _createMemoryDiffSchema(db);
  }

  /// v7：记忆差量与提取运行记录。
  Future<void> _createMemoryDiffSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_memory_diffs (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        branch_leaf_id TEXT NOT NULL,
        target_memory_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        content TEXT,
        importance INTEGER,
        type TEXT,
        is_pinned INTEGER,
        is_user_edited INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (branch_leaf_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
        FOREIGN KEY (target_memory_id) REFERENCES chat_memories(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_memory_diffs_session_branch '
      'ON chat_memory_diffs(session_id, branch_leaf_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_memory_diffs_target '
      'ON chat_memory_diffs(target_memory_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_memory_extraction_runs (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        branch_leaf_id TEXT NOT NULL,
        processed_message_ids TEXT NOT NULL DEFAULT '[]',
        status TEXT NOT NULL,
        added_count INTEGER NOT NULL DEFAULT 0,
        updated_count INTEGER NOT NULL DEFAULT 0,
        invalidated_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT NOT NULL DEFAULT '',
        character_name TEXT NOT NULL DEFAULT '',
        user_name TEXT NOT NULL DEFAULT '',
        current_input TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (branch_leaf_id) REFERENCES chat_messages(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_memory_runs_anchor '
      'ON chat_memory_extraction_runs(branch_leaf_id)',
    );
  }

  Future<void> _migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // v2: 引入 chat_memories 表与索引
      await _createMemoriesSchema(db);
    }
    // v3: 仅调整 _dbVersion 占位，无 schema 变更。
    // 若未来需要在 v3 引入列/索引，请在此处添加 oldVersion < 3 分支。
    if (oldVersion < 4 && newVersion >= 4) {
      // v4: 引入 chat_session_regex_rule_groups 表，用于会话级正则规则组启用绑定。
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_session_regex_rule_groups (
          session_id TEXT NOT NULL,
          regex_rule_group_id TEXT NOT NULL,
          PRIMARY KEY (session_id, regex_rule_group_id),
          FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5 && newVersion >= 5) {
      // v5: chat_sessions 新增 gal_mode_enabled 列，用于会话级 gal 模式开关状态。
      // 先检查列是否存在：若之前的迁移在写入版本号前中断，列可能已存在，
      // 直接 ALTER 会因 duplicate column 报错，导致应用无法启动。
      final columns = await db.rawQuery('PRAGMA table_info(chat_sessions)');
      final hasGalModeColumn =
          columns.any((row) => row['name'] == 'gal_mode_enabled');
      if (!hasGalModeColumn) {
        await db.execute(
          'ALTER TABLE chat_sessions ADD COLUMN gal_mode_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 6 && newVersion >= 6) {
      // v6: 引入状态变量事件溯源表。
      // chat_variable_init 存会话初始变量；chat_variable_diffs 把变量差量
      // 挂在产生它的助手消息上，随消息删除级联清理，随分支各归各路。
      await _createVariableSchema(db);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      // v7: 记忆升级为「原始记忆 + 分支差量 + 提取运行记录」。
      // 先补 importance 列（旧库无此列），再建 diff / run 表。列存在性检查
      // 使迁移可安全重入。
      final columns = await db.rawQuery('PRAGMA table_info(chat_memories)');
      final hasImportance = columns.any(
        (row) => row['name'] == 'importance',
      );
      if (!hasImportance) {
        await db.execute(
          'ALTER TABLE chat_memories ADD COLUMN importance INTEGER NOT NULL DEFAULT 3',
        );
      }
      await _createMemoryDiffSchema(db);
    }
    if (oldVersion < 8 && newVersion >= 8) {
      // v8: 记忆引入类型与常驻标记。列存在性检查保证迁移可重入。
      final memoryColumns = await db.rawQuery(
        'PRAGMA table_info(chat_memories)',
      );
      if (!memoryColumns.any((row) => row['name'] == 'type')) {
        await db.execute(
          "ALTER TABLE chat_memories ADD COLUMN type TEXT NOT NULL DEFAULT 'other'",
        );
      }
      if (!memoryColumns.any((row) => row['name'] == 'is_pinned')) {
        await db.execute(
          'ALTER TABLE chat_memories ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
        );
      }
      final diffColumns = await db.rawQuery(
        'PRAGMA table_info(chat_memory_diffs)',
      );
      if (!diffColumns.any((row) => row['name'] == 'type')) {
        await db.execute(
          'ALTER TABLE chat_memory_diffs ADD COLUMN type TEXT',
        );
      }
      if (!diffColumns.any((row) => row['name'] == 'is_pinned')) {
        await db.execute(
          'ALTER TABLE chat_memory_diffs ADD COLUMN is_pinned INTEGER',
        );
      }
    }
  }

  Future<void> _createVariableSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_variable_init (
        session_id TEXT PRIMARY KEY,
        variables TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_variable_diffs (
        message_id TEXT PRIMARY KEY,
        ops TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        character_id TEXT NOT NULL,
        selected_user_setting_id TEXT,
        selected_preset_id TEXT,
        gal_mode_enabled INTEGER NOT NULL DEFAULT 0,
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
        PRIMARY KEY (session_id, world_book_id),
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_session_regex_rule_groups (
        session_id TEXT NOT NULL,
        regex_rule_group_id TEXT NOT NULL,
        PRIMARY KEY (session_id, regex_rule_group_id),
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
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
        sibling_order INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES chat_messages(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_branch_state (
        parent_message_id TEXT PRIMARY KEY,
        active_child_message_id TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_chat_sessions_updated_at ON chat_sessions(updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_session_parent ON chat_messages(session_id, parent_id, sibling_order)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_session_created ON chat_messages(session_id, created_at)',
    );

    await _createMemoriesSchema(db);
    await _createVariableSchema(db);
  }

  Future<ChatSession> createSession({
    required String characterId,
    String? title,
    String? selectedUserSettingId,
    List<String> selectedWorldBookIds = const [],
    List<String> selectedRegexRuleGroupIds = const [],
    String? selectedPresetId,
    bool galModeEnabled = false,
    List<String> openingAssistantMessages = const [],
    int activeOpeningMessageIndex = 0,
  }) async {
    final sessionId = _generateId('session');
    final now = DateTime.now();
    final normalizedOpeningMessages = openingAssistantMessages
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final openingMessageIds = [
      for (var i = 0; i < normalizedOpeningMessages.length; i++)
        _generateId('message'),
    ];
    final activeOpeningIndex = openingMessageIds.isEmpty
        ? -1
        : activeOpeningMessageIndex.clamp(0, openingMessageIds.length - 1);
    final session = ChatSession(
      id: sessionId,
      title: title?.trim().isNotEmpty == true ? title!.trim() : '新聊天',
      characterId: characterId,
      selectedUserSettingId: selectedUserSettingId,
      selectedWorldBookIds: List<String>.from(selectedWorldBookIds),
      selectedRegexRuleGroupIds: List<String>.from(selectedRegexRuleGroupIds),
      selectedPresetId: selectedPresetId,
      galModeEnabled: galModeEnabled,
      currentLeafMessageId: activeOpeningIndex >= 0
          ? openingMessageIds[activeOpeningIndex]
          : null,
      lastMessagePreview: activeOpeningIndex >= 0
          ? normalizedOpeningMessages[activeOpeningIndex]
          : '',
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction((tx) async {
      await tx.insert('chat_sessions', _sessionToMap(session));
      await _replaceSessionWorldBooks(
        tx,
        sessionId: session.id,
        worldBookIds: session.selectedWorldBookIds,
      );
      await _replaceSessionRegexRuleGroups(
        tx,
        sessionId: session.id,
        regexRuleGroupIds: session.selectedRegexRuleGroupIds,
      );
      for (var i = 0; i < normalizedOpeningMessages.length; i++) {
        final openingNode = ChatNode(
          id: openingMessageIds[i],
          sessionId: session.id,
          parentId: null,
          role: ChatNodeRole.assistant,
          text: normalizedOpeningMessages[i],
          createdAt: now,
          siblingOrder: i,
        );
        await tx.insert('chat_messages', _nodeToMap(openingNode));
      }
      if (activeOpeningIndex >= 0) {
        await _setActiveChild(
          tx,
          sessionId: session.id,
          parentMessageId: null,
          childMessageId: openingMessageIds[activeOpeningIndex],
        );
      }
    });

    _notifyChanged();
    return session;
  }

  Future<void> updateSessionTitle({
    required String sessionId,
    required String title,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return;
    }
    await _db.update(
      'chat_sessions',
      {
        'title': normalizedTitle,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    _notifyChanged();
  }

  Future<ChatSession?> loadSessionById(String id) async {
    final rows = await _db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final worldBookIds = await _loadSessionWorldBookIds(id);
    final regexRuleGroupIds = await _loadSessionRegexRuleGroupIds(id);
    return _sessionFromMap(
      rows.first,
      worldBookIds,
      regexRuleGroupIds,
    );
  }

  Future<ChatSessionBundle?> loadSessionBundle(String id) async {
    final session = await loadSessionById(id);
    if (session == null) {
      return null;
    }
    // 会话对象已读到手，直接传给消息加载，避免它内部再查一次同一行。
    final messages = await loadActivePathMessages(id, session: session);
    return ChatSessionBundle(session: session, activeMessages: messages);
  }

  Future<List<ChatSessionSummary>> loadSessionSummaries() async {
    final rows = await _db.query('chat_sessions', orderBy: 'updated_at DESC');
    return rows.map(_summaryFromMap).toList();
  }

  /// 最近更新的会话 id；仅在按 id 直查失败（记忆的会话已被删除）时用于回退。
  ///
  /// 只取主键一列，不加载整行，也不处理关联表。
  Future<String?> loadLatestSessionId() async {
    final rows = await _db.query(
      'chat_sessions',
      columns: ['id'],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['id'] as String;
  }

  Future<void> updateSessionConfig({
    required String sessionId,
    required String? selectedUserSettingId,
    required List<String> selectedWorldBookIds,
    required List<String> selectedRegexRuleGroupIds,
    required String? selectedPresetId,
    required bool galModeEnabled,
  }) async {
    await _db.transaction((tx) async {
      await tx.update(
        'chat_sessions',
        {
          'selected_user_setting_id': selectedUserSettingId,
          'selected_preset_id': selectedPresetId,
          'gal_mode_enabled': galModeEnabled ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await _replaceSessionWorldBooks(
        tx,
        sessionId: sessionId,
        worldBookIds: selectedWorldBookIds,
      );
      await _replaceSessionRegexRuleGroups(
        tx,
        sessionId: sessionId,
        regexRuleGroupIds: selectedRegexRuleGroupIds,
      );
    });
    _notifyChanged();
  }

  Future<void> resetSession({
    required String sessionId,
    required String title,
    required String? selectedUserSettingId,
    required List<String> selectedWorldBookIds,
    required List<String> selectedRegexRuleGroupIds,
    required String? selectedPresetId,
    List<String> openingAssistantMessages = const [],
  }) async {
    final normalizedTitle = title.trim().isNotEmpty ? title.trim() : '新聊天';
    final now = DateTime.now();
    final normalizedOpeningMessages = openingAssistantMessages
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final openingMessageIds = [
      for (var i = 0; i < normalizedOpeningMessages.length; i++)
        _generateId('message'),
    ];

    await _db.transaction((tx) async {
      final messageRows = await tx.query(
        'chat_messages',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      final messageIds = messageRows
          .map((row) => row['id'] as String)
          .toList(growable: false);

      if (messageIds.isNotEmpty) {
        final messagePlaceholders = List.filled(
          messageIds.length,
          '?',
        ).join(',');
        await tx.delete(
          'chat_branch_state',
          where:
              'parent_message_id IN ($messagePlaceholders) OR active_child_message_id IN ($messagePlaceholders)',
          whereArgs: [...messageIds, ...messageIds],
        );
      }

      await tx.delete(
        'chat_branch_state',
        where: 'parent_message_id = ?',
        whereArgs: [_rootBranchKey(sessionId)],
      );
      await tx.delete(
        'chat_memories',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await tx.delete(
        'chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await tx.update(
        'chat_sessions',
        {
          'title': normalizedTitle,
          'selected_user_setting_id': selectedUserSettingId,
          'selected_preset_id': selectedPresetId,
          'current_leaf_message_id': openingMessageIds.isNotEmpty
              ? openingMessageIds.first
              : null,
          'last_message_preview': normalizedOpeningMessages.isNotEmpty
              ? normalizedOpeningMessages.first
              : '',
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await _replaceSessionWorldBooks(
        tx,
        sessionId: sessionId,
        worldBookIds: selectedWorldBookIds,
      );
      await _replaceSessionRegexRuleGroups(
        tx,
        sessionId: sessionId,
        regexRuleGroupIds: selectedRegexRuleGroupIds,
      );

      for (var i = 0; i < normalizedOpeningMessages.length; i++) {
        final openingNode = ChatNode(
          id: openingMessageIds[i],
          sessionId: sessionId,
          parentId: null,
          role: ChatNodeRole.assistant,
          text: normalizedOpeningMessages[i],
          createdAt: now,
          siblingOrder: i,
        );
        await tx.insert('chat_messages', _nodeToMap(openingNode));
      }

      if (openingMessageIds.isNotEmpty) {
        await _setActiveChild(
          tx,
          sessionId: sessionId,
          parentMessageId: null,
          childMessageId: openingMessageIds.first,
        );
      }
    });

    _notifyChanged();
  }

  Future<void> updateMessage({
    required String sessionId,
    required String messageId,
    required String text,
    String? thinkingChain,
    bool clearThinkingChain = false,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw const FormatException('消息不能为空');
    }

    await _db.transaction((tx) async {
      final existingRows = await tx.query(
        'chat_messages',
        columns: ['id'],
        where: 'id = ? AND session_id = ?',
        whereArgs: [messageId, sessionId],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        return;
      }

      await tx.update(
        'chat_messages',
        {
          'text': normalizedText,
          'thinking_chain': clearThinkingChain ? null : thinkingChain,
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );

      final nextLeafId = await _resolveLeafForSession(tx, sessionId);
      final preview = nextLeafId == null
          ? ''
          : await _loadMessageText(tx, nextLeafId) ?? '';

      await tx.update(
        'chat_sessions',
        {
          'current_leaf_message_id': nextLeafId,
          'last_message_preview': preview,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    _notifyChanged();
  }

  Future<ChatNode> branchMessageFromEdit({
    required String sessionId,
    required String messageId,
    required String text,
    String? thinkingChain,
    bool clearThinkingChain = false,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw const FormatException('消息不能为空');
    }

    final now = DateTime.now();
    final node = await _db.transaction((tx) async {
      final existingRows = await tx.query(
        'chat_messages',
        columns: ['parent_id', 'role'],
        where: 'id = ? AND session_id = ?',
        whereArgs: [messageId, sessionId],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('消息不存在或已被删除');
      }

      final existingRow = existingRows.first;
      final parentId = existingRow['parent_id'] as String?;
      final role = ChatNodeRole.fromValue(existingRow['role'] as String);
      final siblingOrder = await _nextSiblingOrder(
        tx,
        sessionId: sessionId,
        parentMessageId: parentId,
      );
      final nextMessageId = _generateId('message');
      final node = ChatNode(
        id: nextMessageId,
        sessionId: sessionId,
        parentId: parentId,
        role: role,
        text: normalizedText,
        thinkingChain: clearThinkingChain ? null : thinkingChain,
        createdAt: now,
        siblingOrder: siblingOrder,
      );

      await tx.insert('chat_messages', _nodeToMap(node));
      await _setActiveChild(
        tx,
        sessionId: sessionId,
        parentMessageId: parentId,
        childMessageId: nextMessageId,
      );
      await tx.update(
        'chat_sessions',
        {
          'current_leaf_message_id': nextMessageId,
          'last_message_preview': normalizedText,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      return node;
    });

    _notifyChanged();
    return node;
  }

  Future<ChatNode> appendUserMessage({
    required String sessionId,
    required String? parentMessageId,
    required String text,
  }) {
    return _appendMessage(
      sessionId: sessionId,
      parentMessageId: parentMessageId,
      role: ChatNodeRole.user,
      text: text,
    );
  }

  Future<ChatNode> appendAssistantMessage({
    required String sessionId,
    required String? parentMessageId,
    required String text,
    String? thinkingChain,
  }) {
    return _appendMessage(
      sessionId: sessionId,
      parentMessageId: parentMessageId,
      role: ChatNodeRole.assistant,
      text: text,
      thinkingChain: thinkingChain,
    );
  }

  Future<void> switchActiveBranch({
    required String sessionId,
    required String? parentMessageId,
    required String childMessageId,
  }) async {
    await _db.transaction((tx) async {
      final childRows = await tx.query(
        'chat_messages',
        columns: ['id', 'session_id', 'parent_id'],
        where: 'id = ?',
        whereArgs: [childMessageId],
        limit: 1,
      );
      if (childRows.isEmpty) {
        return;
      }

      await _setActiveChild(
        tx,
        sessionId: sessionId,
        parentMessageId: parentMessageId,
        childMessageId: childMessageId,
      );

      final leafId = await _resolveLeafFromNode(
        tx,
        sessionId: sessionId,
        startMessageId: childMessageId,
      );

      await tx.update(
        'chat_sessions',
        {'current_leaf_message_id': leafId},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    _notifyChanged();
  }

  Future<void> deleteSession(String sessionId) async {
    final deletedCount = await _deleteSessionsByIds([sessionId]);
    if (deletedCount > 0) {
      _notifyChanged();
    }
  }

  Future<int> deleteSessionsByCharacterId(String characterId) async {
    final rows = await _db.query(
      'chat_sessions',
      columns: ['id'],
      where: 'character_id = ?',
      whereArgs: [characterId],
    );
    final sessionIds = rows
        .map((row) => row['id'] as String)
        .toList(growable: false);
    if (sessionIds.isEmpty) {
      return 0;
    }

    final deletedCount = await _deleteSessionsByIds(sessionIds);
    if (deletedCount > 0) {
      _notifyChanged();
    }
    return deletedCount;
  }

  Future<void> deleteMessageBranch({
    required String sessionId,
    required String messageId,
  }) async {
    await _db.transaction((tx) async {
      final subtreeIds = await _collectSubtreeIds(tx, messageId);
      if (subtreeIds.isEmpty) {
        return;
      }

      final messageRows = await tx.query(
        'chat_messages',
        columns: ['id', 'parent_id', 'sibling_order'],
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      if (messageRows.isEmpty) {
        return;
      }
      final messageRow = messageRows.first;
      final parentId = messageRow['parent_id'] as String?;

      // 分批删除：长分支的子树 id 可能上千，避免撑爆 SQLite 变量上限；
      // 仍在同一事务内分批，整体保持原子性。
      for (final chunk in _chunked(subtreeIds, _sqlInChunkSize)) {
        final placeholders = List.filled(chunk.length, '?').join(',');
        await tx.delete(
          'chat_branch_state',
          where:
              'parent_message_id IN ($placeholders) OR active_child_message_id IN ($placeholders)',
          whereArgs: [...chunk, ...chunk],
        );

        // 记忆差量与提取记录挂在消息分支上，随子树一并清理；显式删除
        // 避免依赖外键级联在不同运行环境下的行为差异。
        await tx.delete(
          'chat_memory_extraction_runs',
          where: 'branch_leaf_id IN ($placeholders)',
          whereArgs: chunk,
        );
        await tx.delete(
          'chat_memory_diffs',
          where: 'branch_leaf_id IN ($placeholders)',
          whereArgs: chunk,
        );

        await tx.delete(
          'chat_memories',
          where: 'branch_leaf_id IN ($placeholders)',
          whereArgs: chunk,
        );

        await tx.delete(
          'chat_messages',
          where: 'id IN ($placeholders)',
          whereArgs: chunk,
        );
      }

      final replacementChildId = await _findPreferredChildAfterDelete(
        tx,
        sessionId: sessionId,
        parentMessageId: parentId,
      );

      if (replacementChildId == null) {
        await tx.delete(
          'chat_branch_state',
          where: 'parent_message_id = ?',
          whereArgs: [_branchKey(sessionId, parentId)],
        );
      } else {
        await _setActiveChild(
          tx,
          sessionId: sessionId,
          parentMessageId: parentId,
          childMessageId: replacementChildId,
        );
      }

      final nextLeafId = await _resolveLeafForSession(tx, sessionId);
      final preview = nextLeafId == null
          ? ''
          : await _loadMessageText(tx, nextLeafId) ?? '';

      await tx.update(
        'chat_sessions',
        {
          'current_leaf_message_id': nextLeafId,
          'last_message_preview': preview,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    _notifyChanged();
  }

  /// 加载会话的活跃分支消息（根 → 叶）。
  ///
  /// [session] 为已知的会话对象时跳过重复读取：调用方通常刚读过同一行。
  ///
  /// 实现要点：先一次性取回本会话所有节点的结构（id/parent_id），在内存里
  /// 回溯路径并建立 `parent → 兄弟 id 列表` 索引，再批量取回路径节点的正文。
  /// 旧的逐节点回溯 + 逐节点查兄弟共需 `2N` 条 SQL（线性会话下兄弟查询每次
  /// 都只返回自己），现在固定为 `1 + ⌈N/500⌉` 条。
  Future<List<ChatMessage>> loadActivePathMessages(
    String sessionId, {
    ChatSession? session,
  }) async {
    final resolvedSession = session ?? await loadSessionById(sessionId);
    if (resolvedSession == null) {
      return const [];
    }

    final leafId = await _resolveLeafForSession(
      _db,
      sessionId,
      session: resolvedSession,
    );
    if (leafId == null) {
      return const [];
    }

    // 一次性取回本会话的节点结构；命中 idx_chat_messages_session_parent。
    // 排序与原先的兄弟查询一致，分组后组内顺序自然保持 sibling_order,created_at。
    final structureRows = await _db.query(
      'chat_messages',
      columns: ['id', 'parent_id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sibling_order ASC, created_at ASC',
    );
    if (structureRows.isEmpty) {
      return const [];
    }

    final parentOf = <String, String?>{};
    final siblingsByParent = <String?, List<String>>{};
    for (final row in structureRows) {
      final id = row['id'] as String;
      final parentId = row['parent_id'] as String?;
      parentOf[id] = parentId;
      (siblingsByParent[parentId] ??= <String>[]).add(id);
    }

    // 从叶子沿 parent 指针在内存中回溯到根。
    final reversedPathIds = <String>[];
    String? currentId = leafId;
    while (currentId != null) {
      if (!parentOf.containsKey(currentId)) {
        break;
      }
      reversedPathIds.add(currentId);
      currentId = parentOf[currentId];
    }
    if (reversedPathIds.isEmpty) {
      return const [];
    }
    final pathIds = reversedPathIds.reversed.toList(growable: false);

    // 只取路径节点的完整行，忽略其它分支的正文。
    final nodesById = <String, ChatNode>{};
    for (final chunk in _chunked(pathIds, _sqlInChunkSize)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _db.query(
        'chat_messages',
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final row in rows) {
        final node = _nodeFromMap(row);
        nodesById[node.id] = node;
      }
    }

    final result = <ChatMessage>[];
    for (final id in pathIds) {
      final node = nodesById[id];
      if (node == null) {
        continue;
      }
      final siblingIds = siblingsByParent[node.parentId] ?? const <String>[];
      final siblingIndex = siblingIds.indexOf(node.id);

      result.add(
        ChatMessage(
          id: node.id,
          sessionId: node.sessionId,
          parentId: node.parentId,
          text: node.text,
          isMe: node.role == ChatNodeRole.user,
          index: siblingIndex >= 0 ? siblingIndex + 1 : 1,
          total: siblingIds.isNotEmpty ? siblingIds.length : 1,
          siblingIds: siblingIds,
          thinkingChain: node.thinkingChain,
        ),
      );
    }

    return result;
  }

  Future<ChatNode> _appendMessage({
    required String sessionId,
    required String? parentMessageId,
    required ChatNodeRole role,
    required String text,
    String? thinkingChain,
  }) async {
    final now = DateTime.now();
    final node = await _db.transaction((tx) async {
      final siblingOrder = await _nextSiblingOrder(
        tx,
        sessionId: sessionId,
        parentMessageId: parentMessageId,
      );
      final messageId = _generateId('message');
      final node = ChatNode(
        id: messageId,
        sessionId: sessionId,
        parentId: parentMessageId,
        role: role,
        text: text,
        thinkingChain: thinkingChain,
        createdAt: now,
        siblingOrder: siblingOrder,
      );

      await tx.insert('chat_messages', _nodeToMap(node));
      await _setActiveChild(
        tx,
        sessionId: sessionId,
        parentMessageId: parentMessageId,
        childMessageId: messageId,
      );
      await tx.update(
        'chat_sessions',
        {
          'current_leaf_message_id': messageId,
          'last_message_preview': text,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      return node;
    });

    _notifyChanged();
    return node;
  }

  Future<int> _deleteSessionsByIds(List<String> sessionIds) async {
    if (sessionIds.isEmpty) {
      return 0;
    }

    final sessionPlaceholders = List.filled(sessionIds.length, '?').join(',');
    final rootKeys = sessionIds.map(_rootBranchKey).toList(growable: false);
    final rootPlaceholders = List.filled(rootKeys.length, '?').join(',');

    return _db.transaction((tx) async {
      final messageRows = await tx.query(
        'chat_messages',
        columns: ['id'],
        where: 'session_id IN ($sessionPlaceholders)',
        whereArgs: sessionIds,
      );
      final messageIds = messageRows
          .map((row) => row['id'] as String)
          .toList(growable: false);

      if (messageIds.isNotEmpty) {
        final messagePlaceholders = List.filled(
          messageIds.length,
          '?',
        ).join(',');
        await tx.delete(
          'chat_branch_state',
          where:
              'parent_message_id IN ($messagePlaceholders) OR active_child_message_id IN ($messagePlaceholders)',
          whereArgs: [...messageIds, ...messageIds],
        );
      }

      await tx.delete(
        'chat_branch_state',
        where: 'parent_message_id IN ($rootPlaceholders)',
        whereArgs: rootKeys,
      );

      return tx.delete(
        'chat_sessions',
        where: 'id IN ($sessionPlaceholders)',
        whereArgs: sessionIds,
      );
    });
  }

  Future<List<MemoryNode>> loadBranchMemories(
    String sessionId,
    List<String> branchLeafIds,
  ) async {
    if (branchLeafIds.isEmpty) return const [];
    return _loadBranchMemories(_db, sessionId, branchLeafIds);
  }

  Future<List<MemoryNode>> _loadBranchMemories(
    DatabaseExecutor executor,
    String sessionId,
    List<String> branchLeafIds,
  ) async {
    // 分批查询：长分支的路径 id 可能上千，避免撑爆 SQLite 的变量上限。
    final memories = <MemoryNode>[];
    for (final chunk in _chunked(branchLeafIds, _sqlInChunkSize)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await executor.query(
        'chat_memories',
        where: 'session_id = ? AND branch_leaf_id IN ($placeholders)',
        whereArgs: [sessionId, ...chunk],
        orderBy: 'created_at DESC',
      );
      memories.addAll(rows.map(_memoryFromMap));
    }
    // 分批后补一次全局排序，保持与单条 IN 查询一致的 created_at 降序语义。
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return memories;
  }

  /// 只读取指定分支路径上的记忆差量（按创建时间升序）。
  ///
  /// 与 [loadBranchMemories] 配套：求值某条路径时只取该路径上的记忆与差量，
  /// 避免把其它兄弟分支的整表数据也拉进内存。分批查询避免撑爆 SQLite
  /// 变量上限；分批后补一次全局 created_at 升序排序。
  Future<List<MemoryDiff>> loadBranchMemoryDiffs(
    String sessionId,
    List<String> branchLeafIds,
  ) async {
    if (branchLeafIds.isEmpty) return const [];
    return _loadBranchMemoryDiffs(_db, sessionId, branchLeafIds);
  }

  Future<List<MemoryDiff>> _loadBranchMemoryDiffs(
    DatabaseExecutor executor,
    String sessionId,
    List<String> branchLeafIds,
  ) async {
    final diffs = <MemoryDiff>[];
    for (final chunk in _chunked(branchLeafIds, _sqlInChunkSize)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await executor.query(
        'chat_memory_diffs',
        where: 'session_id = ? AND branch_leaf_id IN ($placeholders)',
        whereArgs: [sessionId, ...chunk],
        orderBy: 'created_at ASC',
      );
      diffs.addAll(rows.map(_memoryDiffFromMap));
    }
    diffs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return diffs;
  }

  /// 在同一只读事务内读取提取所需的原始记忆与分支差量，避免混用两个时刻。
  Future<MemoryExtractionSnapshot> loadMemoryExtractionSnapshot({
    required String sessionId,
    required List<String> pathMessageIds,
  }) async {
    final path = List<String>.unmodifiable(pathMessageIds);
    return _db.transaction((tx) async {
      final memories = await _loadBranchMemories(tx, sessionId, path);
      final diffs = await _loadBranchMemoryDiffs(tx, sessionId, path);
      return MemoryExtractionSnapshot(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
      );
    }, exclusive: false);
  }

  Future<List<MemoryNode>> loadAllSessionMemories(String sessionId) async {
    final rows = await _db.query(
      'chat_memories',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_memoryFromMap).toList();
  }

  /// 按 id 读取单条原始记忆；不存在返回 null。
  Future<MemoryNode?> loadMemoryById(String memoryId) async {
    final rows = await _db.query(
      'chat_memories',
      where: 'id = ?',
      whereArgs: [memoryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _memoryFromMap(rows.first);
  }

  /// 读取会话内全部记忆差量（按创建时间升序）。
  Future<List<MemoryDiff>> loadAllSessionMemoryDiffs(String sessionId) async {
    final rows = await _db.query(
      'chat_memory_diffs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_memoryDiffFromMap).toList();
  }

  /// 读取会话内全部提取运行记录（按创建时间升序）。
  Future<List<MemoryExtractionRun>> loadAllSessionExtractionRuns(
    String sessionId,
  ) async {
    final rows = await _db.query(
      'chat_memory_extraction_runs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_extractionRunFromMap).toList();
  }

  Future<List<ChatNode>> loadAllSessionNodes(String sessionId) async {
    final rows = await _db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, sibling_order ASC',
    );
    return rows.map(_nodeFromMap).toList(growable: false);
  }

  Future<String> resolveLeafFromMessage({
    required String sessionId,
    required String messageId,
  }) async {
    return _resolveLeafFromNode(
      _db,
      sessionId: sessionId,
      startMessageId: messageId,
    );
  }

  Future<void> insertMemory(MemoryNode memory) async {
    await _db.insert('chat_memories', _memoryToMap(memory));
    notifyMemoryChanged();
  }

  Future<void> insertMemoriesInTx(List<MemoryNode> memories) async {
    if (memories.isEmpty) return;
    await _db.transaction((tx) async {
      for (final m in memories) {
        await tx.insert('chat_memories', _memoryToMap(m));
      }
    });
    notifyMemoryChanged();
  }

  /// 更新原始记忆的内容 / 重要度（仅来源节点使用）。
  Future<void> updateMemoryRow({
    required String memoryId,
    required String content,
    required int importance,
    MemoryType? type,
    bool? isPinned,
  }) async {
    await _db.update(
      'chat_memories',
      {
        'content': content,
        'importance': importance,
        if (type != null) 'type': type.name,
        if (isPinned != null) 'is_pinned': isPinned ? 1 : 0,
        'is_user_edited': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [memoryId],
    );
    notifyMemoryChanged();
  }

  /// 物理删除原始记忆（其差量由外键级联清理）。
  Future<void> deleteMemoryById(String memoryId) async {
    await _db.delete('chat_memories', where: 'id = ?', whereArgs: [memoryId]);
    notifyMemoryChanged();
  }

  /// 写入一条记忆差量。
  Future<void> insertMemoryDiff(MemoryDiff diff) async {
    await _db.insert('chat_memory_diffs', _memoryDiffToMap(diff));
    notifyMemoryChanged();
  }

  /// 读取某节点上产生过差量的目标记忆 id（用于判断“本节点是否有改动”）。
  Future<Set<String>> loadMemoryDiffTargetsAtNode({
    required String sessionId,
    required String branchLeafId,
  }) async {
    final rows = await _db.query(
      'chat_memory_diffs',
      columns: ['target_memory_id'],
      where: 'session_id = ? AND branch_leaf_id = ?',
      whereArgs: [sessionId, branchLeafId],
    );
    return {
      for (final row in rows) row['target_memory_id'] as String,
    };
  }

  /// 删除某节点上针对指定记忆的全部差量，使其回退到祖先节点的状态。
  ///
  /// 只动该节点自己的差量，不影响祖先或其它分支。
  Future<int> deleteMemoryDiffsAtNode({
    required String sessionId,
    required String branchLeafId,
    required String targetMemoryId,
  }) async {
    final deleted = await _db.delete(
      'chat_memory_diffs',
      where: 'session_id = ? AND branch_leaf_id = ? AND target_memory_id = ?',
      whereArgs: [sessionId, branchLeafId, targetMemoryId],
    );
    if (deleted > 0) {
      notifyMemoryChanged();
    }
    return deleted;
  }

  /// 写入（或覆盖）一次提取运行记录（按锚点消息唯一）。
  Future<void> upsertExtractionRun(MemoryExtractionRun run) async {
    await _db.insert(
      'chat_memory_extraction_runs',
      _extractionRunToMap(run),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyMemoryChanged();
  }

  /// 删除锚点消息上的提取运行记录。
  Future<void> deleteExtractionRun(String branchLeafId) async {
    await _db.delete(
      'chat_memory_extraction_runs',
      where: 'branch_leaf_id = ?',
      whereArgs: [branchLeafId],
    );
    notifyMemoryChanged();
  }

  /// 原子地应用一次提取结果（包括无变化与失败）：先检查锚点仍允许本次提交，
  /// 再校验原始行与相关分支差量，最后一起写入记忆、差量与运行记录。
  ///
  /// [expectedRunId] 为空时要求锚点尚无记录；否则只允许替换该 id 的失败记录。
  /// 前置条件失效抛出 [MemoryExtractionSuperseded]，不可用迟到结果覆盖新记录。
  /// 原始行或 [branchSnapshot] 路径内相关目标的差量变化时抛出
  /// [MemoryExtractionConflict]，整体回滚以保护请求期间的用户编辑。
  Future<void> applyMemoryExtractionTx({
    required List<MemoryNode> newMemories,
    required List<MemoryDiff> diffs,
    required MemoryExtractionRun run,
    required Map<String, MemorySnapshotEntry> expectedSnapshot,
    MemoryExtractionSnapshot? branchSnapshot,
    String? expectedRunId,
  }) async {
    await _db.transaction((tx) async {
      final existingRuns = await tx.query(
        'chat_memory_extraction_runs',
        columns: ['id', 'status'],
        where: 'branch_leaf_id = ?',
        whereArgs: [run.branchLeafId],
        limit: 1,
      );
      final existingRun = existingRuns.isEmpty ? null : existingRuns.first;
      if (expectedRunId == null
          ? existingRun != null
          : existingRun == null ||
                existingRun['id'] != expectedRunId ||
                existingRun['status'] != MemoryExtractionStatus.failed.name) {
        throw const MemoryExtractionSuperseded('提取运行记录已变化，本次结果已过期');
      }

      for (final entry in expectedSnapshot.entries) {
        final rows = await tx.query(
          'chat_memories',
          columns: ['content', 'importance', 'type', 'is_pinned'],
          where: 'id = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const MemoryExtractionConflict('目标记忆已不存在');
        }
        final row = rows.first;
        final content = row['content'] as String? ?? '';
        final importance = (row['importance'] as int?) ?? 3;
        final type = MemoryType.fromName(row['type'] as String?);
        final isPinned = ((row['is_pinned'] as int?) ?? 0) == 1;
        // 内容 / 重要度 / 类型 / 常驻，任一被并发修改都判为冲突，
        // 避免后台提取结果覆盖用户编辑（包括仅改类型或常驻的场景）。
        if (content != entry.value.content ||
            importance != entry.value.importance ||
            type != entry.value.type ||
            isPinned != entry.value.isPinned) {
          throw const MemoryExtractionConflict('目标记忆在提取期间被修改');
        }
      }
      if (branchSnapshot != null && expectedSnapshot.isNotEmpty) {
        final targetIds = expectedSnapshot.keys.toSet();
        final pathIds = branchSnapshot.pathMessageIds.toSet();
        final expectedDiffIds = branchSnapshot.diffs
            .where(
              (diff) =>
                  diff.sessionId == run.sessionId &&
                  pathIds.contains(diff.branchLeafId) &&
                  targetIds.contains(diff.targetMemoryId),
            )
            .map((diff) => diff.id)
            .toSet();
        final currentDiffs = await _loadBranchMemoryDiffs(
          tx,
          run.sessionId,
          branchSnapshot.pathMessageIds,
        );
        final currentDiffIds = currentDiffs
            .where((diff) => targetIds.contains(diff.targetMemoryId))
            .map((diff) => diff.id)
            .toSet();
        if (!setEquals(expectedDiffIds, currentDiffIds)) {
          throw const MemoryExtractionConflict('目标记忆的分支差量在提取期间被修改');
        }
      }
      for (final m in newMemories) {
        await tx.insert('chat_memories', _memoryToMap(m));
      }
      for (final d in diffs) {
        await tx.insert('chat_memory_diffs', _memoryDiffToMap(d));
      }
      await tx.insert(
        'chat_memory_extraction_runs',
        _extractionRunToMap(run),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    notifyMemoryChanged();
  }

  /// 原子地应用一批用户手动编辑（新增 / 更新 / 失效 / 恢复 / 还原 / 删除）。
  ///
  /// 编辑弹窗的保存通过这里统一落库：所有改动在同一事务内完成，任一失败整体
  /// 回滚，避免出现「前几条已写入、后一条报错」的半提交状态，也避免用户再次
  /// 保存时把已新增的条目重复插入。
  Future<void> applyMemoryEditsTx({
    required String sessionId,
    required List<MemoryNode> newMemories,
    required List<MemoryDiff> newDiffs,
    required List<String> deleteMemoryIds,
    required List<MemoryRowUpdate> rowUpdates,
    required List<DiffClearTarget> clearDiffTargets,
  }) async {
    if (newMemories.isEmpty &&
        newDiffs.isEmpty &&
        deleteMemoryIds.isEmpty &&
        rowUpdates.isEmpty &&
        clearDiffTargets.isEmpty) {
      return;
    }
    await _db.transaction((tx) async {
      // 先清除「还原」要丢弃的旧差量，再写入新差量：同一目标若同时被还原并
      // 重新编辑（clear + update），保证新的 update 落在清理之后而不被误删。
      for (final target in clearDiffTargets) {
        await tx.delete(
          'chat_memory_diffs',
          where:
              'session_id = ? AND branch_leaf_id = ? AND target_memory_id = ?',
          whereArgs: [sessionId, target.branchLeafId, target.targetMemoryId],
        );
      }
      for (final id in deleteMemoryIds) {
        await tx.delete('chat_memories', where: 'id = ?', whereArgs: [id]);
      }
      final nowIso = DateTime.now().toIso8601String();
      for (final update in rowUpdates) {
        await tx.update(
          'chat_memories',
          {
            'content': update.content,
            'importance': update.importance,
            'type': update.type.name,
            'is_pinned': update.isPinned ? 1 : 0,
            'is_user_edited': 1,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [update.memoryId],
        );
      }
      for (final memory in newMemories) {
        await tx.insert('chat_memories', _memoryToMap(memory));
      }
      for (final diff in newDiffs) {
        await tx.insert('chat_memory_diffs', _memoryDiffToMap(diff));
      }
    });
    notifyMemoryChanged();
  }

  /// 按 id 顺序读取消息（用于失败重试时还原对话上下文）。
  Future<List<ChatMessage>> loadMessagesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final byId = <String, ChatMessage>{};
    for (final chunk in _chunked(ids, _sqlInChunkSize)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _db.query(
        'chat_messages',
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final row in rows) {
        final node = _nodeFromMap(row);
        byId[node.id] = ChatMessage(
          id: node.id,
          sessionId: node.sessionId,
          parentId: node.parentId,
          text: node.text,
          isMe: node.role == ChatNodeRole.user,
        );
      }
    }
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  // ==================== 状态变量（事件溯源） ====================

  /// 读取会话初始变量的 JSON 快照；未设置时返回 null。
  Future<String?> loadVariableInit(String sessionId) async {
    final rows = await _db.query(
      'chat_variable_init',
      columns: ['variables'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['variables'] as String?;
  }

  /// 写入（或覆盖）会话初始变量。
  ///
  /// 变量属按需求值的派生数据，不广播 DB 变化：广播会触发会话重载，
  /// 进而清掉 gal 选项等瞬态 UI 状态（发送时的 {{getvar}} 与调试页
  /// 均为读取时求值，无需通知）。
  Future<void> saveVariableInit({
    required String sessionId,
    required String valuesJson,
  }) async {
    await _db.insert(
      'chat_variable_init',
      {'session_id': sessionId, 'variables': valuesJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 读取挂在某条消息上的变量差量 JSON；无差量返回 null。
  Future<String?> loadVariableDiff(String messageId) async {
    final rows = await _db.query(
      'chat_variable_diffs',
      columns: ['ops'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['ops'] as String?;
  }

  /// 单条 SQL 允许绑定的最大参数个数。
  ///
  /// SQLite 老版本的 `SQLITE_MAX_VARIABLE_NUMBER` 为 999，长分支（上千条
  /// 消息）一次性拼占位符会直接报 "too many SQL variables"。这里保守取
  /// 500 并分批查询，避免深会话求值整体失败。
  static const int _maxSqlParameters = 500;

  /// 批量读取多条消息的变量差量（用于沿路径折叠，避免逐条查询）。
  ///
  /// 消息数超过 [_maxSqlParameters] 时自动分批，结果合并后返回。
  Future<Map<String, String>> loadVariableDiffBatch(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) {
      return const {};
    }
    final result = <String, String>{};
    for (
      var start = 0;
      start < messageIds.length;
      start += _maxSqlParameters
    ) {
      final end = start + _maxSqlParameters < messageIds.length
          ? start + _maxSqlParameters
          : messageIds.length;
      final chunk = messageIds.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _db.query(
        'chat_variable_diffs',
        columns: ['message_id', 'ops'],
        where: 'message_id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final row in rows) {
        result[row['message_id'] as String] = row['ops'] as String? ?? '[]';
      }
    }
    return result;
  }

  /// 写入（或覆盖）消息的变量差量。不广播 DB 变化，见 [saveVariableInit]。
  Future<void> saveVariableDiff({
    required String messageId,
    required String opsJson,
  }) async {
    await _db.insert(
      'chat_variable_diffs',
      {
        'message_id': messageId,
        'ops': opsJson,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 删除消息的变量差量（原地编辑后旧差量即过期）。不广播 DB 变化。
  Future<void> deleteVariableDiff(String messageId) async {
    await _db.delete(
      'chat_variable_diffs',
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  /// 从 [messageId] 沿 parent 链回溯到根，返回顺序为
  /// `[messageId, parent, ..., root]`；消息不存在返回空列表。
  ///
  /// 用递归 CTE 一次取回整条路径：逐层查询在长分支上会退化成 N+1。
  /// [maxDepth] 兜底异常的 parent 环，避免递归不收敛。
  Future<List<String>> loadMessageAncestorIds(
    String messageId, {
    int maxDepth = 4096,
  }) async {
    final rows = await _db.rawQuery(
      '''
      WITH RECURSIVE path(id, parent_id, depth) AS (
        SELECT id, parent_id, 0 FROM chat_messages WHERE id = ?
        UNION ALL
        SELECT m.id, m.parent_id, path.depth + 1
        FROM chat_messages m
        JOIN path ON m.id = path.parent_id
        WHERE path.depth < ?
      )
      SELECT id FROM path ORDER BY depth ASC
      ''',
      [messageId, maxDepth],
    );
    return [for (final row in rows) row['id'] as String];
  }

  void notifyDataChanged() {
    changeNotifier.value++;
  }

  /// 广播记忆数据已变化；不触发聊天消息的重载。
  void notifyMemoryChanged() {
    memoryChangeNotifier.value++;
  }

  void _notifyChanged() {
    notifyDataChanged();
  }

  /// 是否仍有会话在使用指定世界书（用于删除角色时避免误删共用世界书）。
  Future<bool> isWorldBookUsedBySessions(String worldBookId) async {
    final rows = await _db.query(
      'chat_session_world_books',
      columns: ['session_id'],
      where: 'world_book_id = ?',
      whereArgs: [worldBookId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<String>> _loadSessionWorldBookIds(String sessionId) async {
    final rows = await _db.query(
      'chat_session_world_books',
      columns: ['world_book_id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'world_book_id ASC',
    );
    return rows
        .map((row) => row['world_book_id'] as String)
        .toList(growable: false);
  }

  Future<void> _replaceSessionWorldBooks(
    DatabaseExecutor tx, {
    required String sessionId,
    required List<String> worldBookIds,
  }) async {
    await tx.delete(
      'chat_session_world_books',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    for (final worldBookId in worldBookIds.toSet()) {
      await tx.insert('chat_session_world_books', {
        'session_id': sessionId,
        'world_book_id': worldBookId,
      });
    }
  }

  Future<List<String>> _loadSessionRegexRuleGroupIds(
    String sessionId,
  ) async {
    final rows = await _db.query(
      'chat_session_regex_rule_groups',
      columns: ['regex_rule_group_id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'regex_rule_group_id ASC',
    );
    return rows
        .map((row) => row['regex_rule_group_id'] as String)
        .toList(growable: false);
  }

  Future<void> _replaceSessionRegexRuleGroups(
    DatabaseExecutor tx, {
    required String sessionId,
    required List<String> regexRuleGroupIds,
  }) async {
    await tx.delete(
      'chat_session_regex_rule_groups',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    for (final groupId in regexRuleGroupIds.toSet()) {
      await tx.insert('chat_session_regex_rule_groups', {
        'session_id': sessionId,
        'regex_rule_group_id': groupId,
      });
    }
  }

  Future<int> _nextSiblingOrder(
    DatabaseExecutor tx, {
    required String sessionId,
    required String? parentMessageId,
  }) async {
    final rows = await tx.rawQuery(
      parentMessageId == null
          ? '''
            SELECT COALESCE(MAX(sibling_order), -1) AS max_order
            FROM chat_messages
            WHERE session_id = ? AND parent_id IS NULL
          '''
          : '''
            SELECT COALESCE(MAX(sibling_order), -1) AS max_order
            FROM chat_messages
            WHERE session_id = ? AND parent_id = ?
          ''',
      parentMessageId == null ? [sessionId] : [sessionId, parentMessageId],
    );

    final maxOrder = rows.first['max_order'] as int? ?? -1;
    return maxOrder + 1;
  }

  Future<void> _setActiveChild(
    DatabaseExecutor tx, {
    required String sessionId,
    required String? parentMessageId,
    required String childMessageId,
  }) async {
    await tx.insert('chat_branch_state', {
      'parent_message_id': _branchKey(sessionId, parentMessageId),
      'active_child_message_id': childMessageId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 解析会话当前的叶子消息 id。
  ///
  /// [session] 为调用方刚读到的会话对象时直接复用其 `currentLeafMessageId`，
  /// 省掉一次重复的 `chat_sessions` 查询（事务内刚改过叶子时不要传，会读到旧值）。
  Future<String?> _resolveLeafForSession(
    DatabaseExecutor tx,
    String sessionId, {
    ChatSession? session,
  }) async {
    String? currentLeafId;
    if (session != null) {
      currentLeafId = session.currentLeafMessageId;
    } else {
      final sessionRows = await tx.query(
        'chat_sessions',
        columns: ['current_leaf_message_id'],
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      if (sessionRows.isEmpty) {
        return null;
      }
      currentLeafId = sessionRows.first['current_leaf_message_id'] as String?;
    }

    if (currentLeafId != null) {
      final existing = await tx.query(
        'chat_messages',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [currentLeafId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return currentLeafId;
      }
    }

    final rootStateRows = await tx.query(
      'chat_branch_state',
      columns: ['active_child_message_id'],
      where: 'parent_message_id = ?',
      whereArgs: [_rootBranchKey(sessionId)],
      limit: 1,
    );

    String? rootMessageId = rootStateRows.isNotEmpty
        ? rootStateRows.first['active_child_message_id'] as String?
        : null;

    if (rootMessageId == null) {
      final rootRows = await tx.query(
        'chat_messages',
        columns: ['id'],
        where: 'session_id = ? AND parent_id IS NULL',
        whereArgs: [sessionId],
        orderBy: 'sibling_order ASC, created_at ASC',
        limit: 1,
      );
      if (rootRows.isEmpty) {
        return null;
      }
      rootMessageId = rootRows.first['id'] as String;
    }

    return _resolveLeafFromNode(
      tx,
      sessionId: sessionId,
      startMessageId: rootMessageId,
    );
  }

  Future<String> _resolveLeafFromNode(
    DatabaseExecutor tx, {
    required String sessionId,
    required String startMessageId,
  }) async {
    var currentId = startMessageId;
    while (true) {
      final branchRows = await tx.query(
        'chat_branch_state',
        columns: ['active_child_message_id'],
        where: 'parent_message_id = ?',
        whereArgs: [currentId],
        limit: 1,
      );

      String? nextId = branchRows.isNotEmpty
          ? branchRows.first['active_child_message_id'] as String?
          : null;

      if (nextId == null) {
        final childRows = await tx.query(
          'chat_messages',
          columns: ['id'],
          where: 'session_id = ? AND parent_id = ?',
          whereArgs: [sessionId, currentId],
          orderBy: 'sibling_order ASC, created_at ASC',
          limit: 1,
        );
        if (childRows.isEmpty) {
          break;
        }
        nextId = childRows.first['id'] as String;
      }

      currentId = nextId;
    }
    return currentId;
  }

  Future<List<String>> _collectSubtreeIds(
    DatabaseExecutor tx,
    String messageId,
  ) async {
    final rows = await tx.rawQuery(
      '''
      WITH RECURSIVE subtree(id) AS (
        SELECT id FROM chat_messages WHERE id = ?
        UNION ALL
        SELECT chat_messages.id
        FROM chat_messages
        INNER JOIN subtree ON chat_messages.parent_id = subtree.id
      )
      SELECT id FROM subtree
      ''',
      [messageId],
    );
    return rows.map((row) => row['id'] as String).toList(growable: false);
  }

  Future<String?> _findPreferredChildAfterDelete(
    DatabaseExecutor tx, {
    required String sessionId,
    required String? parentMessageId,
  }) async {
    final rows = await tx.query(
      'chat_messages',
      columns: ['id'],
      where: parentMessageId == null
          ? 'session_id = ? AND parent_id IS NULL'
          : 'session_id = ? AND parent_id = ?',
      whereArgs: parentMessageId == null
          ? [sessionId]
          : [sessionId, parentMessageId],
      orderBy: 'sibling_order ASC, created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['id'] as String;
  }

  Future<String?> _loadMessageText(
    DatabaseExecutor tx,
    String messageId,
  ) async {
    final rows = await tx.query(
      'chat_messages',
      columns: ['text'],
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['text'] as String?;
  }

  /// 按 id 读取消息文本；消息不存在返回 null。
  ///
  /// 供后台子任务判断"消息文本与捕获时一致"的过期校验使用。
  Future<String?> loadMessageTextById(String messageId) async {
    return _loadMessageText(_db, messageId);
  }

  String _branchKey(String sessionId, String? parentMessageId) {
    return parentMessageId ?? _rootBranchKey(sessionId);
  }

  String _rootBranchKey(String sessionId) => 'root:$sessionId';

  String _generateId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    _idSequence = (_idSequence + 1) & 0x7fffffff;
    return '$prefix-$micros-$_idSequence';
  }

  Map<String, Object?> _sessionToMap(ChatSession session) {
    return {
      'id': session.id,
      'title': session.title,
      'character_id': session.characterId,
      'selected_user_setting_id': session.selectedUserSettingId,
      'selected_preset_id': session.selectedPresetId,
      'gal_mode_enabled': session.galModeEnabled ? 1 : 0,
      'current_leaf_message_id': session.currentLeafMessageId,
      'last_message_preview': session.lastMessagePreview,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
    };
  }

  ChatSession _sessionFromMap(
    Map<String, Object?> map,
    List<String> worldBookIds,
    List<String> regexRuleGroupIds,
  ) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      characterId: map['character_id'] as String,
      selectedUserSettingId: map['selected_user_setting_id'] as String?,
      selectedWorldBookIds: worldBookIds,
      selectedRegexRuleGroupIds: regexRuleGroupIds,
      selectedPresetId: map['selected_preset_id'] as String?,
      galModeEnabled: (map['gal_mode_enabled'] as int? ?? 0) == 1,
      currentLeafMessageId: map['current_leaf_message_id'] as String?,
      lastMessagePreview: map['last_message_preview'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ChatSessionSummary _summaryFromMap(Map<String, Object?> map) {
    return ChatSessionSummary(
      id: map['id'] as String,
      title: map['title'] as String,
      characterId: map['character_id'] as String,
      lastMessagePreview: map['last_message_preview'] as String? ?? '',
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> _nodeToMap(ChatNode node) {
    return {
      'id': node.id,
      'session_id': node.sessionId,
      'parent_id': node.parentId,
      'role': node.role.value,
      'text': node.text,
      'thinking_chain': node.thinkingChain,
      'created_at': node.createdAt.toIso8601String(),
      'sibling_order': node.siblingOrder,
    };
  }

  ChatNode _nodeFromMap(Map<String, Object?> map) {
    return ChatNode(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      parentId: map['parent_id'] as String?,
      role: ChatNodeRole.fromValue(map['role'] as String? ?? 'assistant'),
      text: map['text'] as String? ?? '',
      thinkingChain: map['thinking_chain'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      siblingOrder: map['sibling_order'] as int? ?? 0,
    );
  }

  Map<String, Object?> _memoryToMap(MemoryNode memory) {
    return {
      'id': memory.id,
      'session_id': memory.sessionId,
      'branch_leaf_id': memory.branchLeafId,
      'content': memory.content,
      'source_message_ids': _sourceMessageIdsToJson(memory.sourceMessageIds),
      'is_user_edited': memory.isUserEdited ? 1 : 0,
      'importance': memory.importance,
      'type': memory.type.name,
      'is_pinned': memory.isPinned ? 1 : 0,
      'created_at': memory.createdAt.toIso8601String(),
      'updated_at': memory.updatedAt.toIso8601String(),
    };
  }

  MemoryNode _memoryFromMap(Map<String, Object?> map) {
    return MemoryNode(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      branchLeafId: map['branch_leaf_id'] as String,
      content: map['content'] as String,
      sourceMessageIds: _sourceMessageIdsFromJson(
        map['source_message_ids'] as String? ?? '[]',
      ),
      isUserEdited: (map['is_user_edited'] as int? ?? 0) == 1,
      importance: (map['importance'] as int?) ?? 3,
      type: MemoryType.fromName(map['type'] as String?),
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> _memoryDiffToMap(MemoryDiff diff) {
    return {
      'id': diff.id,
      'session_id': diff.sessionId,
      'branch_leaf_id': diff.branchLeafId,
      'target_memory_id': diff.targetMemoryId,
      'kind': diff.kind.name,
      'content': diff.content,
      'importance': diff.importance,
      'type': diff.type?.name,
      'is_pinned': diff.isPinned == null ? null : (diff.isPinned! ? 1 : 0),
      'is_user_edited': diff.isUserEdited ? 1 : 0,
      'created_at': diff.createdAt.toIso8601String(),
    };
  }

  MemoryDiff _memoryDiffFromMap(Map<String, Object?> map) {
    return MemoryDiff(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      branchLeafId: map['branch_leaf_id'] as String,
      targetMemoryId: map['target_memory_id'] as String,
      kind: MemoryDiffKind.values.firstWhere(
        (kind) => kind.name == (map['kind'] as String?),
        orElse: () => MemoryDiffKind.update,
      ),
      content: map['content'] as String?,
      importance: map['importance'] as int?,
      type: map['type'] == null
          ? null
          : MemoryType.fromName(map['type'] as String?),
      isPinned: map['is_pinned'] == null
          ? null
          : (map['is_pinned'] as int?) == 1,
      isUserEdited: (map['is_user_edited'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> _extractionRunToMap(MemoryExtractionRun run) {
    return {
      'id': run.id,
      'session_id': run.sessionId,
      'branch_leaf_id': run.branchLeafId,
      'processed_message_ids': _sourceMessageIdsToJson(run.processedMessageIds),
      'status': run.status.name,
      'added_count': run.addedCount,
      'updated_count': run.updatedCount,
      'invalidated_count': run.invalidatedCount,
      'error_message': run.errorMessage,
      'character_name': run.characterName,
      'user_name': run.userName,
      'current_input': run.currentInput,
      'created_at': run.createdAt.toIso8601String(),
    };
  }

  MemoryExtractionRun _extractionRunFromMap(Map<String, Object?> map) {
    return MemoryExtractionRun(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      branchLeafId: map['branch_leaf_id'] as String,
      processedMessageIds: _sourceMessageIdsFromJson(
        map['processed_message_ids'] as String? ?? '[]',
      ),
      status: MemoryExtractionStatus.values.firstWhere(
        (status) => status.name == (map['status'] as String?),
        orElse: () => MemoryExtractionStatus.failed,
      ),
      addedCount: (map['added_count'] as int?) ?? 0,
      updatedCount: (map['updated_count'] as int?) ?? 0,
      invalidatedCount: (map['invalidated_count'] as int?) ?? 0,
      errorMessage: map['error_message'] as String? ?? '',
      characterName: map['character_name'] as String? ?? '',
      userName: map['user_name'] as String? ?? '',
      currentInput: map['current_input'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 提取落库时目标记忆与快照不一致（并发编辑）抛出的异常。
class MemoryExtractionConflict implements Exception {
  const MemoryExtractionConflict(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 提取结果所属的锚点记录已变化，迟到或重复提交应直接丢弃。
class MemoryExtractionSuperseded implements Exception {
  const MemoryExtractionSuperseded(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 同一时刻读取的提取上下文；列表防御拷贝，避免请求期间被调用方修改。
@immutable
class MemoryExtractionSnapshot {
  MemoryExtractionSnapshot({
    required List<MemoryNode> memories,
    required List<MemoryDiff> diffs,
    required List<String> pathMessageIds,
  }) : memories = List<MemoryNode>.unmodifiable(memories),
       diffs = List<MemoryDiff>.unmodifiable(diffs),
       pathMessageIds = List<String>.unmodifiable(pathMessageIds);

  final List<MemoryNode> memories;
  final List<MemoryDiff> diffs;
  final List<String> pathMessageIds;
}

/// 自动提取使用的目标记忆快照项：内容 + 重要度 + 类型 + 常驻。
///
/// 四者任一与提取开始时不一致即视为并发修改，避免后台提取覆盖用户的编辑。
typedef MemorySnapshotEntry = ({
  String content,
  int importance,
  MemoryType type,
  bool isPinned,
});

/// 直接改写原始记忆行时的一项更新（仅来源节点允许）。
typedef MemoryRowUpdate = ({
  String memoryId,
  String content,
  int importance,
  MemoryType type,
  bool isPinned,
});

/// 清除某节点上针对一条记忆的全部差量（「还原本节点改动」）。
typedef DiffClearTarget = ({String branchLeafId, String targetMemoryId});

String _sourceMessageIdsToJson(List<String> ids) => jsonEncode(ids);
List<String> _sourceMessageIdsFromJson(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  } catch (_) {}
  return [];
}

/// SQL `IN (...)` 单批最大占位符数，避免触及 SQLite 变量上限（旧版默认 999）。
const int _sqlInChunkSize = 500;

/// 把 [items] 按 [size] 切分为多个子列表，用于分批执行超长 `IN (...)` 语句。
Iterable<List<T>> _chunked<T>(List<T> items, int size) sync* {
  for (var i = 0; i < items.length; i += size) {
    final end = i + size < items.length ? i + size : items.length;
    yield items.sublist(i, end);
  }
}
