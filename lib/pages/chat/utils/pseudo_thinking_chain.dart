/// 从文本开头提取伪思维链（`<think>`/`<thinking>` 标签包裹的内容），
/// 避开代码块和行内代码。
/// 返回 (提取到的内容, 清理后的文本, 是否已闭合)。
(String?, String, bool) extractPseudoThinkingChain(String text) {
  if (text.isEmpty) return (null, text, true);

  final protectedPattern = RegExp(r'```[\s\S]*?```|`[^`\n]+`', dotAll: true);
  final protectedMatches = protectedPattern.allMatches(text).toList();

  bool isProtected(int index) {
    for (final m in protectedMatches) {
      if (m.start <= index && index < m.end) return true;
    }
    return false;
  }

  final startPattern = RegExp(
    r'^\s*<(?:think|thinking)>\s*',
    caseSensitive: false,
  );
  final startMatch = startPattern.firstMatch(text);
  if (startMatch == null || isProtected(startMatch.start)) {
    return (null, text, true);
  }

  final endPattern = RegExp(r'<\/(?:think|thinking)>\s*', caseSensitive: false);
  final remaining = text.substring(startMatch.end);
  final endMatch = endPattern.firstMatch(remaining);

  if (endMatch == null) {
    final content = text.substring(startMatch.end).trim();
    final cleaned = text.substring(0, startMatch.start);
    return (content.isEmpty ? null : content, cleaned, false);
  }

  final endPos = startMatch.end + endMatch.start;
  final afterEndPos = startMatch.end + endMatch.end;

  if (isProtected(endPos)) return (null, text, true);

  final content = text.substring(startMatch.end, endPos).trim();
  final cleaned =
      text.substring(0, startMatch.start) + text.substring(afterEndPos);

  return (content.isEmpty ? null : content, cleaned, true);
}
