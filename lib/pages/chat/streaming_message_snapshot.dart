import 'package:flutter/foundation.dart';

/// 流式助手消息的不可变快照。
///
/// 流式过程中正文与思考链每帧都在增长；把二者打包成一个可比较的快照，
/// 让 UI 层只在内容真正变化时刷新，而不必监听会触发整页重建的
/// `ChatViewModel` 主通知。
@immutable
class StreamingMessageSnapshot {
  const StreamingMessageSnapshot({this.text = '', this.thinkingChain = ''});

  /// 空快照：没有流式内容（未发送或已结束）。
  static const StreamingMessageSnapshot empty = StreamingMessageSnapshot();

  /// 已接收的助手正文。
  final String text;

  /// 已接收的思考链内容（推理模型或伪思维链的原始文本）。
  final String thinkingChain;

  /// 正文与思考链都为空时沿用既有占位语义，显示省略号。
  String get displayText =>
      text.isEmpty && thinkingChain.isEmpty ? '...' : text;

  /// 无思考链时返回 null，与 [ChatMessage.thinkingChain] 语义一致。
  String? get thinkingChainOrNull =>
      thinkingChain.isEmpty ? null : thinkingChain;

  /// 是否没有任何内容。
  bool get isEmpty => text.isEmpty && thinkingChain.isEmpty;

  @override
  bool operator ==(Object other) {
    return other is StreamingMessageSnapshot &&
        other.text == text &&
        other.thinkingChain == thinkingChain;
  }

  @override
  int get hashCode => Object.hash(text, thinkingChain);

  @override
  String toString() =>
      'StreamingMessageSnapshot(textLength: ${text.length}, '
      'thinkingChainLength: ${thinkingChain.length})';
}
