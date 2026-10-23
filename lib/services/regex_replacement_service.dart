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
///
/// 列表渲染等需要对多条消息反复执行同一批规则的场景，应先用 [compile]
/// 得到 [CompiledRegexRules]，再对每条消息调用它的 `applyToMessage`，
/// 避免每条消息都重新过滤规则、重新编译正则。
class RegexReplacementService {
  const RegexReplacementService();

  /// 正则编译缓存：同一个 pattern 只编译一次；无效正则以 null 缓存，
  /// 避免每条消息重复抛异常。
  static final Map<String, RegExp?> _regexCache = <String, RegExp?>{};
  static const int _maxCachedRegexCount = 256;

  static RegExp? _compiledRegex(String pattern) {
    if (_regexCache.containsKey(pattern)) {
      return _regexCache[pattern];
    }
    RegExp? regex;
    try {
      regex = RegExp(pattern);
    } catch (_) {
      // 无效正则跳过，不阻断其他规则。
      regex = null;
    }
    if (_regexCache.length >= _maxCachedRegexCount) {
      _regexCache.clear();
    }
    _regexCache[pattern] = regex;
    return regex;
  }

  /// 预先按 [mode] 过滤并编译规则，得到可重复使用的规则集。
  ///
  /// 只保留启用、作用于某一角色、且正则有效的规则；角色与深度过滤
  /// 在执行时按消息进行，因为同一批消息里二者逐条不同。
  CompiledRegexRules compile({
    required List<RegexRuleGroup> groups,
    required RegexExecutionMode mode,
  }) {
    if (groups.isEmpty) return const CompiledRegexRules([]);

    final compiled = <CompiledRegexRule>[];
    for (final group in groups) {
      for (final rule in group.rules) {
        if (!rule.enabled) continue;
        if (!rule.applyToUser && !rule.applyToAssistant) continue;
        if (!_matchesMode(rule, mode)) continue;
        if (rule.findRegex.isEmpty) continue;

        final regex = _compiledRegex(rule.findRegex);
        if (regex == null) continue;

        compiled.add(
          CompiledRegexRule(
            regex: regex,
            replaceString: rule.replaceString,
            applyToUser: rule.applyToUser,
            applyToAssistant: rule.applyToAssistant,
            minDepth: rule.minDepth,
            maxDepth: rule.maxDepth,
          ),
        );
      }
    }

    return CompiledRegexRules(compiled);
  }

  /// 对单条消息文本应用 [groups] 中启用、且作用范围匹配的规则。
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
    return compile(groups: groups, mode: mode).applyToMessage(
      text: text,
      isUserMessage: isUserMessage,
      depth: depth,
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

    final rules = compile(groups: groups, mode: RegexExecutionMode.request);
    final total = messages.length;
    return [
      for (var i = 0; i < total; i++)
        {
          'role': messages[i]['role'],
          'content': rules
              .applyToMessage(
                text: messages[i]['content'] as String? ?? '',
                isUserMessage: messages[i]['role'] == 'user',
                depth: total - 1 - i,
              )
              .text,
        },
    ];
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
}

/// 一条已编译的规则：正则已编译，角色/深度过滤在执行时判断。
class CompiledRegexRule {
  const CompiledRegexRule({
    required this.regex,
    required this.replaceString,
    required this.applyToUser,
    required this.applyToAssistant,
    this.minDepth,
    this.maxDepth,
  });

  final RegExp regex;
  final String replaceString;
  final bool applyToUser;
  final bool applyToAssistant;
  final int? minDepth;
  final int? maxDepth;

  bool matches({required bool isUserMessage, required int depth}) {
    if (isUserMessage ? !applyToUser : !applyToAssistant) return false;
    if (minDepth != null && depth < minDepth!) return false;
    if (maxDepth != null && depth > maxDepth!) return false;
    return true;
  }

  String apply(String input) {
    return input.replaceAllMapped(
      regex,
      (match) => _interpretReplacement(replaceString, input, match),
    );
  }
}

/// 预编译好的规则集合，可对多条消息重复执行而无需再次过滤/编译。
class CompiledRegexRules {
  const CompiledRegexRules(this.rules);

  final List<CompiledRegexRule> rules;

  bool get isEmpty => rules.isEmpty;

  RegexReplacementResult applyToMessage({
    required String text,
    required bool isUserMessage,
    required int depth,
  }) {
    var result = text;
    var modified = false;
    var matched = 0;

    for (final rule in rules) {
      if (!rule.matches(isUserMessage: isUserMessage, depth: depth)) continue;
      final next = rule.apply(result);
      if (next != result) {
        result = next;
        modified = true;
        matched++;
      }
    }

    return RegexReplacementResult(
      text: result,
      modified: modified,
      matchedRules: matched,
    );
  }
}

/// 按 SillyTavern（JS）替换语义执行替换：
/// `$$` 转义为 `$`，`$&` 为完整匹配，`$`` 为匹配前文本，`$'` 为匹配后文本，
/// `$n` / `$nn` 为捕获组，`$<name>` 为命名捕获组。
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
