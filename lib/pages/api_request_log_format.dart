// 请求日志的展示格式化工具，供列表页与详情页共用。

import 'dart:convert';

/// 将时间格式化为 `yyyy-MM-dd HH:mm:ss`（本地时区）。
String formatApiRequestLogTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute:$second';
}

/// 从请求体 JSON 中读取 `reasoning_effort`（思考强度）。
///
/// 请求体不是合法 JSON、或未携带该字段时返回 null。
String? formatApiRequestLogReasoningEffort(String requestBody) {
  final text = requestBody.trim();
  if (text.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      final value = decoded['reasoning_effort'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  } on Object {
    // 请求体不是合法 JSON 时忽略。
  }
  return null;
}

/// 用量字段中已单独展示、无需再原样输出的键。
const Set<String> _usageHandledKeys = {
  'prompt_tokens',
  'completion_tokens',
  'total_tokens',
  'prompt_cache_hit_tokens',
  'prompt_cache_miss_tokens',
  'prompt_tokens_details',
  'completion_tokens_details',
};

/// 将 usage 字段格式化为易读的多行文本。
String formatApiRequestLogUsage(Map<String, dynamic> usage) {
  final lines = <String>[];

  final summary = <String>[
    if (usage['prompt_tokens'] != null) '输入 ${usage['prompt_tokens']}',
    if (usage['completion_tokens'] != null) '输出 ${usage['completion_tokens']}',
    if (usage['total_tokens'] != null) '合计 ${usage['total_tokens']}',
  ];
  if (summary.isNotEmpty) {
    lines.add(summary.join(' · '));
  }

  final cacheHit =
      _readNestedInt(usage, 'prompt_tokens_details', 'cached_tokens') ??
      usage['prompt_cache_hit_tokens'];
  final cacheMiss = usage['prompt_cache_miss_tokens'];
  if (cacheHit != null || cacheMiss != null) {
    lines.add(
      [
        if (cacheHit != null) '缓存命中 $cacheHit',
        if (cacheMiss != null) '缓存未命中 $cacheMiss',
      ].join(' · '),
    );
  }

  final reasoningTokens =
      _readNestedInt(usage, 'completion_tokens_details', 'reasoning_tokens') ??
      usage['reasoning_tokens'];
  if (reasoningTokens != null) {
    lines.add('思考链 $reasoningTokens');
  }

  final extraKeys = usage.keys
      .where((key) => !_usageHandledKeys.contains(key))
      .toList();
  if (extraKeys.isNotEmpty) {
    lines.add(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({for (final key in extraKeys) key: usage[key]}),
    );
  }
  return lines.join('\n');
}

int? _readNestedInt(Map<String, dynamic> usage, String section, String key) {
  final detail = usage[section];
  if (detail is Map && detail[key] is num) {
    return (detail[key] as num).toInt();
  }
  return null;
}
