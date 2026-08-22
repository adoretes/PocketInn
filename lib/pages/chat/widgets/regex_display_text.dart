import 'package:flutter/material.dart';

import '../../../models/chat_message.dart';
import '../../../models/regex_rule_group.dart';
import '../../../services/regex_replacement_service.dart';
import '../../../services/regex_rule_group_service.dart';

/// 消息正文的显示替换支持。
///
/// 加载正则规则组并监听其变化，提供 [displayTextFor] 把消息原文转为
/// 显示文本。Gal 视图与普通消息列表共用，保证两种模式下正则替换
/// 行为一致。
mixin RegexDisplayTextMixin<T extends StatefulWidget> on State<T> {
  static const RegexReplacementService _regexService =
      RegexReplacementService();

  List<RegexRuleGroup> _displayRuleGroups = const [];

  @override
  void initState() {
    super.initState();
    _loadDisplayRuleGroups();
    RegexRuleGroupService.instance.changeNotifier.addListener(
      _loadDisplayRuleGroups,
    );
  }

  @override
  void dispose() {
    RegexRuleGroupService.instance.changeNotifier.removeListener(
      _loadDisplayRuleGroups,
    );
    super.dispose();
  }

  Future<void> _loadDisplayRuleGroups() async {
    final groups = await RegexRuleGroupService.instance.loadAll();
    if (mounted) {
      setState(() {
        _displayRuleGroups = groups;
      });
    }
  }

  /// [depth] 为该消息距最新一条消息的距离（最新一条为 0）。
  String displayTextFor(ChatMessage msg, int depth, Set<String> selectedIds) {
    if (_displayRuleGroups.isEmpty) return msg.text;
    final groups = selectedIds.isEmpty
        ? const <RegexRuleGroup>[]
        : _displayRuleGroups
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
}
