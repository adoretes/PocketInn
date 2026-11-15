import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_memory_service.dart';
import 'package:pocket_inn/services/chat_variable_service.dart';

import 'helpers/test_env.dart';

ChatMessage _user(String text) => ChatMessage(text: text, isMe: true);

ChatMessage _assistant(String text) => ChatMessage(text: text, isMe: false);

MemoryNode _memory({
  required String id,
  required String branchLeafId,
  required String content,
  required DateTime createdAt,
  List<String> sourceMessageIds = const [],
  bool isUserEdited = false,
  int importance = 3,
}) {
  return MemoryNode(
    id: id,
    sessionId: 's1',
    branchLeafId: branchLeafId,
    content: content,
    sourceMessageIds: sourceMessageIds,
    isUserEdited: isUserEdited,
    importance: importance,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('ChatMemoryService.truncateToRecentRounds', () {
    test('recentRounds <= 0 返回原列表', () {
      final messages = [_user('a'), _assistant('b')];
      expect(
        ChatMemoryService.truncateToRecentRounds(messages, 0),
        same(messages),
      );
      expect(
        ChatMemoryService.truncateToRecentRounds(messages, -1),
        same(messages),
      );
    });

    test('消息数不足 N 轮时返回原列表', () {
      final messages = [_user('u1'), _assistant('a1')];
      expect(
        ChatMemoryService.truncateToRecentRounds(messages, 2),
        same(messages),
      );
    });

    test('消息数恰好等于 N 轮时返回原列表', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
      ];
      expect(
        ChatMemoryService.truncateToRecentRounds(messages, 2),
        same(messages),
      );
    });

    test('消息数大于 N 轮时截断为最后 N 轮（含前导用户消息）', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
        _user('u3'),
        _assistant('a3'),
      ];
      final result = ChatMemoryService.truncateToRecentRounds(messages, 2);
      expect(result.map((m) => m.text), ['u2', 'a2', 'u3', 'a3']);
    });

    test('末尾用户消息未获回复时仍按助手计数截断', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
        _user('u3'),
      ];
      final result = ChatMemoryService.truncateToRecentRounds(messages, 1);
      expect(result.map((m) => m.text), ['u2', 'a2', 'u3']);
    });

    test('连续助手消息时正确处理前导用户消息', () {
      final messages = [_user('u1'), _assistant('a1'), _assistant('a2')];
      final result = ChatMemoryService.truncateToRecentRounds(messages, 2);
      expect(result.map((m) => m.text), ['u1', 'a1', 'a2']);
    });
  });

  group('ChatMemoryService.messagesBeforeWindow', () {
    test('recentRounds <= 0（无限制）返回空表', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
      ];
      expect(ChatMemoryService.messagesBeforeWindow(messages, 0), isEmpty);
      expect(ChatMemoryService.messagesBeforeWindow(messages, -1), isEmpty);
    });

    test('历史不足以截断时返回空表', () {
      final messages = [_user('u1'), _assistant('a1')];
      expect(ChatMemoryService.messagesBeforeWindow(messages, 2), isEmpty);
    });

    test('返回被裁掉的窗口之前消息', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
        _user('u3'),
        _assistant('a3'),
      ];
      final result = ChatMemoryService.messagesBeforeWindow(messages, 2);
      expect(result.map((m) => m.text), ['u1', 'a1']);
    });

    test('末尾用户消息未获回复时也正确切分', () {
      final messages = [
        _user('u1'),
        _assistant('a1'),
        _user('u2'),
        _assistant('a2'),
        _user('u3'),
      ];
      final result = ChatMemoryService.messagesBeforeWindow(messages, 1);
      expect(result.map((m) => m.text), ['u1', 'a1']);
    });
  });

  group('ChatMemoryService.parseMemoryPoints', () {
    test('空字符串返回空列表', () {
      expect(ChatMemoryService.parseMemoryPoints(''), isEmpty);
    });

    test('识别 -、*、• 三种前缀并支持混用', () {
      final text = '- 第一条\n* 第二条\n• 第三条';
      expect(ChatMemoryService.parseMemoryPoints(text), ['第一条', '第二条', '第三条']);
    });

    test('纯空白行被跳过', () {
      final text = '- 第一条\n\n   \n- 第二条';
      expect(ChatMemoryService.parseMemoryPoints(text), ['第一条', '第二条']);
    });

    test('无前缀行被跳过', () {
      final text = '- 第一条\n这是普通文本\n- 第二条';
      expect(ChatMemoryService.parseMemoryPoints(text), ['第一条', '第二条']);
    });

    test('前缀后内容为空被跳过', () {
      final text = '- \n-   \n- 第一条';
      expect(ChatMemoryService.parseMemoryPoints(text), ['第一条']);
    });

    test('前缀后内容包含前导空白被裁剪', () {
      expect(ChatMemoryService.parseMemoryPoints('-    缩进内容'), ['缩进内容']);
    });
  });


  group('MemoryExtractionConfig.copyWith', () {
    test('不传参数时两个可空字段保持原值', () {
      const config = MemoryExtractionConfig(
        extractionModelId: 'model-1',
        customExtractionPrompt: '原提示词',
      );
      final next = config.copyWith();
      expect(next.extractionModelId, 'model-1');
      expect(next.customExtractionPrompt, '原提示词');
    });

    test('显式传值覆盖原值，传 null/空串表示清空', () {
      const config = MemoryExtractionConfig(
        extractionModelId: 'model-1',
        customExtractionPrompt: '原提示词',
      );

      final cleared = config.copyWith(
        extractionModelId: null,
        customExtractionPrompt: '',
      );
      expect(cleared.extractionModelId, isNull);
      expect(cleared.customExtractionPrompt, '');

      final replaced = config.copyWith(
        extractionModelId: 'model-2',
        customExtractionPrompt: '新提示词',
      );
      expect(replaced.extractionModelId, 'model-2');
      expect(replaced.customExtractionPrompt, '新提示词');
    });

    test('普通字段透传', () {
      const config = MemoryExtractionConfig(
        enabled: false,
        interval: 5,
        recentRounds: 10,
        recallCount: 3,
      );
      final next = config.copyWith(
        enabled: true,
        interval: 8,
        recentRounds: 4,
        recallCount: 6,
      );
      expect(next.enabled, isTrue);
      expect(next.interval, 8);
      expect(next.recentRounds, 4);
      expect(next.recallCount, 6);
    });
  });

  group('ChatMemoryService.formatMemoryContext', () {
    test('空列表返回空字符串', () {
      expect(ChatMemoryService.formatMemoryContext(<String>[]), '');
    });

    test('使用默认 header 格式化记忆列表', () {
      // 注意：formatMemoryContext 依赖全局 memoryExtractionNotifier.value，
      // 测试环境下 notifier 为默认配置（customInjectionPrompt 为空），
      // 故使用默认 header。
      const expectedHeader = '以下是角色记得的关于过去事件的信息：';
      final result = ChatMemoryService.formatMemoryContext(['记忆A', '记忆B']);
      expect(result, '$expectedHeader\n- 记忆A\n- 记忆B');
    });
  });

  group('ChatMemoryService.formatMemoryList', () {
    test('空列表返回空字符串', () {
      expect(ChatMemoryService.formatMemoryList(<String>[]), '');
    });

    test('仅渲染条目，不含引导语表头', () {
      expect(ChatMemoryService.formatMemoryList(['A', 'B']), '- A\n- B');
    });
  });

  group('ChatVariableService {{memory}} 宏', () {
    PromptMacroState state({required bool withHeader}) => PromptMacroState(
      characterName: '角色',
      userName: '用户',
      memoryContext: const ['记忆A'],
      memoryContextWithHeader: withHeader,
    );

    test('memoryContextWithHeader=true 时带引导语表头（主聊天注入）', () {
      expect(
        ChatVariableService.resolveMacros(
          '{{memory}}',
          state: state(withHeader: true),
        ),
        '以下是角色记得的关于过去事件的信息：\n- 记忆A',
      );
    });

    test('memoryContextWithHeader=false 时为纯列表（提取场景）', () {
      expect(
        ChatVariableService.resolveMacros(
          '{{memory}}',
          state: state(withHeader: false),
        ),
        '- 记忆A',
      );
    });
  });

  group('ChatMemoryService 分支求值 resolveFromData', () {
    const path = ['n1', 'n2', 'n3', 'n4', 'n5'];
    final baseTime = DateTime(2026, 1, 1);

    test('无记忆返回空', () {
      expect(
        ChatMemoryService.resolveFromData(
          memories: const [],
          diffs: const [],
          pathMessageIds: path,
        ),
        isEmpty,
      );
    });

    test('update 差量改写内容与重要度，并按分支顺序输出', () {
      final memories = [
        _memory(id: 'm1', branchLeafId: 'n1', content: '旧内容', createdAt: baseTime),
        _memory(id: 'm2', branchLeafId: 'n3', content: '第二条', createdAt: baseTime.add(const Duration(minutes: 1))),
      ];
      final diffs = [
        MemoryDiff(
          id: 'd1',
          sessionId: 's1',
          branchLeafId: 'n4',
          targetMemoryId: 'm1',
          kind: MemoryDiffKind.update,
          content: '新内容',
          importance: 5,
          createdAt: baseTime.add(const Duration(minutes: 2)),
        ),
      ];
      final result = ChatMemoryService.resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
      );
      expect(result.map((m) => m.content), ['新内容', '第二条']);
      expect(result.first.importance, 5);
    });

    test('invalidate 差量使记忆失效，默认不返回', () {
      final memories = [
        _memory(id: 'm1', branchLeafId: 'n1', content: 'a', createdAt: baseTime),
      ];
      final diffs = [
        MemoryDiff(
          id: 'd1',
          sessionId: 's1',
          branchLeafId: 'n3',
          targetMemoryId: 'm1',
          kind: MemoryDiffKind.invalidate,
          createdAt: baseTime.add(const Duration(minutes: 1)),
        ),
      ];
      final hidden = ChatMemoryService.resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
      );
      expect(hidden, isEmpty);
      final shown = ChatMemoryService.resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
        includeInvalidated: true,
      );
      expect(shown.single.invalidated, isTrue);
    });

    test('restore 差量撤销失效', () {
      final memories = [
        _memory(id: 'm1', branchLeafId: 'n1', content: 'a', createdAt: baseTime),
      ];
      final diffs = [
        MemoryDiff(
          id: 'd1',
          sessionId: 's1',
          branchLeafId: 'n3',
          targetMemoryId: 'm1',
          kind: MemoryDiffKind.invalidate,
          createdAt: baseTime.add(const Duration(minutes: 1)),
        ),
        MemoryDiff(
          id: 'd2',
          sessionId: 's1',
          branchLeafId: 'n4',
          targetMemoryId: 'm1',
          kind: MemoryDiffKind.restore,
          createdAt: baseTime.add(const Duration(minutes: 2)),
        ),
      ];
      final result = ChatMemoryService.resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
      );
      expect(result.single.content, 'a');
      expect(result.single.invalidated, isFalse);
    });

    test('路径之外的差量不影响当前分支（兄弟分支隔离）', () {
      final memories = [
        _memory(id: 'm1', branchLeafId: 'n1', content: '原值', createdAt: baseTime),
      ];
      final diffs = [
        // 该差量位于不在当前路径上的 nX 分支。
        MemoryDiff(
          id: 'd1',
          sessionId: 's1',
          branchLeafId: 'nX',
          targetMemoryId: 'm1',
          kind: MemoryDiffKind.update,
          content: '兄弟分支的修改',
          createdAt: baseTime.add(const Duration(minutes: 1)),
        ),
      ];
      final result = ChatMemoryService.resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: path,
      );
      expect(result.single.content, '原值');
    });
  });

  group('ChatMemoryService.rankMemories', () {
    const path = ['n1', 'n2', 'n3', 'n4', 'n5'];
    final baseTime = DateTime(2026, 1, 1);

    ResolvedMemory resolved(
      String node,
      String content, {
      int importance = 3,
      bool isPinned = false,
    }) {
      return ResolvedMemory(
        origin: _memory(
          id: '$node-$content',
          branchLeafId: node,
          content: content,
          createdAt: baseTime,
        ),
        content: content,
        importance: importance,
        invalidated: false,
        isPinned: isPinned,
      );
    }

    test('高相关旧记忆胜过低相关新记忆', () {
      final all = [
        resolved('n1', '用户喜欢雨天散步'),
        resolved('n5', '用户讨厌噪音'),
      ];
      final result = ChatMemoryService.rankMemories(
        all: all,
        pathMessageIds: path,
        query: '今天雨天想出去',
        count: 1,
      );
      expect(result.single.content, '用户喜欢雨天散步');
    });

    test('空查询时重要度更高的记忆优先', () {
      final all = [
        resolved('n1', '重要设定', importance: 5),
        resolved('n5', '琐碎小事', importance: 1),
      ];
      final result = ChatMemoryService.rankMemories(
        all: all,
        pathMessageIds: path,
        query: '',
        count: 1,
      );
      expect(result.single.content, '重要设定');
    });

    test('count <= 0 视为不限制，并按分支顺序输出', () {
      final all = [
        resolved('n3', 'c'),
        resolved('n1', 'a'),
        resolved('n5', 'e'),
      ];
      final result = ChatMemoryService.rankMemories(
        all: all,
        pathMessageIds: path,
        query: '',
        count: 0,
      );
      expect(result.map((m) => m.content), ['a', 'c', 'e']);
    });

    test('常驻记忆无条件入选且不占用召回额度', () {
      final all = [
        resolved('n1', '常驻设定', importance: 1, isPinned: true),
        resolved('n5', '普通A', importance: 3),
        resolved('n3', '普通B', importance: 3),
      ];
      final result = ChatMemoryService.rankMemories(
        all: all,
        pathMessageIds: path,
        query: '',
        count: 1,
      );
      expect(result.length, 2, reason: '1 条常驻 + 1 条普通');
      expect(result.any((m) => m.content == '常驻设定'), isTrue);
    });

    test('同分时结果稳定（确定性）', () {
      final all = [
        resolved('n2', 'b', importance: 3),
        resolved('n4', 'd', importance: 3),
      ];
      final first = ChatMemoryService.rankMemories(
        all: all,
        pathMessageIds: path,
        query: '',
        count: 2,
      );
      final second = ChatMemoryService.rankMemories(
        all: all.reversed.toList(),
        pathMessageIds: path,
        query: '',
        count: 2,
      );
      expect(first.map((m) => m.content), second.map((m) => m.content));
    });
  });

  group('ChatMemoryService.parseMemoryOps', () {
    test('解析 JSON ops', () {
      final ops = ChatMemoryService.parseMemoryOps(
        '{"ops":[{"op":"add","content":"喜欢猫","importance":4},'
        '{"op":"update","id":"m1","content":"改名","importance":5},'
        '{"op":"invalidate","id":"m2"}]}',
      );
      expect(ops, isNotNull);
      expect(ops!.length, 3);
      expect(ops[0].kind, MemoryOpKind.add);
      expect(ops[0].content, '喜欢猫');
      expect(ops[0].importance, 4);
      expect(ops[1].kind, MemoryOpKind.update);
      expect(ops[1].id, 'm1');
      expect(ops[2].kind, MemoryOpKind.invalidate);
    });

    test('容忍 Markdown 围栏', () {
      final ops = ChatMemoryService.parseMemoryOps(
        '```json\n{"ops":[{"op":"add","content":"x"}]}\n```',
      );
      expect(ops!.single.kind, MemoryOpKind.add);
    });

    test('合法空操作返回空列表（无变化）', () {
      expect(ChatMemoryService.parseMemoryOps('{"ops":[]}'), isEmpty);
    });

    test('无法解析返回 null', () {
      expect(ChatMemoryService.parseMemoryOps('模型抽风了'), isNull);
      expect(ChatMemoryService.parseMemoryOps(''), isNull);
    });

    test('旧协议逐行列表回退为 add', () {
      final ops = ChatMemoryService.parseMemoryOps('- 记忆一\n- 记忆二');
      expect(ops!.map((o) => o.content), ['记忆一', '记忆二']);
    });

    test('解析 type 与 isPinned', () {
      final ops = ChatMemoryService.parseMemoryOps(
        '{"ops":[{"op":"add","content":"x","type":"preference","isPinned":true},'
        '{"op":"update","id":"m1","type":"关系","isPinned":"false"}]}',
      );
      expect(ops, isNotNull);
      expect(ops![0].type, MemoryType.preference);
      expect(ops[0].isPinned, isTrue);
      expect(ops[1].type, MemoryType.relationship);
      expect(ops[1].isPinned, isFalse);
    });

    test('update/invalidate 缺少 id 的条目被丢弃', () {
      final ops = ChatMemoryService.parseMemoryOps(
        '{"ops":[{"op":"update","content":"x"},{"op":"invalidate"}]}',
      );
      expect(ops, isEmpty);
    });
  });

  group('ChatMemoryService 提取水位线', () {
    MemoryExtractionRun run(String anchor, List<String> processed) {
      return MemoryExtractionRun(
        id: 'run-$anchor',
        sessionId: 's1',
        branchLeafId: anchor,
        processedMessageIds: processed,
        status: MemoryExtractionStatus.applied,
        createdAt: DateTime(2026),
      );
    }

    test('processedMessageIds 返回所有运行记录处理消息的并集', () {
      final runs = [run('a1', ['u1', 'a1']), run('a2', ['u2', 'a2'])];
      expect(
        ChatMemoryService.processedMessageIds(runs),
        {'u1', 'a1', 'u2', 'a2'},
      );
    });

    test('无运行记录时统计全部角色消息', () {
      final all = [
        ChatMessage(id: 'u1', text: 'u1', isMe: true),
        ChatMessage(id: 'a1', text: 'a1', isMe: false),
        ChatMessage(id: 'u2', text: 'u2', isMe: true),
        ChatMessage(id: 'a2', text: 'a2', isMe: false),
      ];
      expect(
        ChatMemoryService.countNewAssistantMessages(
          allMessages: all,
          runs: const [],
        ),
        2,
      );
    });

    test('「无值得记忆」的空运行同样推进水位，不再每轮重提', () {
      final all = [
        ChatMessage(id: 'u1', text: 'u1', isMe: true),
        ChatMessage(id: 'a1', text: 'a1', isMe: false),
      ];
      final runs = [
        MemoryExtractionRun(
          id: 'run-a1',
          sessionId: 's1',
          branchLeafId: 'a1',
          processedMessageIds: const ['u1', 'a1'],
          status: MemoryExtractionStatus.empty,
          createdAt: DateTime(2026),
        ),
      ];
      expect(
        ChatMemoryService.countNewAssistantMessages(
          allMessages: all,
          runs: runs,
        ),
        0,
      );
    });

    test('旧数据无运行记录时回退到记忆来源，避免历史重提', () {
      final all = [
        ChatMessage(id: 'u1', text: 'u1', isMe: true),
        ChatMessage(id: 'a1', text: 'a1', isMe: false),
        ChatMessage(id: 'u2', text: 'u2', isMe: true),
        ChatMessage(id: 'a2', text: 'a2', isMe: false),
      ];
      final memories = [
        _memory(
          id: 'm-auto',
          branchLeafId: 'a1',
          content: 'auto',
          createdAt: DateTime(2026),
          sourceMessageIds: const ['u1', 'a1'],
        ),
      ];
      expect(
        ChatMemoryService.countNewAssistantMessages(
          allMessages: all,
          runs: const [],
          memories: memories,
        ),
        1,
      );
    });
  });

  group('记忆写入的变更广播', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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

    test('记忆写入不触发聊天数据广播，只广播记忆变更', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final leafId = session.currentLeafMessageId!;

      // 基线取在会话创建之后：只断言记忆操作本身不广播。
      final chatNotifyBefore = db.changeNotifier.value;
      final memoryNotifyBefore = db.memoryChangeNotifier.value;

      await service.addMemory(
        sessionId: session.id,
        branchLeafId: leafId,
        content: '喜欢雨天',
      );
      expect(
        db.changeNotifier.value,
        chatNotifyBefore,
        reason: '新增记忆不应触发聊天页重载',
      );
      expect(db.memoryChangeNotifier.value, memoryNotifyBefore + 1);

      final second = await service.addMemory(
        sessionId: session.id,
        branchLeafId: leafId,
        content: '讨厌噪音',
      );
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: leafId,
        memoryId: second.id,
        content: '非常讨厌噪音',
        importance: 4,
      );
      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: leafId,
      );
      expect(resolved.length, 2);
      expect(resolved.any((m) => m.content == '非常讨厌噪音'), isTrue);
      expect(
        db.changeNotifier.value,
        chatNotifyBefore,
        reason: '编辑记忆不应触发聊天页重载',
      );

      await service.invalidateMemory(
        sessionId: session.id,
        atMessageId: leafId,
        memoryId: second.id,
      );
      final afterInvalidate = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: leafId,
      );
      expect(afterInvalidate.length, 1, reason: '失效记忆不应再出现在求值结果里');

      // 空批量写入什么都不改，不应广播。
      final memoryNotifyAfterEdit = db.memoryChangeNotifier.value;
      await db.insertMemoriesInTx(const []);
      expect(db.memoryChangeNotifier.value, memoryNotifyAfterEdit);
    });
  });

  group('记忆分支落库', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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

    test('后代 update 差量不回写祖先时刻；删除来源记忆级联清理差量', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final rootAssistant = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: rootAssistant,
        text: '你好',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: '回复',
      );

      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: rootAssistant,
        content: '原值',
      );
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
        content: '新值',
        importance: 4,
      );

      final atAssistant = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(atAssistant.single.content, '新值');
      expect(atAssistant.single.importance, 4);

      // 祖先时刻（同一条记忆的来源节点）不受后代 diff 影响。
      final atRoot = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: rootAssistant,
      );
      expect(atRoot.single.content, '原值');

      // 物理删除来源记忆：差量随外键级联清理，后代分支也不再见。
      await service.deleteMemoryAtOrigin(
        sessionId: session.id,
        memoryId: memory.id,
      );
      expect(
        await db.loadAllSessionMemoryDiffs(session.id),
        isEmpty,
        reason: '删除来源记忆应级联清理其差量',
      );
      expect(
        await service.resolveMemoriesAtMessage(
          sessionId: session.id,
          messageId: assistant.id,
        ),
        isEmpty,
      );
    });

    test('失效后仍可被查到并可恢复，避免停用后彻底失联', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final rootAssistant = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: rootAssistant,
        text: '你好',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: '回复',
      );
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: rootAssistant,
        content: '重要设定',
      );

      await service.invalidateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
      );
      expect(
        await service.resolveMemoriesAtMessage(
          sessionId: session.id,
          messageId: assistant.id,
        ),
        isEmpty,
        reason: '失效记忆不进入默认结果',
      );
      final withInvalid = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
        includeInvalidated: true,
      );
      expect(withInvalid.single.invalidated, isTrue);

      // 用户点击「恢复」。
      await service.restoreMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
      );
      final restored = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(restored.single.content, '重要设定');
    });

    test('类型与常驻标记可写入并通过差量求值', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final rootAssistant = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: rootAssistant,
        text: '你好',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: '回复',
      );
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: rootAssistant,
        content: '设定',
        type: MemoryType.setting,
      );
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
        content: '设定',
        importance: 4,
        type: MemoryType.commitment,
        isPinned: true,
      );
      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(resolved.single.type, MemoryType.commitment);
      expect(resolved.single.isPinned, isTrue);
      expect(resolved.single.importance, 4);
    });

    test('可清除某节点的编辑改动，使记忆回退到祖先状态', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final rootAssistant = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: rootAssistant,
        text: '你好',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: '回复',
      );
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: rootAssistant,
        content: 'A',
      );

      await service.updateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
        content: 'B',
        importance: 5,
      );
      expect(
        (await service.resolveMemoriesAtMessage(
          sessionId: session.id,
          messageId: assistant.id,
        ))
            .single
            .content,
        'B',
      );
      expect(
        await db.loadMemoryDiffTargetsAtNode(
          sessionId: session.id,
          branchLeafId: assistant.id,
        ),
        {memory.id},
        reason: '本节点应记录到对这条记忆的改动',
      );

      // 还原本节点改动：只删该节点差量，回到祖先的 A。
      await service.clearMemoryEditsAtNode(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
      );
      final reverted = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(reverted.single.content, 'A');
      expect(reverted.single.importance, 3);
      expect(
        await db.loadMemoryDiffTargetsAtNode(
          sessionId: session.id,
          branchLeafId: assistant.id,
        ),
        isEmpty,
      );
    });
  });

  group('记忆提取快照与分支差量', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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

    test('快照取 origin 原始值：记忆已有分支 update 时提取更新不再误报冲突', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;
      final u1 = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: root,
        text: 'u1',
      );
      final a1 = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: u1.id,
        text: 'a1',
      );
      final u2 = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: a1.id,
        text: 'u2',
      );
      final a2 = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: u2.id,
        text: 'a2',
      );

      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: root,
        content: 'A',
        importance: 3,
      );
      // 首次（类自动提取）在后代节点写入 update 差量：原始行仍是 A/3，折叠后为 B/4。
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: a1.id,
        memoryId: memory.id,
        content: 'B',
        importance: 4,
      );

      final folded = (await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: a2.id,
      ))
          .single;
      expect(folded.content, 'B');

      Future<void> apply({
        required String content,
        required int importance,
      }) {
        return db.applyMemoryExtractionTx(
          newMemories: const [],
          diffs: [
            MemoryDiff(
              id: 'memdiff-next',
              sessionId: session.id,
              branchLeafId: a2.id,
              targetMemoryId: memory.id,
              kind: MemoryDiffKind.update,
              content: content,
              importance: importance,
              createdAt: DateTime.now(),
            ),
          ],
          run: MemoryExtractionRun(
            id: 'memrun-next',
            sessionId: session.id,
            branchLeafId: a2.id,
            processedMessageIds: const [],
            status: MemoryExtractionStatus.applied,
            createdAt: DateTime.now(),
          ),
          expectedSnapshot: {
            memory.id: ChatMemoryService.originSnapshotOf(folded),
          },
        );
      }

      // 用折叠值做快照会与原始行不一致 → 误报冲突（回归保护）。
      await expectLater(
        db.applyMemoryExtractionTx(
          newMemories: const [],
          diffs: const [],
          run: MemoryExtractionRun(
            id: 'memrun-guard',
            sessionId: session.id,
            branchLeafId: a2.id,
            processedMessageIds: const [],
            status: MemoryExtractionStatus.applied,
            createdAt: DateTime.now(),
          ),
          expectedSnapshot: {
            memory.id: (
              content: folded.content,
              importance: folded.importance,
              type: folded.type,
              isPinned: folded.isPinned,
            ),
          },
        ),
        throwsA(isA<MemoryExtractionConflict>()),
        reason: '折叠值不等于原始行，应判为冲突（证明快照必须取 origin）',
      );

      // 用 origin 原始值做快照 → 与原始行一致 → 正常落库。
      await apply(content: 'C', importance: 5);
      final after = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: a2.id,
      );
      expect(after.single.content, 'C');
      expect(after.single.importance, 5);
    });

    test('快照含类型/常驻：仅类型被并发改动也应判冲突', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: root,
        content: 'A',
        type: MemoryType.setting,
      );

      await expectLater(
        db.applyMemoryExtractionTx(
          newMemories: const [],
          diffs: const [],
          run: MemoryExtractionRun(
            id: 'memrun-type-check',
            sessionId: session.id,
            branchLeafId: root,
            processedMessageIds: const [],
            status: MemoryExtractionStatus.applied,
            createdAt: DateTime.now(),
          ),
          expectedSnapshot: {
            memory.id: (
              content: 'A',
              importance: 3,
              type: MemoryType.fact, // 与原始 setting 不符
              isPinned: false,
            ),
          },
        ),
        throwsA(isA<MemoryExtractionConflict>()),
      );
    });
  });

  group('记忆批量编辑 applyMemoryEdits', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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

    test('新增与更新在同一事务内生效', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: root,
        content: 'A',
        importance: 2,
      );

      await service.applyMemoryEdits(
        sessionId: session.id,
        atMessageId: root,
        commands: [
          const MemoryEditCommand(
            kind: MemoryEditKind.add,
            content: 'B',
            importance: 4,
            type: MemoryType.fact,
          ),
          MemoryEditCommand(
            kind: MemoryEditKind.update,
            targetMemoryId: memory.id,
            content: 'A2',
            importance: 5,
            type: MemoryType.setting,
            isOrigin: true,
          ),
        ],
      );

      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: root,
      );
      expect(resolved.length, 2);
      final updated = resolved.firstWhere((m) => m.id == memory.id);
      expect(updated.content, 'A2');
      expect(updated.importance, 5);
      expect(updated.type, MemoryType.setting);
      expect(
        resolved.any(
          (m) =>
              m.content == 'B' &&
              m.importance == 4 &&
              m.type == MemoryType.fact,
        ),
        isTrue,
      );
    });

    test('校验失败时整体不落库，重试不会重复新增', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;

      // 第二条 update 内容为空白 → 在开启事务前抛错，第一条 add 不应落库。
      await expectLater(
        service.applyMemoryEdits(
          sessionId: session.id,
          atMessageId: root,
          commands: [
            const MemoryEditCommand(
              kind: MemoryEditKind.add,
              content: 'X',
            ),
            const MemoryEditCommand(
              kind: MemoryEditKind.update,
              targetMemoryId: 'missing',
              content: '   ',
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        await service.resolveMemoriesAtMessage(
          sessionId: session.id,
          messageId: root,
        ),
        isEmpty,
        reason: '校验失败时不应有任何记忆落库',
      );

      // 重试一个合法批次，只应新增一条，不产生此前那条的重复。
      await service.applyMemoryEdits(
        sessionId: session.id,
        atMessageId: root,
        commands: [
          const MemoryEditCommand(kind: MemoryEditKind.add, content: 'Y'),
        ],
      );
      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: root,
      );
      expect(resolved.length, 1);
      expect(resolved.single.content, 'Y');
    });

    test('仅还原：清除本节点差量，回到祖先状态', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: root,
        text: 'hi',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: 'yo',
      );
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: root,
        content: 'A',
        importance: 2,
      );
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
        content: 'B',
        importance: 3,
      );

      await service.applyMemoryEdits(
        sessionId: session.id,
        atMessageId: assistant.id,
        commands: [
          MemoryEditCommand(
            kind: MemoryEditKind.clearEdits,
            targetMemoryId: memory.id,
          ),
        ],
      );

      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(resolved.single.content, 'A');
      expect(resolved.single.importance, 2);
    });

    test('还原并重新编辑：先清旧差量再写新 update，结果取新值', () async {
      final db = ChatDatabaseService.instance;
      final service = ChatMemoryService.instance;
      final session = await db.createSession(
        characterId: 'char-1',
        openingAssistantMessages: ['开场白'],
      );
      final root = session.currentLeafMessageId!;
      final user = await db.appendUserMessage(
        sessionId: session.id,
        parentMessageId: root,
        text: 'hi',
      );
      final assistant = await db.appendAssistantMessage(
        sessionId: session.id,
        parentMessageId: user.id,
        text: 'yo',
      );
      final memory = await service.addMemory(
        sessionId: session.id,
        branchLeafId: root,
        content: 'A',
        importance: 2,
      );
      await service.updateMemory(
        sessionId: session.id,
        atMessageId: assistant.id,
        memoryId: memory.id,
        content: 'B',
        importance: 3,
      );

      // 模拟「还原」后继续编辑：clearEdits 必须在新 update 之前执行，
      // 否则刚写入的 C 会被随后的清理误删。
      await service.applyMemoryEdits(
        sessionId: session.id,
        atMessageId: assistant.id,
        commands: [
          MemoryEditCommand(
            kind: MemoryEditKind.clearEdits,
            targetMemoryId: memory.id,
          ),
          MemoryEditCommand(
            kind: MemoryEditKind.update,
            targetMemoryId: memory.id,
            content: 'C',
            importance: 5,
            isOrigin: false,
          ),
        ],
      );

      final resolved = await service.resolveMemoriesAtMessage(
        sessionId: session.id,
        messageId: assistant.id,
      );
      expect(resolved.single.content, 'C');
      expect(resolved.single.importance, 5);
    });
  });
}
