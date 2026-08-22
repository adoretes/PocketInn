import 'dart:convert' show JsonDecoder;

/// Gal 模式选项响应解析。
///
/// 模型被要求输出 `{"choices": ["…", "…"]}` 形式的 JSON；这里做容错解析：
/// 剥离 Markdown 围栏、截取首个 JSON 对象/数组，失败时返回空列表。
List<String> parseGalChoices(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return const [];

  // 剥离 ```json … ``` 围栏。
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
  final fenceMatch = fence.firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }

  // 截取首个平衡的 JSON 对象或数组。
  final jsonText = _extractFirstJson(text);
  if (jsonText == null) return const [];

  final dynamic decoded;
  try {
    decoded = _decodeJson(jsonText);
  } catch (_) {
    return const [];
  }

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
    return const [];
  }
  if (items == null || items.isEmpty) return const [];

  final choices = <String>[];
  for (final item in items) {
    String? label;
    if (item is String) {
      label = item;
    } else if (item is Map) {
      final value = item['text'] ?? item['label'] ?? item['content'] ?? item['choice'];
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


String? _extractFirstJson(String text) {
  for (var i = 0; i < text.length; i++) {
    final open = text[i];
    if (open != '{' && open != '[') continue;
    final close = open == '{' ? '}' : ']';
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var j = i; j < text.length; j++) {
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
        if (depth == 0) {
          return text.substring(i, j + 1);
        }
      }
    }
    // 未闭合则放弃。
    return null;
  }
  return null;
}
