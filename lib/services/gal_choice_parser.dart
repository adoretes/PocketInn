import 'dart:convert' show JsonDecoder;

/// Gal 模式选项响应解析。
///
/// 模型被要求输出 `{"choices": ["…", "…"]}` 形式的 JSON；这里做容错解析：
/// 剥离 Markdown 围栏、逐个尝试文中的平衡 JSON 对象/数组块，
/// 首个能解出选项的块生效，全部失败时返回空列表。
List<String> parseGalChoices(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return const [];

  // 剥离 ```json … ``` 围栏。
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
  final fenceMatch = fence.firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }

  // 模型可能在 JSON 前后夹杂杂文（如「好的，选项{1}：{"choices": …}」），
  // 逐个尝试候选块，避免被前文的孤立花括号或非法块干扰。
  for (final jsonText in _extractJsonCandidates(text)) {
    final dynamic decoded;
    try {
      decoded = _decodeJson(jsonText);
    } catch (_) {
      continue;
    }
    final choices = _choicesFromDecoded(decoded);
    if (choices != null && choices.isNotEmpty) return choices;
  }
  return const [];
}

List<String>? _choicesFromDecoded(dynamic decoded) {
  List<dynamic>? items;
  if (decoded is List) {
    items = decoded;
  } else if (decoded is Map) {
    final candidates = const ['choices', 'options', '选项'];
    for (final key in candidates) {
      final value = decoded[key];
      if (value is List) {
        items = value;
        break;
      }
      // 也接受 {"choices": {"1": "…"}} 之类的映射形式。
      if (value is Map) {
        items = value.values.toList();
        break;
      }
    }
  } else {
    return null;
  }
  if (items == null || items.isEmpty) return null;

  final choices = <String>[];
  for (final item in items) {
    String? label;
    if (item is String) {
      label = item;
    } else if (item is Map) {
      final value =
          item['text'] ?? item['label'] ?? item['content'] ?? item['choice'];
      if (value is String) label = value;
    } else if (item is num || item is bool) {
      label = item.toString();
    }
    label = label?.trim();
    if (label != null && label.isNotEmpty) {
      choices.add(label);
    }
  }
  return choices;
}

dynamic _decodeJson(String source) {
  return const JsonDecoder().convert(source);
}

/// 收集文中最多 [maxCandidates] 个平衡的 JSON 对象/数组块。
///
/// 从左到右扫描：找到平衡块后跳到块尾继续；未闭合则从下一字符继续
/// （后文可能仍有完整块）。限制扫描次数，避免畸形长文本的二次方开销。
Iterable<String> _extractJsonCandidates(
  String text, {
  int maxCandidates = 4,
}) sync* {
  var produced = 0;
  var attempts = 0;
  var i = 0;
  while (i < text.length && produced < maxCandidates) {
    final open = text[i];
    if (open != '{' && open != '[') {
      i++;
      continue;
    }
    attempts++;
    if (attempts > maxCandidates * 2) return;
    final end = _balancedEnd(text, i);
    if (end == null) {
      i++;
      continue;
    }
    yield text.substring(i, end + 1);
    produced++;
    i = end + 1;
  }
}

/// 返回以 [start] 处 `{`/`[` 为开括号的平衡块结束下标；未闭合返回 null。
int? _balancedEnd(String text, int start) {
  final open = text[start];
  final close = open == '{' ? '}' : ']';
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var j = start; j < text.length; j++) {
    final ch = text[j];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) return j;
    }
  }
  return null;
}
