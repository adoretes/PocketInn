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
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static const int _dbVersion = 3;
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
  }

  Future<void> _createSchema(Database db) async {
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
        PRIMARY KEY (session_id, world_book_id),
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
  }

  Future<ChatSession> createSession({
    required String characterId,
    String? title,
    String? selectedUserSettingId,
    List<String> selectedWorldBookIds = const [],
    String? selectedPresetId,
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
      selectedPresetId: selectedPresetId,
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
    return _sessionFromMap(rows.first, worldBookIds);
  }

  Future<ChatSessionBundle?> loadSessionBundle(String id) async {
    final session = await loadSessionById(id);
    if (session == null) {
      return null;
    }
    final messages = await loadActivePathMessages(id);
    return ChatSessionBundle(session: session, activeMessages: messages);
  }

  Future<List<ChatSessionSummary>> loadSessionSummaries() async {
    final rows = await _db.query('chat_sessions', orderBy: 'updated_at DESC');
    return rows.map(_summaryFromMap).toList();
  }

  Future<void> updateSessionConfig({
    required String sessionId,
    required String? selectedUserSettingId,
    required List<String> selectedWorldBookIds,
    required String? selectedPresetId,
  }) async {
    await _db.transaction((tx) async {
      await tx.update(
        'chat_sessions',
        {
          'selected_user_setting_id': selectedUserSettingId,
          'selected_preset_id': selectedPresetId,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await _replaceSessionWorldBooks(
        tx,
        sessionId: sessionId,
        worldBookIds: selectedWorldBookIds,
      );
    });
    _notifyChanged();
  }

  Future<void> resetSession({
    required String sessionId,
    required String title,
    required String? selectedUserSettingId,
    required List<String> selectedWorldBookIds,
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

      final placeholders = List.filled(subtreeIds.length, '?').join(',');
      await tx.delete(
        'chat_branch_state',
        where:
            'parent_message_id IN ($placeholders) OR active_child_message_id IN ($placeholders)',
        whereArgs: [...subtreeIds, ...subtreeIds],
      );

      await tx.delete(
        'chat_memories',
        where: 'branch_leaf_id IN ($placeholders)',
        whereArgs: subtreeIds,
      );

      await tx.delete(
        'chat_messages',
        where: 'id IN ($placeholders)',
        whereArgs: subtreeIds,
      );

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

  Future<List<ChatMessage>> loadActivePathMessages(String sessionId) async {
    final session = await loadSessionById(sessionId);
    if (session == null) {
      return const [];
    }

    final leafId = await _resolveLeafForSession(_db, sessionId);
    if (leafId == null) {
      return const [];
    }

    final path = <ChatNode>[];
    String? currentId = leafId;
    while (currentId != null) {
      final rows = await _db.query(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [currentId],
        limit: 1,
      );
      if (rows.isEmpty) {
        break;
      }
      final node = _nodeFromMap(rows.first);
      path.add(node);
      currentId = node.parentId;
    }
    final orderedPath = path.reversed.toList(growable: false);

    final result = <ChatMessage>[];
    for (final node in orderedPath) {
      final siblings = await _db.query(
        'chat_messages',
        columns: ['id'],
        where: node.parentId == null
            ? 'session_id = ? AND parent_id IS NULL'
            : 'session_id = ? AND parent_id = ?',
        whereArgs: node.parentId == null
            ? [sessionId]
            : [sessionId, node.parentId],
        orderBy: 'sibling_order ASC, created_at ASC',
      );
      final siblingIds = siblings
          .map((row) => row['id'] as String)
          .toList(growable: false);
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
    final placeholders = List.filled(branchLeafIds.length, '?').join(',');
    final rows = await _db.query(
      'chat_memories',
      where: 'session_id = ? AND branch_leaf_id IN ($placeholders)',
      whereArgs: [sessionId, ...branchLeafIds],
      orderBy: 'created_at DESC',
    );
    return rows.map(_memoryFromMap).toList();
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
    _notifyChanged();
  }

  Future<void> insertMemoriesInTx(List<MemoryNode> memories) async {
    if (memories.isEmpty) return;
    await _db.transaction((tx) async {
      for (final m in memories) {
        await tx.insert('chat_memories', _memoryToMap(m));
      }
    });
    _notifyChanged();
  }

  Future<void> replaceBranchMemoriesInTx({
    required String sessionId,
    required String branchLeafId,
    required List<MemoryNode> memories,
  }) async {
    await _db.transaction((tx) async {
      await tx.delete(
        'chat_memories',
        where: 'session_id = ? AND branch_leaf_id = ?',
        whereArgs: [sessionId, branchLeafId],
      );
      for (final m in memories) {
        await tx.insert('chat_memories', _memoryToMap(m));
      }
    });
    _notifyChanged();
  }

  Future<void> updateMemoryContent({
    required String memoryId,
    required String content,
  }) async {
    await _db.update(
      'chat_memories',
      {
        'content': content,
        'is_user_edited': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [memoryId],
    );
    _notifyChanged();
  }

  Future<void> deleteMemory(String memoryId) async {
    await _db.delete('chat_memories', where: 'id = ?', whereArgs: [memoryId]);
    _notifyChanged();
  }

  void notifyDataChanged() {
    changeNotifier.value++;
  }

  void _notifyChanged() {
    notifyDataChanged();
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

  Future<String?> _resolveLeafForSession(
    DatabaseExecutor tx,
    String sessionId,
  ) async {
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

    final currentLeafId =
        sessionRows.first['current_leaf_message_id'] as String?;
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
      'current_leaf_message_id': session.currentLeafMessageId,
      'last_message_preview': session.lastMessagePreview,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
    };
  }

  ChatSession _sessionFromMap(
    Map<String, Object?> map,
    List<String> worldBookIds,
  ) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      characterId: map['character_id'] as String,
      selectedUserSettingId: map['selected_user_setting_id'] as String?,
      selectedWorldBookIds: worldBookIds,
      selectedPresetId: map['selected_preset_id'] as String?,
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
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

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
