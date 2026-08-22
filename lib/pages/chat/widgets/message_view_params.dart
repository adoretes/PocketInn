import 'package:flutter/material.dart';

import '../../../models/chat_message.dart';
import '../../../models/user_setting.dart';
import '../../../services/chat_character_resolver.dart';

/// Gal 视图与普通消息列表共享的公共参数。
///
/// 两个视图对消息、会话状态与回调的语义完全一致；集中为一个对象，
/// 避免在聊天页与历史弹层等多处逐参数复制导致漂移。
class MessageViewParams {
  const MessageViewParams({
    required this.visibleMessages,
    required this.inputTapRegionGroupId,
    required this.isSending,
    required this.isImpersonating,
    required this.regeneratingUserMessageId,
    required this.isDraftSession,
    required this.activeCharacter,
    required this.currentUserSetting,
    required this.sessionId,
    required this.selectedRegexRuleGroupIds,
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
  final Object inputTapRegionGroupId;
  final bool isSending;
  final bool isImpersonating;
  final String? regeneratingUserMessageId;
  final bool isDraftSession;
  final ResolvedChatCharacter? activeCharacter;
  final UserSetting? currentUserSetting;
  final String? sessionId;
  final Set<String> selectedRegexRuleGroupIds;

  final void Function(ChatMessage msg) onCopyMessage;
  final void Function(int index) onEditMessage;
  final VoidCallback onEditDraftOpeningMessage;
  final void Function(int index) onDeleteMessage;
  final void Function(int index) onRegenerateFromUserMessage;
  final void Function(int index) onRegenerateMessage;
  final void Function(int index) onContinueMessage;
  final VoidCallback onImpersonate;
  final void Function(ChatMessage message, int delta) onSwitchMessageVariant;

  /// 返回替换了消息列表的副本（历史弹层内监听刷新可见消息用）。
  MessageViewParams withVisibleMessages(List<ChatMessage> messages) {
    return MessageViewParams(
      visibleMessages: messages,
      inputTapRegionGroupId: inputTapRegionGroupId,
      isSending: isSending,
      isImpersonating: isImpersonating,
      regeneratingUserMessageId: regeneratingUserMessageId,
      isDraftSession: isDraftSession,
      activeCharacter: activeCharacter,
      currentUserSetting: currentUserSetting,
      sessionId: sessionId,
      selectedRegexRuleGroupIds: selectedRegexRuleGroupIds,
      onCopyMessage: onCopyMessage,
      onEditMessage: onEditMessage,
      onEditDraftOpeningMessage: onEditDraftOpeningMessage,
      onDeleteMessage: onDeleteMessage,
      onRegenerateFromUserMessage: onRegenerateFromUserMessage,
      onRegenerateMessage: onRegenerateMessage,
      onContinueMessage: onContinueMessage,
      onImpersonate: onImpersonate,
      onSwitchMessageVariant: onSwitchMessageVariant,
    );
  }
}
