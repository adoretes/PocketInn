import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/pages/chat/streaming_message_snapshot.dart';
import 'package:pocket_inn/pages/chat/widgets/streaming_message_builder.dart';

void main() {
  group('StreamingMessageSnapshot', () {
    test('内容为空时沿用省略号占位', () {
      const snapshot = StreamingMessageSnapshot();
      expect(snapshot.displayText, '...');
      expect(snapshot.thinkingChainOrNull, isNull);
      expect(snapshot.isEmpty, isTrue);
    });

    test('仅有思考链时不显示省略号', () {
      const snapshot = StreamingMessageSnapshot(thinkingChain: '思考');
      expect(snapshot.displayText, '');
      expect(snapshot.thinkingChainOrNull, '思考');
      expect(snapshot.isEmpty, isFalse);
    });

    test('文本与思考链相同即视为相等', () {
      expect(
        const StreamingMessageSnapshot(text: '你好', thinkingChain: '想'),
        const StreamingMessageSnapshot(text: '你好', thinkingChain: '想'),
      );
      expect(
        const StreamingMessageSnapshot(text: '你好'),
        isNot(const StreamingMessageSnapshot(text: '你好 ')),
      );
    });
  });

  group('StreamingMessageBuilder', () {
    testWidgets('快照更新只重建订阅子树', (tester) async {
      final notifier = ValueNotifier<StreamingMessageSnapshot>(
        StreamingMessageSnapshot.empty,
      );
      addTearDown(notifier.dispose);

      var builderCalls = 0;
      var siblingBuilds = 0;
      ChatMessage? received;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  siblingBuilds++;
                  return const SizedBox.shrink();
                },
              ),
              StreamingMessageBuilder(
                baseMessage: const ChatMessage(
                  text: '...',
                  isMe: false,
                  parentId: 'parent-1',
                ),
                listenable: notifier,
                builder: (context, message) {
                  builderCalls++;
                  received = message;
                  return Text(message.text);
                },
              ),
            ],
          ),
        ),
      );

      expect(builderCalls, 1);
      expect(siblingBuilds, 1);
      expect(received?.parentId, 'parent-1');
      expect(find.text('...'), findsOneWidget);

      notifier.value = const StreamingMessageSnapshot(
        text: '你好',
        thinkingChain: '思考',
      );
      await tester.pump();

      expect(builderCalls, 2);
      // 兄弟节点不参与流式刷新。
      expect(siblingBuilds, 1);
      expect(received?.text, '你好');
      expect(received?.thinkingChain, '思考');
      expect(find.text('你好'), findsOneWidget);

      // 相同内容重复发布不触发重建。
      notifier.value = const StreamingMessageSnapshot(
        text: '你好',
        thinkingChain: '思考',
      );
      await tester.pump();
      expect(builderCalls, 2);
    });

    testWidgets('快照清空后回落到占位文本', (tester) async {
      final notifier = ValueNotifier<StreamingMessageSnapshot>(
        const StreamingMessageSnapshot(text: '进行中'),
      );
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StreamingMessageBuilder(
            baseMessage: const ChatMessage(text: '', isMe: false),
            listenable: notifier,
            builder: (context, message) => Text(message.text),
          ),
        ),
      );
      expect(find.text('进行中'), findsOneWidget);

      notifier.value = StreamingMessageSnapshot.empty;
      await tester.pump();
      expect(find.text('...'), findsOneWidget);
    });
  });
}
