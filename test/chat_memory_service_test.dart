import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/services/chat_memory_service.dart';
import 'package:pocket_inn/services/chat_variable_service.dart';

ChatMessage _user(String text) => ChatMessage(text: text, isMe: true);

ChatMessage _assistant(String text) => ChatMessage(text: text, isMe: false);

MemoryNode _memory({
  required String id,
  required String branchLeafId,
  required String content,
  required DateTime createdAt,
  List<String> sourceMessageIds = const [],
  bool isUserEdited = false,
}) {
  return MemoryNode(
    id: id,
    sessionId: 's1',
    branchLeafId: branchLeafId,
    content: content,
    sourceMessageIds: sourceMessageIds,
    isUserEdited: isUserEdited,
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

  group('ChatMemoryService.selectBranchMemories', () {
    // 当前分支 根→叶：n1..n5。
    const path = ['n1', 'n2', 'n3', 'n4', 'n5'];
    final baseTime = DateTime(2026, 1, 1);

    MemoryNode at(String node, String content, {int minutes = 0}) => _memory(
      id: '$node-$content',
      branchLeafId: node,
      content: content,
      createdAt: baseTime.add(Duration(minutes: minutes)),
    );

    test('无记忆返回空列表', () {
      expect(
        ChatMemoryService.selectBranchMemories(
          all: const [],
          pathMessageIds: path,
          count: 2,
        ),
        isEmpty,
      );
    });

    test('count <= 0 视为无限制，返回全部并按分支顺序展开', () {
      final all = [at('n1', 'a'), at('n5', 'c'), at('n3', 'b')];
      final result = ChatMemoryService.selectBranchMemories(
        all: all,
        pathMessageIds: path,
        count: 0,
      );
      expect(result.map((m) => m.content), ['a', 'b', 'c']);
    });

    test('节点数 <= count 时返回全部，节点内按 createdAt 升序', () {
      final all = [
        at('n3', 'c2', minutes: 5),
        at('n1', 'a1'),
        at('n3', 'c1', minutes: 1),
      ];
      final result = ChatMemoryService.selectBranchMemories(
        all: all,
        pathMessageIds: path,
        count: 3,
      );
      expect(result.map((m) => m.content), ['a1', 'c1', 'c2']);
    });

    test('节点数 > count 时取最靠近当前叶的 count 个节点', () {
      final all = [at('n1', 'a'), at('n3', 'c'), at('n5', 'e')];
      final result = ChatMemoryService.selectBranchMemories(
        all: all,
        pathMessageIds: path,
        count: 2,
      );
      // 取 n3、n5（最靠近叶），输出仍按分支顺序。
      expect(result.map((m) => m.content), ['c', 'e']);
    });

    test('在最早的节点手动新增记忆不改变节点选取集合', () {
      final base = [at('n1', 'a'), at('n3', 'c'), at('n5', 'e')];
      final before = ChatMemoryService.selectBranchMemories(
        all: base,
        pathMessageIds: path,
        count: 2,
      );
      expect(before.map((m) => m.branchLeafId).toSet(), {'n3', 'n5'});

      // 模拟在最早的 n1 上手动新增一条"最新"记忆。
      final edited = [
        ...base,
        _memory(
          id: 'n1-manual',
          branchLeafId: 'n1',
          content: '手动',
          createdAt: baseTime.add(const Duration(days: 30)),
          isUserEdited: true,
        ),
      ];
      final after = ChatMemoryService.selectBranchMemories(
        all: edited,
        pathMessageIds: path,
        count: 2,
      );
      // 选取的节点集合保持不变（不再被 createdAt 扰动）。
      expect(after.map((m) => m.branchLeafId).toSet(), {'n3', 'n5'});
    });

    test('路径外节点（异常数据）不抛异常且排在最早', () {
      final all = [at('nX', 'x'), at('n5', 'e')];
      final result = ChatMemoryService.selectBranchMemories(
        all: all,
        pathMessageIds: path,
        count: 1,
      );
      expect(result.map((m) => m.content), ['e']);
    });
  });

  group('ChatMemoryService 提取水位线', () {
    test('processedMessageIds 返回所有记忆来源的并集', () {
      final memories = [
        _memory(
          id: 'm1',
          branchLeafId: 'a1',
          content: 'x',
          createdAt: DateTime(2026),
          sourceMessageIds: const ['a', 'b'],
        ),
        _memory(
          id: 'm2',
          branchLeafId: 'a2',
          content: 'y',
          createdAt: DateTime(2026, 1, 2),
          sourceMessageIds: const ['b', 'c'],
        ),
      ];
      expect(ChatMemoryService.processedMessageIds(memories), {'a', 'b', 'c'});
    });

    test('无记忆时统计全部角色消息', () {
      final all = [
        ChatMessage(id: 'u1', text: 'u1', isMe: true),
        ChatMessage(id: 'a1', text: 'a1', isMe: false),
        ChatMessage(id: 'u2', text: 'u2', isMe: true),
        ChatMessage(id: 'a2', text: 'a2', isMe: false),
      ];
      expect(
        ChatMemoryService.countNewAssistantMessages(
          allMessages: all,
          branchMemories: const [],
        ),
        2,
      );
    });

    test('手动编辑写出的空来源记忆不回退水位', () {
      final all = [
        ChatMessage(id: 'u1', text: 'u1', isMe: true),
        ChatMessage(id: 'a1', text: 'a1', isMe: false),
        ChatMessage(id: 'u2', text: 'u2', isMe: true),
        ChatMessage(id: 'a2', text: 'a2', isMe: false),
      ];
      final memories = [
        // 手动编辑产生的最新记忆，来源为空（不能作为水位依据）。
        _memory(
          id: 'm-edit',
          branchLeafId: 'a1',
          content: 'edited',
          createdAt: DateTime(2026, 5, 1),
          isUserEdited: true,
        ),
        // 自动提取的原始记忆，覆盖 u1/a1。
        _memory(
          id: 'm-auto',
          branchLeafId: 'a1',
          content: 'auto',
          createdAt: DateTime(2026),
          sourceMessageIds: const ['u1', 'a1'],
        ),
      ];
      // 并集水位 = {u1, a1}，仅 a2 属于新增。
      expect(
        ChatMemoryService.countNewAssistantMessages(
          allMessages: all,
          branchMemories: memories,
        ),
        1,
      );
    });
  });
}
