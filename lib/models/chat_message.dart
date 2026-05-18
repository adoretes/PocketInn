/// 聊天消息数据模型
class ChatMessage {
  final String? id;
  final String? sessionId;
  final String? parentId;
  final String text;
  final bool isMe;

  /// 当前消息索引（从1开始）
  final int index;

  /// 该角色的总消息数
  final int total;

  /// 同级消息 ID 列表，顺序与 index/total 对应
  final List<String> siblingIds;

  /// 思考链内容（可选）
  final String? thinkingChain;

  ChatMessage({
    this.id,
    this.sessionId,
    this.parentId,
    required this.text,
    required this.isMe,
    this.index = 1,
    this.total = 1,
    this.siblingIds = const [],
    this.thinkingChain,
  });

  /// 是否有多条消息（需要显示<1/x>按钮）
  bool get hasMultiple => total > 1;

  /// 是否有思考链
  bool get hasThinkingChain =>
      thinkingChain != null && thinkingChain!.isNotEmpty;
}
