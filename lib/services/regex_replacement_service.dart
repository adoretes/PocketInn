import '../models/regex_rule_group.dart';

/// 执行结果：文本是否被修改。
class RegexReplacementResult {
  const RegexReplacementResult({
    required this.text,
    required this.modified,
    this.matchedRules = 0,
  });

  final String text;
  final bool modified;
  final int matchedRules;
}

/// 规则执行阶段。
enum RegexExecutionMode {
  /// 送往模型的请求副本：应用「发送」规则。
  request,

  /// 写入数据库：应用「写入」规则。
  store,

  /// 界面渲染：只应用「显示」规则。
  display,
}

/// 纯逻辑正则替换执行器。
///
/// 深度规则：从最新消息向前计数，0 为最新一条；
/// 消息的深度由调用方计算并传入。
class RegexReplacementService {
  const RegexReplacementService();

  /// 对单条消息文本应用 [rules] 中启用、且作用范围匹配的规则。
  ///
  /// [isUserMessage] 表示该消息是否属于用户角色，
  /// [depth] 为该消息的深度（0 为最新一条），
  /// [mode] 决定规则过滤方式（见 [RegexExecutionMode]）。
  RegexReplacementResult applyToMessage({
    required String text,
    required List<RegexRuleGroup> groups,
    required bool isUserMessage,
    required int depth,
    RegexExecutionMode mode = RegexExecutionMode.store,
  }) {
    var result = text;
    var modified = false;
    var matched = 0;

    for (final group in groups) {
      for (final rule in group.rules) {
        if (!rule.enabled) continue;
        if (!_matchesRole(rule, isUserMessage)) continue;
        if (!_matchesDepth(rule, depth)) continue;
        if (!_matchesMode(rule, mode)) continue;
        if (rule.findRegex.isEmpty) continue;

        final RegExp regex;
        try {
          regex = RegExp(rule.findRegex);
        } catch (_) {
          // 无效正则跳过，不阻断其他规则。
          continue;
        }

        final next = _replaceWithJsSemantics(
          input: result,
          regex: regex,
          replacement: rule.replaceString,
        );
        if (next != result) {
          result = next;
          modified = true;
          matched++;
        }
      }
    }

    return RegexReplacementResult(
      text: result,
      modified: modified,
      matchedRules: matched,
    );
  }

  /// 对送往模型的请求消息列表应用请求前规则。
  ///
  /// [messages] 为 `{'role': ..., 'content': ...}` 列表，
  /// 列表顺序即 Prompt 顺序，深度从列表末尾（最新）向前计数。
  List<Map<String, dynamic>> applyToRequestMessages({
    required List<Map<String, dynamic>> messages,
    required List<RegexRuleGroup> groups,
  }) {
    if (groups.isEmpty) return messages;

    final total = messages.length;
    return [
      for (var i = 0; i < total; i++)
        {
          'role': messages[i]['role'],
          'content': _applyToContent(
            messages[i]['content'] as String? ?? '',
            groups: groups,
            isUserMessage: _isUserRole(messages[i]['role']),
            depth: total - 1 - i,
            mode: RegexExecutionMode.request,
          ),
        },
    ];
  }

  String _applyToContent(
    String text, {
    required List<RegexRuleGroup> groups,
    required bool isUserMessage,
    required int depth,
    required RegexExecutionMode mode,
  }) {
    final result = applyToMessage(
      text: text,
      groups: groups,
      isUserMessage: isUserMessage,
      depth: depth,
      mode: mode,
    );
    return result.text;
  }

  bool _matchesRole(RegexRule rule, bool isUserMessage) {
    return isUserMessage ? rule.applyToUser : rule.applyToAssistant;
  }

  bool _matchesDepth(RegexRule rule, int depth) {
    if (rule.minDepth != null && depth < rule.minDepth!) return false;
    if (rule.maxDepth != null && depth > rule.maxDepth!) return false;
    return true;
  }

  bool _matchesMode(RegexRule rule, RegexExecutionMode mode) {
    switch (mode) {
      case RegexExecutionMode.request:
        return rule.applyOnSend;
      case RegexExecutionMode.store:
        return rule.applyOnWrite;
      case RegexExecutionMode.display:
        return rule.applyOnDisplay;
    }
  }

  bool _isUserRole(Object? role) => role == 'user';

  /// 按 SillyTavern（JS）替换语义执行替换：
  /// `$$` 转义为 `$`，`$&` 为完整匹配，`$`` 为匹配前文本，`$'` 为匹配后文本，
  /// `$n` / `$nn` 为捕获组，`$<name>` 为命名捕获组。
  String _replaceWithJsSemantics({
    required String input,
    required RegExp regex,
    required String replacement,
  }) {
    return input.replaceAllMapped(regex, (match) {
      return _interpretReplacement(replacement, input, match);
    });
  }

  String _interpretReplacement(String template, String input, Match match) {
    final sb = StringBuffer();
    var i = 0;
    while (i < template.length) {
      final ch = template[i];
      if (ch != r'$' || i + 1 >= template.length) {
        sb.write(ch);
        i++;
        continue;
      }

      final next = template[i + 1];
      if (next == r'$') {
        sb.write(r'$');
        i += 2;
        continue;
      }
      if (next == '&') {
        sb.write(match.group(0) ?? '');
        i += 2;
        continue;
      }
      if (next == '`') {
        sb.write(input.substring(0, match.start));
        i += 2;
        continue;
      }
      if (next == "'") {
        sb.write(input.substring(match.end));
        i += 2;
        continue;
      }
      if (next == '<') {
        final close = template.indexOf('>', i + 2);
        if (close > 0) {
          final name = template.substring(i + 2, close);
          if (match is RegExpMatch) {
            try {
              sb.write(match.namedGroup(name) ?? '');
              i = close + 1;
              continue;
            } catch (_) {
              // 命名组不存在时保留字面量
            }
          }
          sb.write(template.substring(i, close + 1));
          i = close + 1;
          continue;
        }
      }
      if (next.codeUnitAt(0) >= 0x30 && next.codeUnitAt(0) <= 0x39) {
        // 最多两位数字的组引用
        var j = i + 1;
        if (j + 1 < template.length &&
            template[j + 1].codeUnitAt(0) >= 0x30 &&
            template[j + 1].codeUnitAt(0) <= 0x39) {
          j++;
        }
        final digits = template.substring(i + 1, j + 1);
        var n = int.parse(digits);
        if (n > match.groupCount && digits.length > 1) {
          final first = int.parse(digits.substring(0, 1));
          if (first <= match.groupCount) {
            sb.write(match.group(first) ?? '');
            sb.write(digits.substring(1));
            i = i + 2;
            continue;
          }
        }
        if (n <= match.groupCount) {
          sb.write(match.group(n) ?? '');
        } else {
          sb.write(template.substring(i, i + 1 + digits.length));
        }
        i = i + 1 + digits.length;
        continue;
      }

      // 未知的 $x 视为字面量 $
      sb.write(ch);
      i++;
    }
    return sb.toString();
  }
}
