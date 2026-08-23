import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/variable_state_service.dart';

import 'helpers/test_env.dart';

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

  VariableState initState() {
    return VariableState.fromVariables({
      '好感度': const ChatVariable(
        name: '好感度',
        type: ChatVariableType.number,
        value: '0',
        metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
      ),
    });
  }

  test('diff 沿路径折叠，includeSelf 控制是否含目标消息自身', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.saveInitState(session.id, initState());

    final openingId = session.currentLeafMessageId!;
    final user = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: openingId,
      text: '你好',
    );
    final assistant = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '回复',
    );
    await service.writeDiff(
      messageId: assistant.id,
      ops: [
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '5',
        ),
      ],
    );

    Future<int> favor(String? messageId, {bool includeSelf = true}) async {
      final state = await service.resolveState(
        sessionId: session.id,
        messageId: messageId,
        includeSelf: includeSelf,
      );
      return int.parse(state['好感度']?.value ?? '-1');
    }

    expect(await favor(null), 0, reason: '无消息时只剩初始变量');
    expect(await favor(openingId), 0);
    expect(await favor(user.id), 0, reason: '用户消息不含其后回复的 diff');
    expect(await favor(assistant.id), 5);
    expect(
      await favor(assistant.id, includeSelf: false),
      0,
      reason: '求值到该消息发生之前的状态（提取调用的分支点快照）',
    );
  });

  test('gal 回复历史：新分支取分支点时刻的状态', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.saveInitState(session.id, initState());

    // 原分支：user1 → asst1(+5) → user2 → asst2(+10)
    final user1 = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: session.currentLeafMessageId,
      text: '第一轮',
    );
    final asst1 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user1.id,
      text: '第一轮回复',
    );
    await service.writeDiff(
      messageId: asst1.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '5'),
      ],
    );
    final user2 = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: asst1.id,
      text: '第二轮',
    );
    final asst2 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user2.id,
      text: '第二轮回复',
    );
    await service.writeDiff(
      messageId: asst2.id,
      ops: [
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '10',
        ),
      ],
    );

    // gal 回复历史：回到 asst1 处开新分支 user3 → asst3(+3)。
    final user3 = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: asst1.id,
      text: '改走另一条线',
    );
    final asst3 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user3.id,
      text: '另一条线的回复',
    );
    await service.writeDiff(
      messageId: asst3.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '3'),
      ],
    );

    Future<String> favorAt(String messageId) async {
      final state = await service.resolveState(
        sessionId: session.id,
        messageId: messageId,
      );
      return state['好感度']?.value ?? '';
    }

    expect(await favorAt(asst2.id), '15', reason: '旧分支叶含两轮 diff');
    expect(
      await favorAt(asst3.id),
      '8',
      reason: '新分支从分支点 asst1(+5) 出发，不得混入旧分支的 +10',
    );
  });

  test('重新生成的兄弟版本互不污染', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.saveInitState(session.id, initState());

    final user = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: session.currentLeafMessageId,
      text: '你好',
    );
    final v1 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '版本一',
    );
    await service.writeDiff(
      messageId: v1.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '5'),
      ],
    );
    final v2 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '版本二',
    );
    await service.writeDiff(
      messageId: v2.id,
      ops: [
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '10',
        ),
      ],
    );

    Future<String> favorAt(String messageId) async {
      final state = await service.resolveState(
        sessionId: session.id,
        messageId: messageId,
      );
      return state['好感度']?.value ?? '';
    }

    expect(await favorAt(v1.id), '5');
    expect(await favorAt(v2.id), '10');

    // 切回版本一：激活路径变化后重新求值，旧版本的 diff 不参与。
    await db.switchActiveBranch(
      sessionId: session.id,
      parentMessageId: user.id,
      childMessageId: v1.id,
    );
    final bundle = await db.loadSessionBundle(session.id);
    expect(bundle!.session.currentLeafMessageId, v1.id);
    expect(await favorAt(bundle.session.currentLeafMessageId!), '5');
  });

  test('删除分支级联清理其 diff', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.saveInitState(session.id, initState());

    final user = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: session.currentLeafMessageId,
      text: '你好',
    );
    final v1 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '版本一',
    );
    await service.writeDiff(
      messageId: v1.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '5'),
      ],
    );
    final v2 = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '版本二',
    );
    await service.writeDiff(
      messageId: v2.id,
      ops: [
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '10',
        ),
      ],
    );

    await db.deleteMessageBranch(sessionId: session.id, messageId: v2.id);

    expect(await service.readDiff(v2.id), isEmpty, reason: 'diff 随消息级联删除');
    expect(await service.readDiff(v1.id), isNotEmpty);

    // 删除后激活叶子回到版本一，状态回退。
    final state = await service.resolveState(
      sessionId: session.id,
      messageId: v1.id,
    );
    expect(state['好感度']?.value, '5');
  });

  test('resetSession 后状态回到初始', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.saveInitState(session.id, initState());

    final user = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: session.currentLeafMessageId,
      text: '你好',
    );
    final assistant = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: '回复',
    );
    await service.writeDiff(
      messageId: assistant.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '7'),
      ],
    );

    await db.resetSession(
      sessionId: session.id,
      title: session.title,
      selectedUserSettingId: null,
      selectedWorldBookIds: const [],
      selectedRegexRuleGroupIds: const [],
      selectedPresetId: null,
      openingAssistantMessages: ['新的开场白'],
    );

    final bundle = await db.loadSessionBundle(session.id);
    final state = await service.resolveState(
      sessionId: session.id,
      messageId: bundle!.session.currentLeafMessageId,
    );
    expect(state['好感度']?.value, '0', reason: '重置后回到初始变量');
    expect(await service.readDiff(assistant.id), isEmpty);
  });

  test('变量写入不广播 DB 变化（避免会话重载清掉 gal 选项等瞬态 UI）', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );

    final assistant = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: session.currentLeafMessageId,
      text: '回复',
    );

    // 基线取在消息写入之后：只断言变量操作本身不广播。
    final notifyCountBefore = db.changeNotifier.value;
    await service.saveInitState(session.id, initState());
    await service.writeDiff(
      messageId: assistant.id,
      ops: [
        const VariableOp(kind: VariableOpKind.add, variable: '好感度', value: '5'),
      ],
    );
    await service.clearDiff(assistant.id);

    expect(
      db.changeNotifier.value,
      notifyCountBefore,
      reason: '变量 init/diff 的写入与删除都不应触发 changeNotifier',
    );
  });

  test('applyCardInit：正式开聊应用角色卡声明，重置时覆盖旧值', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );

    Map<String, Object?> cardWith(String name, String value) => {
      'data': {
        'extensions': {
          'variables': {
            name: {'type': 'number', 'value': value, 'max': 100},
          },
        },
      },
    };

    // 正式开始聊天：应用角色卡声明。
    await service.applyCardInit(
      sessionId: session.id,
      cardJson: cardWith('好感度', '0'),
    );
    var state = await service.resolveState(sessionId: session.id);
    expect(state['好感度']?.value, '0');
    expect(state['好感度']?.metadata?.maxValue, 100);

    // 角色卡声明被修改后重置聊天：初始值按新卡覆盖。
    await service.applyCardInit(
      sessionId: session.id,
      cardJson: cardWith('好感度', '20'),
    );
    state = await service.resolveState(sessionId: session.id);
    expect(state['好感度']?.value, '20');

    // 角色卡移除声明后重置：初始状态清空，系统回到未启用。
    await service.applyCardInit(sessionId: session.id, cardJson: {});
    state = await service.resolveState(sessionId: session.id);
    expect(state.isEmpty, isTrue);
  });

  test('ensureCardInit：旧会话仅在无记录且卡有声明时补写一次', () async {
    final db = ChatDatabaseService.instance;
    final service = VariableStateService.instance;
    final session = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    final card = {
      'data': {
        'extensions': {
          'variables': {
            '金币': {'type': 'number', 'value': '50'},
          },
        },
      },
    };

    await service.ensureCardInit(sessionId: session.id, cardJson: card);
    expect((await service.loadInitState(session.id))['金币']?.value, '50');

    // 第二次调用（卡值已变）不得覆盖已存在的记录。
    await service.ensureCardInit(
      sessionId: session.id,
      cardJson: {
        'data': {
          'extensions': {
            'variables': {
              '金币': {'type': 'number', 'value': '999'},
            },
          },
        },
      },
    );
    expect((await service.loadInitState(session.id))['金币']?.value, '50');

    // 卡未声明变量时不写入记录。
    final other = await db.createSession(
      characterId: 'char-1',
      openingAssistantMessages: ['开场白'],
    );
    await service.ensureCardInit(sessionId: other.id, cardJson: {});
    expect(
      await db.loadVariableInit(other.id),
      isNull,
      reason: '无声明的旧会话不应产生空的初始变量记录',
    );
  });

  test('v5 旧库升级 v6 后变量表可用', () async {
    final service = ChatDatabaseService.instance;
    await service.deleteDatabaseFiles();

    // 以 v5 schema（无变量表）建库并写入一条旧会话，模拟升级前遗留库。
    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'pocket_inn_data', 'pocket_inn_chat.db');
    Directory(p.dirname(dbPath)).createSync(recursive: true);
    final raw = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 5,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
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

    // 服务初始化触发 v5 -> v6 迁移。
    await service.initialize();

    final init = await VariableStateService.instance.loadInitState('legacy-1');
    expect(init.isEmpty, isTrue, reason: '旧会话无初始变量，优雅回落');

    await VariableStateService.instance.saveInitState('legacy-1', initState());
    final restored = await VariableStateService.instance.loadInitState(
      'legacy-1',
    );
    expect(restored['好感度']?.value, '0');
    expect(restored['好感度']?.metadata?.maxValue, 100);
  });
}
