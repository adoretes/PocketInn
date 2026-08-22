import 'package:flutter/material.dart';

import '../../../widgets/scroll_float_button.dart';
import 'message_action_availability.dart';
import 'message_bubble.dart';
import 'message_view_params.dart';
import 'regex_display_text.dart';

/// 聊天消息列表（含滚动浮动按钮）。
///
/// 从原 [ChatPage] 的 build 方法中拆出，负责根据可见消息列表渲染
/// [MessageBubble] 并将用户事件转发给回调。
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.params,
    required this.scrollController,
  });

  /// 与 GalMessageView 共享的公共参数。
  final MessageViewParams params;
  final ScrollController scrollController;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList>
    with RegexDisplayTextMixin<ChatMessageList> {
  @override
  Widget build(BuildContext context) {
    final messages = widget.params.visibleMessages;
    if (messages.isEmpty) {
      return const Center(child: Text('这段聊天还没有消息'));
    }
    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: const [0.0, 0.03, 0.97, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            key: ValueKey(widget.params.sessionId),
            controller: widget.scrollController,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageIndex = messages.length - 1 - index;
              final msg = messages[messageIndex];
              final availability = evaluateMessageActions(
                message: msg,
                messageIndex: messageIndex,
                messageCount: messages.length,
                isSending: widget.params.isSending,
                isDraftSession: widget.params.isDraftSession,
                regeneratingUserMessageId:
                    widget.params.regeneratingUserMessageId,
              );
              final displayText = displayTextFor(
                msg,
                messages.length - 1 - messageIndex,
                widget.params.selectedRegexRuleGroupIds,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MessageBubble(
                  key: ValueKey(msg.id ?? messageIndex),
                  message: msg,
                  userSetting: widget.params.currentUserSetting,
                  character: widget.params.activeCharacter,
                  inputTapRegionGroupId: widget.params.inputTapRegionGroupId,
                  isLastUserMessageWithoutReply:
                      availability.isLastUserMessageWithoutReply,
                  isLastCharacterMessage: availability.isLastCharacterMessage,
                  showActions: availability.showActions,
                  canEdit: availability.canEdit,
                  canDelete: availability.canDelete,
                  isBusyRegenerating: availability.isRegeneratingUserMessage,
                  isBusyImpersonating: widget.params.isImpersonating,
                  displayText: displayText == msg.text ? null : displayText,
                  onCopy: () => widget.params.onCopyMessage(msg),
                  onEdit: availability.hasDraftOpeningActions
                      ? widget.params.onEditDraftOpeningMessage
                      : () => widget.params.onEditMessage(messageIndex),
                  onDelete: () => widget.params.onDeleteMessage(messageIndex),
                  onGenerate:
                      availability.isLastUserMessageWithoutReply &&
                          availability.showActions &&
                          !availability.isRegeneratingUserMessage
                      ? () => widget.params.onRegenerateFromUserMessage(
                          messageIndex,
                        )
                      : null,
                  onRegenerate:
                      availability.isLastCharacterMessage &&
                          availability.showActions
                      ? () => widget.params.onRegenerateMessage(messageIndex)
                      : null,
                  onContinue:
                      availability.isLastCharacterMessage &&
                          availability.showActions
                      ? () => widget.params.onContinueMessage(messageIndex)
                      : null,
                  onImpersonate:
                      availability.isLastCharacterMessage &&
                          availability.showActions
                      ? widget.params.onImpersonate
                      : null,
                  onSelectPreviousVariant: msg.hasMultiple
                      ? () => widget.params.onSwitchMessageVariant(msg, -1)
                      : null,
                  onSelectNextVariant: msg.hasMultiple
                      ? () => widget.params.onSwitchMessageVariant(msg, 1)
                      : null,
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ScrollFloatButton(
            scrollController: widget.scrollController,
            isReversed: true,
          ),
        ),
      ],
    );
  }
}
