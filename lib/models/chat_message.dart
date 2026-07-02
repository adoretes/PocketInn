import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// 聊天消息数据模型
@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    String? id,
    String? sessionId,
    String? parentId,
    required String text,
    required bool isMe,
    /// 当前消息索引（从1开始）
    @Default(1) int index,
    /// 该角色的总消息数
    @Default(1) int total,
    /// 同级消息 ID 列表，顺序与 index/total 对应
    @Default([]) List<String> siblingIds,
    /// 思考链内容（可选）
    String? thinkingChain,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// 是否有多条消息（需要显示<1/x>按钮）
  bool get hasMultiple => total > 1;

  /// 是否有思考链
  bool get hasThinkingChain =>
      thinkingChain != null && thinkingChain!.isNotEmpty;
}
