import '../../../models/chat_message.dart';

/// 消息操作菜单/按钮的可用性判定结果。
class MessageActionAvailability {
  const MessageActionAvailability({
    required this.isLastUserMessageWithoutReply,
    required this.isLastCharacterMessage,
    required this.isRegeneratingUserMessage,
    required this.hasPersistedMessage,
    required this.hasDraftOpeningActions,
    required this.showActions,
    required this.canEdit,
    required this.canDelete,
  });

  final bool isLastUserMessageWithoutReply;
  final bool isLastCharacterMessage;
  final bool isRegeneratingUserMessage;
  final bool hasPersistedMessage;
  final bool hasDraftOpeningActions;
  final bool showActions;
  final bool canEdit;
  final bool canDelete;
}

/// 统一判定某条消息的操作可用性（Gal 视图与普通消息列表共用）。
MessageActionAvailability evaluateMessageActions({
  required ChatMessage message,
  required int messageIndex,
  required int messageCount,
  required bool isSending,
  required bool isDraftSession,
  required String? regeneratingUserMessageId,
}) {
  final isLastMessage = messageIndex == messageCount - 1;
  final isRegeneratingUserMessage =
      regeneratingUserMessageId != null &&
      message.id == regeneratingUserMessageId;
  final hasPersistedMessage = message.id != null;
  final hasDraftOpeningActions =
      isDraftSession && !hasPersistedMessage && !message.isMe;
  final showActions =
      (hasPersistedMessage || hasDraftOpeningActions) &&
      (!isSending || isRegeneratingUserMessage);
  return MessageActionAvailability(
    isLastUserMessageWithoutReply: isLastMessage && message.isMe,
    isLastCharacterMessage: isLastMessage && !message.isMe,
    isRegeneratingUserMessage: isRegeneratingUserMessage,
    hasPersistedMessage: hasPersistedMessage,
    hasDraftOpeningActions: hasDraftOpeningActions,
    showActions: showActions,
    canEdit: (hasPersistedMessage || hasDraftOpeningActions) && !isSending,
    canDelete: hasPersistedMessage && !isSending,
  );
}
