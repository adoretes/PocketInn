import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../models/chat_message.dart';
import '../streaming_message_snapshot.dart';

/// 把高频流式快照合并进一条消息，只重建 [builder] 返回的最小子树。
///
/// 普通消息列表与 Gal 视图共用：两者都只在「当前消息是流式占位」时才
/// 使用本组件，历史消息仍走原有静态路径。
class StreamingMessageBuilder extends StatelessWidget {
  const StreamingMessageBuilder({
    super.key,
    required this.baseMessage,
    required this.listenable,
    required this.builder,
  });

  /// 流式占位消息元信息（id、isMe、索引等），正文由快照覆盖。
  final ChatMessage baseMessage;

  /// [ChatViewModel.streamingMessageListenable] 透传下来的只读通道。
  final ValueListenable<StreamingMessageSnapshot> listenable;

  final Widget Function(BuildContext context, ChatMessage message) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StreamingMessageSnapshot>(
      valueListenable: listenable,
      builder: (context, snapshot, _) {
        return builder(
          context,
          baseMessage.copyWith(
            text: snapshot.displayText,
            thinkingChain: snapshot.thinkingChainOrNull,
          ),
        );
      },
    );
  }
}
