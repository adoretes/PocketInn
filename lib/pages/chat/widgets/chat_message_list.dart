import 'package:flutter/material.dart';

import '../../../models/chat_message.dart';
import '../../../models/user_setting.dart';
import '../../../services/chat_character_resolver.dart';
import '../../../widgets/scroll_float_button.dart';
import 'message_bubble.dart';

/// 聊天消息列表（含滚动浮动按钮）。
///
/// 从原 [ChatPage] 的 build 方法中拆出，负责根据可见消息列表渲染
/// [MessageBubble] 并将用户事件转发给回调。
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.visibleMessages,
    required this.scrollController,
    required this.inputTapRegionGroupId,
    required this.isSending,
    required this.isImpersonating,
    required this.regeneratingUserMessageId,
    required this.isDraftSession,
    required this.activeCharacter,
    required this.currentUserSetting,
    required this.sessionId,
    required this.onCopyMessage,
    required this.onEditMessage,
    required this.onEditDraftOpeningMessage,
    required this.onDeleteMessage,
    required this.onRegenerateFromUserMessage,
    required this.onRegenerateMessage,
    required this.onContinueMessage,
    required this.onImpersonate,
    required this.onSwitchMessageVariant,
  });

  final List<ChatMessage> visibleMessages;
  final ScrollController scrollController;
  final Object inputTapRegionGroupId;
  final bool isSending;
  final bool isImpersonating;
  final String? regeneratingUserMessageId;
  final bool isDraftSession;
  final ResolvedChatCharacter? activeCharacter;
  final UserSetting? currentUserSetting;
  final String? sessionId;

  final void Function(ChatMessage msg) onCopyMessage;
  final void Function(int index) onEditMessage;
  final VoidCallback onEditDraftOpeningMessage;
  final void Function(int index) onDeleteMessage;
  final void Function(int index) onRegenerateFromUserMessage;
  final void Function(int index) onRegenerateMessage;
  final void Function(int index) onContinueMessage;
  final VoidCallback onImpersonate;
  final void Function(ChatMessage message, int delta) onSwitchMessageVariant;

  @override
  Widget build(BuildContext context) {
    if (visibleMessages.isEmpty) {
      return const Center(child: Text('这段聊天还没有消息'));
    }
    return Stack(
      children: [
        ListView.builder(
          key: ValueKey(sessionId),
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: visibleMessages.length,
          itemBuilder: (context, index) {
            final messageIndex = visibleMessages.length - 1 - index;
            final msg = visibleMessages[messageIndex];
            final isLastMessage = messageIndex == visibleMessages.length - 1;
            final isLastUserMessageWithoutReply = isLastMessage && msg.isMe;
            final isLastCharacterMessage = isLastMessage && !msg.isMe;
            final isRegeneratingUserMessage =
                regeneratingUserMessageId != null &&
                msg.id == regeneratingUserMessageId;
            final hasPersistedMessage = msg.id != null;
            final hasDraftOpeningActions =
                isDraftSession && !hasPersistedMessage && !msg.isMe;
            final showActions =
                (hasPersistedMessage || hasDraftOpeningActions) &&
                (!isSending || isRegeneratingUserMessage);
            final canEditMessage =
                (hasPersistedMessage || hasDraftOpeningActions) && !isSending;
            final canDeleteMessage = hasPersistedMessage && !isSending;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MessageBubble(
                key: ValueKey(msg.id ?? messageIndex),
                message: msg,
                userSetting: currentUserSetting,
                character: activeCharacter,
                inputTapRegionGroupId: inputTapRegionGroupId,
                isLastUserMessageWithoutReply: isLastUserMessageWithoutReply,
                isLastCharacterMessage: isLastCharacterMessage,
                showActions: showActions,
                canEdit: canEditMessage,
                canDelete: canDeleteMessage,
                isBusyRegenerating: isRegeneratingUserMessage,
                isBusyImpersonating: isImpersonating,
                onCopy: () => onCopyMessage(msg),
                onEdit: hasDraftOpeningActions
                    ? onEditDraftOpeningMessage
                    : () => onEditMessage(messageIndex),
                onDelete: () => onDeleteMessage(messageIndex),
                onGenerate:
                    isLastUserMessageWithoutReply &&
                        showActions &&
                        !isRegeneratingUserMessage
                    ? () => onRegenerateFromUserMessage(messageIndex)
                    : null,
                onRegenerate: isLastCharacterMessage && showActions
                    ? () => onRegenerateMessage(messageIndex)
                    : null,
                onContinue: isLastCharacterMessage && showActions
                    ? () => onContinueMessage(messageIndex)
                    : null,
                onImpersonate: isLastCharacterMessage && showActions
                    ? onImpersonate
                    : null,
                onSelectPreviousVariant: msg.hasMultiple
                    ? () => onSwitchMessageVariant(msg, -1)
                    : null,
                onSelectNextVariant: msg.hasMultiple
                    ? () => onSwitchMessageVariant(msg, 1)
                    : null,
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ScrollFloatButton(
            scrollController: scrollController,
            isReversed: true,
          ),
        ),
      ],
    );
  }
}
