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
    required this.hasBackground,
    required this.backgroundAreaSize,
    required this.backgroundAreaTop,
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

  /// 当前会话是否设置了角色背景图（用于气泡毛玻璃效果）。
  final bool hasBackground;

  /// 背景图覆盖的页面 body 区域尺寸。消息列表会在遮罩层内绘制一个与
  /// 真实背景同图同尺寸同位置的对齐副本：渐隐时副本与真实背景无缝衔接，
  /// 气泡的 BackdropFilter（在 Impeller 渲染器下）才能采样到背景内容。
  /// null 表示不绘制副本（如 Gal 历史弹层等无真实背景的上下文）。
  final Size? backgroundAreaSize;

  /// 消息列表视口上边缘相对页面 body 顶部的偏移（背景副本对齐用）。
  final double backgroundAreaTop;

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
      hasBackground: hasBackground,
      backgroundAreaSize: backgroundAreaSize,
      backgroundAreaTop: backgroundAreaTop,
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

  /// 返回不绘制背景副本的副本（历史弹层等没有真实背景的上下文）。
  /// 背景副本会把角色背景图连同其半透明罩色绘入列表底部，导致弹层内
  /// 文字可读性下降。
  MessageViewParams withoutBackgroundCopy() {
    return MessageViewParams(
      visibleMessages: visibleMessages,
      inputTapRegionGroupId: inputTapRegionGroupId,
      isSending: isSending,
      isImpersonating: isImpersonating,
      regeneratingUserMessageId: regeneratingUserMessageId,
      isDraftSession: isDraftSession,
      activeCharacter: activeCharacter,
      currentUserSetting: currentUserSetting,
      hasBackground: hasBackground,
      backgroundAreaSize: null,
      backgroundAreaTop: backgroundAreaTop,
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
