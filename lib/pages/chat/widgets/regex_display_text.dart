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
///
/// 列表里每条消息每次 build 都会调用 [displayTextFor]，因此这里缓存
/// 预编译规则集与已计算的显示文本，只在规则组、所选规则组或消息内容
/// 变化时重新执行正则。
mixin RegexDisplayTextMixin<T extends StatefulWidget> on State<T> {
  static const RegexReplacementService _regexService =
      RegexReplacementService();

  /// 显示文本缓存上限，超出后整体清空（消息列表通常远小于该值）。
  static const int _maxCachedTexts = 1000;

  List<RegexRuleGroup> _displayRuleGroups = const [];

  /// 编译所依据的规则组列表（引用比较，列表更新即失效）。
  List<RegexRuleGroup>? _compiledGroups;

  /// 编译所依据的所选规则组 id 集合标识。
  String? _compiledSelection;

  CompiledRegexRules _displayRules = const CompiledRegexRules([]);

  final Map<Object, String> _displayTextCache = <Object, String>{};

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
    _displayTextCache.clear();
    super.dispose();
  }

  Future<void> _loadDisplayRuleGroups() async {
    final groups = await RegexRuleGroupService.instance.loadAll();
    if (!mounted) return;
    // 规则内容未变时不重建列表，避免整列表重跑一遍 displayTextFor。
    if (_sameGroups(groups, _displayRuleGroups)) return;
    setState(() {
      _displayRuleGroups = groups;
    });
  }

  bool _sameGroups(List<RegexRuleGroup> a, List<RegexRuleGroup> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].updatedAt != b[i].updatedAt) {
        return false;
      }
    }
    return true;
  }

  /// [depth] 为该消息距最新一条消息的距离（最新一条为 0）。
  String displayTextFor(ChatMessage msg, int depth, Set<String> selectedIds) {
    final rules = _rulesFor(selectedIds);
    if (rules.isEmpty) return msg.text;

    // 文本内容 + 角色 + 深度 + 规则集共同决定结果，可直接命中原结果。
    final cacheKey = (msg.text, msg.isMe, depth, rules);
    final cached = _displayTextCache[cacheKey];
    if (cached != null) return cached;

    final text = rules
        .applyToMessage(text: msg.text, isUserMessage: msg.isMe, depth: depth)
        .text;
    if (_displayTextCache.length >= _maxCachedTexts) {
      _displayTextCache.clear();
    }
    _displayTextCache[cacheKey] = text;
    return text;
  }

  /// 取得当前所选规则组的预编译规则集，无变化时复用上一次编译结果。
  CompiledRegexRules _rulesFor(Set<String> selectedIds) {
    if (_displayRuleGroups.isEmpty || selectedIds.isEmpty) {
      return const CompiledRegexRules([]);
    }

    final selectionKey = _selectionKey(selectedIds);
    if (identical(_compiledGroups, _displayRuleGroups) &&
        _compiledSelection == selectionKey) {
      return _displayRules;
    }

    final groups = _displayRuleGroups
        .where((group) => selectedIds.contains(group.id))
        .toList(growable: false);

    _compiledGroups = _displayRuleGroups;
    _compiledSelection = selectionKey;
    _displayRules = groups.isEmpty
        ? const CompiledRegexRules([])
        : _regexService.compile(
            groups: groups,
            mode: RegexExecutionMode.display,
          );
    _displayTextCache.clear();
    return _displayRules;
  }

  String _selectionKey(Set<String> ids) {
    final sorted = ids.toList(growable: false)..sort();
    return sorted.join('\u0000');
  }
}
