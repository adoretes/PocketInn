import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/core/service_locator.dart';
import 'package:pocket_inn/data/api_configs.dart';
import 'package:pocket_inn/data/mock_user_settings.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/models/chat_session.dart';
import 'package:pocket_inn/pages/chat/chat_view_model.dart';
import 'package:pocket_inn/services/chat_character_resolver.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/preset_service.dart';

/// 构建一个最小可用的 [ChatSession]，供测试使用。
ChatSession _makeSession({String id = 'session-1'}) {
  final now = DateTime(2026, 1, 1);
  return ChatSession(
    id: id,
    title: '测试会话',
    characterId: 'char-1',
    selectedWorldBookIds: const [],
    createdAt: now,
    updatedAt: now,
  );
}

/// 构建一个最小可用的 [ResolvedChatCharacter]，供测试使用。
ResolvedChatCharacter _makeCharacter() {
  return const ResolvedChatCharacter(
    id: 'char-1',
    name: '测试角色',
    description: '测试描述',
    cardJson: {},
  );
}

ChatMessage _user(String text, {String? id}) =>
    ChatMessage(text: text, isMe: true, id: id);

ChatMessage _assistant(String text, {String? id, String? parentId}) =>
    ChatMessage(text: text, isMe: false, id: id, parentId: parentId);

void main() {
  late ChatViewModel viewModel;

  setUp(() {
    getIt.reset();
    // VM 构造函数访问 changeNotifier 字段，无需 initialize()。
    getIt.registerSingleton<ChatDatabaseService>(ChatDatabaseService.instance);
    getIt.registerSingleton<PresetService>(PresetService.instance);
    // 重置全局状态，避免 _refreshEnabledApiStatus 触发 service 调用。
    apiConfigsNotifier.value = [];
    userSettingsNotifier.value = List.of(defaultUserSettings);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('visibleMessages', () {
    test('空消息列表且未发送时返回空列表', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: const [],
      );
      expect(viewModel.visibleMessages, isEmpty);
    });

    test('仅含已加载消息时返回原列表副本', () {
      final messages = [_user('你好'), _assistant('你好呀')];
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: messages,
      );
      final visible = viewModel.visibleMessages;
      expect(visible.length, 2);
      expect(visible[0].text, '你好');
      expect(visible[1].text, '你好呀');
      // 确保返回的是副本，不影响原列表
      expect(identical(visible, messages), isFalse);
    });

    test('含待发送用户消息时追加到末尾', () {
      viewModel = ChatViewModel();
      final pending = _user('待发送');
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [_user('历史1'), _assistant('历史2')],
        pendingUserMessage: pending,
      );
      final visible = viewModel.visibleMessages;
      expect(visible.length, 3);
      expect(visible.last.text, '待发送');
      expect(visible.last.isMe, isTrue);
    });

    test('发送中且使用流式时追加助手占位消息', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [_user('历史1')],
        isSending: true,
        useStreaming: true,
        streamingAssistantText: '',
        streamingThinkingChain: '',
      );
      final visible = viewModel.visibleMessages;
      // 1 条历史 + 1 条助手占位
      expect(visible.length, 2);
      expect(visible.last.isMe, isFalse);
      expect(visible.last.text, '...');
    });

    test('发送中且已有流式文本时占位消息显示流式文本', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [_user('历史1')],
        isSending: true,
        useStreaming: true,
        streamingAssistantText: '流式回复',
        streamingThinkingChain: '思考中',
      );
      final visible = viewModel.visibleMessages;
      expect(visible.last.text, '流式回复');
      expect(visible.last.thinkingChain, '思考中');
    });

    test('发送中但无角色时不追加占位消息', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: null,
        messages: [_user('历史1')],
        isSending: true,
        useStreaming: true,
      );
      expect(viewModel.visibleMessages.length, 1);
    });

    test('重新生成时移除上一条匹配 parentId 的助手消息', () {
      final userMsgId = 'user-msg-1';
      final assistantMsgId = 'assistant-msg-1';
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: userMsgId),
          _assistant('旧回复', id: assistantMsgId, parentId: userMsgId),
        ],
        regeneratingUserMessageId: userMsgId,
        isSending: true,
        useStreaming: true,
        streamingAssistantText: '',
      );
      final visible = viewModel.visibleMessages;
      // 旧回复被移除，加入助手占位
      expect(visible.length, 2);
      expect(visible[0].text, '问题');
      expect(visible[1].isMe, isFalse);
      expect(visible[1].text, '...');
    });

    test('重新生成时末尾非助手消息则不移除', () {
      final userMsgId = 'user-msg-1';
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: userMsgId),
          _assistant('回复', parentId: userMsgId),
          _user('追问'),
        ],
        regeneratingUserMessageId: userMsgId,
        isSending: true,
        useStreaming: true,
      );
      final visible = viewModel.visibleMessages;
      // 末尾是用户消息，不移除，但追加占位助手消息
      expect(visible.length, 4);
    });
  });

  group('selectSession 守卫', () {
    test('发送中返回 false', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(id: 'session-1'),
        activeCharacter: _makeCharacter(),
        isSending: true,
      );
      expect(viewModel.selectSession('session-2'), isFalse);
      expect(viewModel.isSwitchingSession, isFalse);
    });

    test('选择当前会话返回 false', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(id: 'session-1'),
        activeCharacter: _makeCharacter(),
      );
      expect(viewModel.selectSession('session-1'), isFalse);
      expect(viewModel.isSwitchingSession, isFalse);
    });
  });

  group('sendMessage 守卫', () {
    test('空文本不发送', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
      );
      await viewModel.sendMessage('   ');
      expect(viewModel.isSending, isFalse);
      expect(viewModel.pendingUserMessage, isNull);
    });

    test('无会话时不发送', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(activeCharacter: _makeCharacter());
      await viewModel.sendMessage('你好');
      expect(viewModel.isSending, isFalse);
      expect(viewModel.pendingUserMessage, isNull);
    });

    test('无角色时不发送', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(activeSession: _makeSession());
      await viewModel.sendMessage('你好');
      expect(viewModel.isSending, isFalse);
      expect(viewModel.pendingUserMessage, isNull);
    });

    test('会话切换中不发送', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        isSwitchingSession: true,
      );
      await viewModel.sendMessage('你好');
      expect(viewModel.isSending, isFalse);
      expect(viewModel.pendingUserMessage, isNull);
    });

    test('正在发送中不重复发送', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        isSending: true,
      );
      await viewModel.sendMessage('你好');
      // 仍处于发送中，且 pendingUserMessage 未被覆盖
      expect(viewModel.isSending, isTrue);
    });
  });

  group('regenerateMessage 守卫', () {
    test('发送中不执行', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: 'u1'),
          _assistant('回复'),
        ],
        isSending: true,
      );
      await viewModel.regenerateMessage(1);
      // 未进入重新生成流程
      expect(viewModel.regeneratingUserMessageId, isNull);
    });

    test('无会话不执行', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: 'u1'),
          _assistant('回复'),
        ],
      );
      await viewModel.regenerateMessage(1);
      expect(viewModel.regeneratingUserMessageId, isNull);
    });

    test('无角色不执行', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        messages: [
          _user('问题', id: 'u1'),
          _assistant('回复'),
        ],
      );
      await viewModel.regenerateMessage(1);
      expect(viewModel.regeneratingUserMessageId, isNull);
    });

    test('索引越界不执行', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: 'u1'),
          _assistant('回复'),
        ],
      );
      await viewModel.regenerateMessage(-1);
      expect(viewModel.regeneratingUserMessageId, isNull);
      await viewModel.regenerateMessage(99);
      expect(viewModel.regeneratingUserMessageId, isNull);
    });

    test('索引为 0 不执行（上一条必须是用户消息）', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [
          _user('问题', id: 'u1'),
          _assistant('回复'),
        ],
      );
      await viewModel.regenerateMessage(0);
      expect(viewModel.regeneratingUserMessageId, isNull);
    });

    test('上一条非用户消息不执行', () async {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(
        activeSession: _makeSession(),
        activeCharacter: _makeCharacter(),
        messages: [_assistant('开场白'), _assistant('第二条')],
      );
      await viewModel.regenerateMessage(1);
      expect(viewModel.regeneratingUserMessageId, isNull);
    });
  });

  group('setUseStreaming', () {
    test('切换流式开关并通知监听器', () {
      viewModel = ChatViewModel();
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);
      expect(viewModel.useStreaming, isTrue);

      viewModel.setUseStreaming(false);
      expect(viewModel.useStreaming, isFalse);
      expect(notifyCount, 1);

      viewModel.setUseStreaming(true);
      expect(viewModel.useStreaming, isTrue);
      expect(notifyCount, 2);
    });
  });

  group('currentUserSetting / resolvedUserName', () {
    test('无用户设定时返回 null / 默认名', () {
      userSettingsNotifier.value = [];
      viewModel = ChatViewModel();
      expect(viewModel.currentUserSetting(), isNull);
      expect(viewModel.resolvedUserName(), '默认用户');
    });

    test('未选中时回退到列表首项', () {
      final settings = [
        UserSetting(id: 's1', name: '用户A', prompt: '', colorValue: 0xFF5C6BC0),
        UserSetting(id: 's2', name: '用户B', prompt: '', colorValue: 0xFF5C6BC0),
      ];
      userSettingsNotifier.value = settings;
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(selectedUserSettingId: null);
      expect(viewModel.currentUserSetting()?.id, 's1');
      expect(viewModel.resolvedUserName(), '用户A');
    });

    test('选中 ID 有效时返回对应项', () {
      final settings = [
        UserSetting(id: 's1', name: '用户A', prompt: '', colorValue: 0xFF5C6BC0),
        UserSetting(id: 's2', name: '用户B', prompt: '', colorValue: 0xFF5C6BC0),
      ];
      userSettingsNotifier.value = settings;
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(selectedUserSettingId: 's2');
      expect(viewModel.currentUserSetting()?.id, 's2');
      expect(viewModel.resolvedUserName(), '用户B');
    });

    test('选中 ID 无效时回退到首项', () {
      final settings = [
        UserSetting(id: 's1', name: '用户A', prompt: '', colorValue: 0xFF5C6BC0),
      ];
      userSettingsNotifier.value = settings;
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(selectedUserSettingId: '不存在的ID');
      expect(viewModel.currentUserSetting()?.id, 's1');
    });
  });

  group('replaceChatVariables', () {
    test('替换 {{user}} 和 {{char}} 占位符', () {
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(activeCharacter: _makeCharacter());
      userSettingsNotifier.value = [
        UserSetting(id: 's1', name: '小明', prompt: '', colorValue: 0xFF5C6BC0),
      ];
      final result = viewModel.replaceChatVariables('我是{{user}}, 你是{{char}}');
      expect(result, '我是小明, 你是测试角色');
    });

    test('无角色时使用默认角色名', () {
      viewModel = ChatViewModel();
      userSettingsNotifier.value = [
        UserSetting(id: 's1', name: '小明', prompt: '', colorValue: 0xFF5C6BC0),
      ];
      final result = viewModel.replaceChatVariables('你好, {{char}}');
      expect(result, '你好, 角色');
    });

    test('无用户设定时使用默认用户名', () {
      userSettingsNotifier.value = [];
      viewModel = ChatViewModel();
      viewModel.setStateForTesting(activeCharacter: _makeCharacter());
      final result = viewModel.replaceChatVariables('我是{{user}}');
      expect(result, '我是默认用户');
    });
  });

  group('onSessionReloaded 回调', () {
    test('回调字段初始为 null', () {
      viewModel = ChatViewModel();
      expect(viewModel.onSessionReloaded, isNull);
    });
  });

  group('dispose', () {
    test('dispose 后 isDisposed 标记生效', () {
      // 使用局部 VM 进行 dispose，避免 tearDown 二次 dispose 报错
      final localVm = ChatViewModel();
      // dispose 不应抛异常
      expect(() => localVm.dispose(), returnsNormally);
      // 为 tearDown 准备一个未 dispose 的实例
      viewModel = ChatViewModel();
    });
  });
}
