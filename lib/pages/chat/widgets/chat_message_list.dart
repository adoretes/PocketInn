import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/scroll_float_button.dart';
import 'message_action_availability.dart';
import 'message_bubble.dart';
import 'message_view_params.dart';
import 'regex_display_text.dart';
import 'streaming_message_builder.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final character = widget.params.activeCharacter;
    final backgroundPath = character?.imagePath ?? '';
    final backgroundSize = widget.params.backgroundAreaSize;
    final showBackgroundCopy =
        widget.params.hasBackground &&
        backgroundSize != null &&
        backgroundPath.isNotEmpty;
    final isAssetImage = character?.isAssetImage == true;

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
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 背景副本：与页面真实背景同图同尺寸同位置地绘制在遮罩层内，
              // 让列表内容的渐隐与真实背景无缝衔接；同时气泡的
              // BackdropFilter 在 Impeller 渲染器下才能采样到背景内容。
              if (showBackgroundCopy)
                Positioned(
                  left: 0,
                  top: -widget.params.backgroundAreaTop,
                  width: backgroundSize.width,
                  height: backgroundSize.height,
                  child: IgnorePointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBackgroundImage(
                          path: backgroundPath,
                          isAsset: isAssetImage,
                        ),
                        Container(
                          color: colorScheme.surface.withValues(
                            alpha: appSettingsNotifier.value.backgroundOpacity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ListView.builder(
                key: ValueKey(widget.params.sessionId),
                controller: widget.scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageIndex = messages.length - 1 - index;
                  final msg = messages[messageIndex];
                  final distanceFromLatest = messages.length - 1 - messageIndex;
                  final bubbleKey = ValueKey<Object>(msg.id ?? messageIndex);
                  // 只有末尾的流式占位消息订阅高频通道，历史消息保持静态。
                  final isStreamingPlaceholder =
                      distanceFromLatest == 0 &&
                      widget.params.isSending &&
                      !msg.isMe &&
                      msg.id == null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: isStreamingPlaceholder
                        ? StreamingMessageBuilder(
                            baseMessage: msg,
                            listenable:
                                widget.params.streamingMessageListenable,
                            builder: (context, liveMessage) => _buildBubble(
                              bubbleKey: bubbleKey,
                              message: liveMessage,
                              messageIndex: messageIndex,
                              distanceFromLatest: distanceFromLatest,
                              messageCount: messages.length,
                            ),
                          )
                        : _buildBubble(
                            bubbleKey: bubbleKey,
                            message: msg,
                            messageIndex: messageIndex,
                            distanceFromLatest: distanceFromLatest,
                            messageCount: messages.length,
                          ),
                  );
                },
              ),
            ],
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

  /// 构建单条消息气泡；流式占位与静态消息共用同一套参数计算。
  Widget _buildBubble({
    required Key bubbleKey,
    required ChatMessage message,
    required int messageIndex,
    required int distanceFromLatest,
    required int messageCount,
  }) {
    final availability = evaluateMessageActions(
      message: message,
      messageIndex: messageIndex,
      messageCount: messageCount,
      isSending: widget.params.isSending,
      isDraftSession: widget.params.isDraftSession,
      regeneratingUserMessageId: widget.params.regeneratingUserMessageId,
    );
    final displayText = displayTextFor(
      message,
      distanceFromLatest,
      widget.params.selectedRegexRuleGroupIds,
    );
    return MessageBubble(
      key: bubbleKey,
      message: message,
      userSetting: widget.params.currentUserSetting,
      character: widget.params.activeCharacter,
      hasBackground: widget.params.hasBackground,
      inputTapRegionGroupId: widget.params.inputTapRegionGroupId,
      isLastUserMessageWithoutReply: availability.isLastUserMessageWithoutReply,
      isLastCharacterMessage: availability.isLastCharacterMessage,
      showActions: availability.showActions,
      canEdit: availability.canEdit,
      canDelete: availability.canDelete,
      isBusyRegenerating: availability.isRegeneratingUserMessage,
      isBusyImpersonating: widget.params.isImpersonating,
      displayText: displayText == message.text ? null : displayText,
      onCopy: () => widget.params.onCopyMessage(message),
      onEdit: availability.hasDraftOpeningActions
          ? widget.params.onEditDraftOpeningMessage
          : () => widget.params.onEditMessage(messageIndex),
      onDelete: () => widget.params.onDeleteMessage(messageIndex),
      onGenerate:
          availability.isLastUserMessageWithoutReply &&
              availability.showActions &&
              !availability.isRegeneratingUserMessage
          ? () => widget.params.onRegenerateFromUserMessage(messageIndex)
          : null,
      onRegenerate:
          availability.isLastCharacterMessage && availability.showActions
          ? () => widget.params.onRegenerateMessage(messageIndex)
          : null,
      onContinue:
          availability.isLastCharacterMessage && availability.showActions
          ? () => widget.params.onContinueMessage(messageIndex)
          : null,
      onImpersonate:
          availability.isLastCharacterMessage && availability.showActions
          ? widget.params.onImpersonate
          : null,
      onSelectPreviousVariant: message.hasMultiple
          ? () => widget.params.onSwitchMessageVariant(message, -1)
          : null,
      onSelectNextVariant: message.hasMultiple
          ? () => widget.params.onSwitchMessageVariant(message, 1)
          : null,
    );
  }

  Widget _buildBackgroundImage({required String path, required bool isAsset}) {
    return isAsset
        ? Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          );
  }
}
