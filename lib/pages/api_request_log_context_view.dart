import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/prompt_context_entry.dart';
import '../services/api_request_log_service.dart';

/// 请求日志的「上下文」视图。
///
/// 按提示词组装顺序把上下文片段排成一条连续的文本流：每段只在段首给出一行
/// 极轻量的来源 / role / 名称，正文紧随其后，不用卡片、标题或分隔线打断阅读。
class ApiRequestLogContextView extends StatelessWidget {
  const ApiRequestLogContextView({super.key, required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final fallbackEntries = entry.context.isEmpty
        ? _fallbackEntriesFromRequestBody(entry.requestBody)
        : const <PromptContextEntry>[];
    final entries = entry.context.isNotEmpty ? entry.context : fallbackEntries;

    if (entries.isEmpty) {
      return const _EmptyContext();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 22),
      children: [
        if (entry.context.isEmpty && fallbackEntries.isNotEmpty) ...[
          _FallbackNotice(colorScheme: colorScheme),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          _ContextEntryView(entry: entries[i]),
        ],
      ],
    );
  }
}

class _ContextEntryView extends StatelessWidget {
  const _ContextEntryView({required this.entry});

  final PromptContextEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EntryMetaLine(entry: entry),
        const SizedBox(height: 4),
        SelectableText(
          entry.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.65,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// 段首的轻量元信息行：来源标签 · role 标签 · 名称。
class _EntryMetaLine extends StatelessWidget {
  const _EntryMetaLine({required this.entry});

  final PromptContextEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = _roleColor(context, entry.role);
    final name = entry.name.trim();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InlineTag(
          text: entry.source.label,
          foreground: colorScheme.onSurfaceVariant,
          background: colorScheme.surfaceContainerHighest,
        ),
        _InlineTag(
          text: entry.role.trim().isEmpty ? 'unknown' : entry.role.trim(),
          foreground: roleColor,
          background: roleColor.withValues(alpha: 0.10),
        ),
        if (name.isNotEmpty)
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ),
      ],
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '该日志未记录来源信息，以下按请求体消息展示。',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyContext extends StatelessWidget {
  const _EmptyContext();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subject_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              '无上下文记录',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '该请求没有可展示的提示词上下文。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _roleColor(BuildContext context, String role) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (role.trim()) {
    case 'system':
      return isDark ? const Color(0xFFD9B56D) : const Color(0xFF8A6D3B);
    case 'user':
      return isDark ? const Color(0xFF8FD19E) : const Color(0xFF2E6F40);
    case 'assistant':
      return isDark ? const Color(0xFF9DB8E8) : const Color(0xFF3B5C8A);
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

/// 旧日志或后台子任务没有结构化上下文时，退回到请求体里的 messages。
List<PromptContextEntry> _fallbackEntriesFromRequestBody(String requestBody) {
  if (requestBody.trim().isEmpty) {
    return const <PromptContextEntry>[];
  }

  Object? decoded;
  try {
    decoded = jsonDecode(requestBody);
  } on Object {
    return const <PromptContextEntry>[];
  }
  if (decoded is! Map) {
    return const <PromptContextEntry>[];
  }

  final messages = decoded['messages'];
  if (messages is! List) {
    return const <PromptContextEntry>[];
  }

  return [
    for (final message in messages.whereType<Map>())
      if (_contentToText(message['content']).trim().isNotEmpty)
        PromptContextEntry(
          source: PromptContextSource.request,
          role: message['role']?.toString() ?? '',
          name: '',
          content: _contentToText(message['content']).trim(),
        ),
  ];
}

String _contentToText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } on Object {
    return value.toString();
  }
}
