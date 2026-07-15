import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/services/chat_memory_service.dart';

ChatMessage _user(String text) => ChatMessage(text: text, isMe: true);

ChatMessage _assistant(String text) => ChatMessage(text: text, isMe: false);

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

    test('解析 - 前缀', () {
      expect(ChatMemoryService.parseMemoryPoints('- 用户喜欢苹果'), ['用户喜欢苹果']);
    });

    test('解析 * 前缀', () {
      expect(ChatMemoryService.parseMemoryPoints('* 角色害怕猫'), ['角色害怕猫']);
    });

    test('解析 • 前缀', () {
      expect(ChatMemoryService.parseMemoryPoints('• 故事发生在雪原'), ['故事发生在雪原']);
    });

    test('混合前缀', () {
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
    test('不传 extractionModelId 时保持原值', () {
      const config = MemoryExtractionConfig(extractionModelId: 'model-1');
      final next = config.copyWith();
      expect(next.extractionModelId, 'model-1');
    });

    test('clearExtractionModel 置为 null', () {
      const config = MemoryExtractionConfig(extractionModelId: 'model-1');
      final next = config.copyWith(extractionModelId: null);
      expect(next.extractionModelId, isNull);
    });

    test('显式传入 extractionModelId 覆盖原值', () {
      const config = MemoryExtractionConfig(extractionModelId: 'model-1');
      final next = config.copyWith(extractionModelId: 'model-2');
      expect(next.extractionModelId, 'model-2');
    });

    test('不传 customExtractionPrompt 时保持原值', () {
      const config = MemoryExtractionConfig(customExtractionPrompt: '原提示词');
      final next = config.copyWith();
      expect(next.customExtractionPrompt, '原提示词');
    });

    test('clearCustomExtractionPrompt 置为空字符串', () {
      const config = MemoryExtractionConfig(customExtractionPrompt: '原提示词');
      final next = config.copyWith(customExtractionPrompt: '');
      expect(next.customExtractionPrompt, '');
    });

    test('显式传入 customExtractionPrompt 覆盖原值', () {
      const config = MemoryExtractionConfig(customExtractionPrompt: '原提示词');
      final next = config.copyWith(customExtractionPrompt: '新提示词');
      expect(next.customExtractionPrompt, '新提示词');
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
}
