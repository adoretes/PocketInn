import 'package:flutter/material.dart';

import '../../../models/chat_message.dart';
import '../../../models/regex_rule_group.dart';
import '../../../models/user_setting.dart';
import '../../../services/chat_character_resolver.dart';
import '../../../services/regex_rule_group_service.dart';
import '../../../services/regex_replacement_service.dart';
import '../../../widgets/scroll_float_button.dart';
import 'message_bubble.dart';

/// 聊天消息列表（含滚动浮动按钮）。
///
/// 从原 [ChatPage] 的 build 方法中拆出，负责根据可见消息列表渲染
/// [MessageBubble] 并将用户事件转发给回调。
class ChatMessageList extends StatefulWidget {
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
  final ScrollController scrollController;
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

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static const RegexReplacementService _regexService =
      RegexReplacementService();

  List<RegexRuleGroup> _ruleGroups = const [];

  @override
  void initState() {
    super.initState();
    _loadRuleGroups();
    RegexRuleGroupService.instance.changeNotifier.addListener(_loadRuleGroups);
  }

  @override
  void dispose() {
    RegexRuleGroupService.instance.changeNotifier.removeListener(
      _loadRuleGroups,
    );
    super.dispose();
  }

  Future<void> _loadRuleGroups() async {
    final groups = await RegexRuleGroupService.instance.loadAll();
    if (mounted) {
      setState(() {
        _ruleGroups = groups;
      });
    }
  }

  String _displayTextFor(ChatMessage msg, int depth) {
    if (_ruleGroups.isEmpty) return msg.text;
    final selectedIds = widget.selectedRegexRuleGroupIds;
    final groups = selectedIds.isEmpty
        ? const <RegexRuleGroup>[]
        : _ruleGroups
              .where((group) => selectedIds.contains(group.id))
              .toList();
    if (groups.isEmpty) return msg.text;
    return _regexService
        .applyToMessage(
          text: msg.text,
          groups: groups,
          isUserMessage: msg.isMe,
          depth: depth,
          mode: RegexExecutionMode.display,
        )
        .text;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visibleMessages.isEmpty) {
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
          key: ValueKey(widget.sessionId),
          controller: widget.scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: widget.visibleMessages.length,
          itemBuilder: (context, index) {
            final messageIndex = widget.visibleMessages.length - 1 - index;
            final msg = widget.visibleMessages[messageIndex];
            final isLastMessage = messageIndex == widget.visibleMessages.length - 1;
            final isLastUserMessageWithoutReply = isLastMessage && msg.isMe;
            final isLastCharacterMessage = isLastMessage && !msg.isMe;
            final isRegeneratingUserMessage =
                widget.regeneratingUserMessageId != null &&
                msg.id == widget.regeneratingUserMessageId;
            final hasPersistedMessage = msg.id != null;
            final hasDraftOpeningActions =
                widget.isDraftSession && !hasPersistedMessage && !msg.isMe;
            final showActions =
                (hasPersistedMessage || hasDraftOpeningActions) &&
                (!widget.isSending || isRegeneratingUserMessage);
            final canEditMessage =
                (hasPersistedMessage || hasDraftOpeningActions) &&
                !widget.isSending;
            final canDeleteMessage =
                hasPersistedMessage && !widget.isSending;
            final displayText = _displayTextFor(
              msg,
              widget.visibleMessages.length - 1 - messageIndex,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MessageBubble(
                key: ValueKey(msg.id ?? messageIndex),
                message: msg,
                userSetting: widget.currentUserSetting,
                character: widget.activeCharacter,
                inputTapRegionGroupId: widget.inputTapRegionGroupId,
                isLastUserMessageWithoutReply: isLastUserMessageWithoutReply,
                isLastCharacterMessage: isLastCharacterMessage,
                showActions: showActions,
                canEdit: canEditMessage,
                canDelete: canDeleteMessage,
                isBusyRegenerating: isRegeneratingUserMessage,
                isBusyImpersonating: widget.isImpersonating,
                displayText: displayText == msg.text ? null : displayText,
                onCopy: () => widget.onCopyMessage(msg),
                onEdit: hasDraftOpeningActions
                    ? widget.onEditDraftOpeningMessage
                    : () => widget.onEditMessage(messageIndex),
                onDelete: () => widget.onDeleteMessage(messageIndex),
                onGenerate:
                    isLastUserMessageWithoutReply &&
                        showActions &&
                        !isRegeneratingUserMessage
                    ? () => widget.onRegenerateFromUserMessage(messageIndex)
                    : null,
                onRegenerate: isLastCharacterMessage && showActions
                    ? () => widget.onRegenerateMessage(messageIndex)
                    : null,
                onContinue: isLastCharacterMessage && showActions
                    ? () => widget.onContinueMessage(messageIndex)
                    : null,
                onImpersonate: isLastCharacterMessage && showActions
                    ? widget.onImpersonate
                    : null,
                onSelectPreviousVariant: msg.hasMultiple
                    ? () => widget.onSwitchMessageVariant(msg, -1)
                    : null,
                onSelectNextVariant: msg.hasMultiple
                    ? () => widget.onSwitchMessageVariant(msg, 1)
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
