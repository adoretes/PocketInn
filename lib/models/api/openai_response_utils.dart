Object? readChoiceTextRaw(Map json, String _) {
  for (final key in const ['text', 'content']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

Object? readChoiceReasoningRaw(Map json, String _) {
  for (final key in const ['reasoning_content', 'reasoning', 'thinking']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

String extractStructuredText(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is List) {
    final buffer = <String>[];
    for (final item in value) {
      final text = extractStructuredText(item).trim();
      if (text.isNotEmpty) buffer.add(text);
    }
    return buffer.join('\n');
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in const ['text', 'content', 'value', 'output_text']) {
      final text = extractStructuredText(map[key]).trim();
      if (text.isNotEmpty) return text;
    }
  }
  return '';
}
