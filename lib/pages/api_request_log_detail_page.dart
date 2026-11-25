import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_request_log_service.dart';
import 'api_request_log_format.dart';

/// 单条 API 请求日志的详情页。
class ApiRequestLogDetailPage extends StatelessWidget {
  const ApiRequestLogDetailPage({super.key, required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final usage = entry.usage;
    final usageText = usage == null || usage.isEmpty
        ? null
        : formatApiRequestLogUsage(usage);
    final errorMessage = entry.errorMessage?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('请求详情')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusBanner(entry: entry),
          if (usageText != null) ...[
            const SizedBox(height: 20),
            _SectionTitle('用量', copyValue: usageText),
            _TextCard(text: usageText),
          ],
          const SizedBox(height: 20),
          _SectionTitle(
            '请求体',
            copyValue: entry.requestBody.isEmpty ? null : entry.requestBody,
          ),
          if (entry.requestBody.isEmpty)
            const _EmptyCard('无请求体')
          else
            _JsonCard(jsonString: entry.requestBody),
          const SizedBox(height: 20),
          _SectionTitle(
            '响应',
            copyValue: entry.responseBody.isEmpty ? null : entry.responseBody,
          ),
          entry.responseBody.isEmpty
              ? const _EmptyCard('无响应内容')
              : _TextCard(text: entry.responseBody),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('错误', copyValue: errorMessage),
            _TextCard(text: errorMessage, errorTone: true),
          ],
        ],
      ),
    );
  }
}

/// 顶部状态横幅：结果、供应商、地址、模型、时间与 HTTP 状态。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = entry.success ? Colors.green : colorScheme.error;
    final summary = [
      formatApiRequestLogTime(entry.timestamp),
      '${entry.durationMs} ms',
    ].join(' · ');
    final endpointText = entry.endpoint.isEmpty ? '未填写' : entry.endpoint;
    final modelText = entry.model.isEmpty ? '未填写' : entry.model;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.20 : 0.08,
            ),
            colorScheme.surfaceContainerLow,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.success ? Icons.check_rounded : Icons.close_rounded,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.success ? '请求成功' : '请求失败',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            entry.configName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      endpointText,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: entry.endpoint.isEmpty ? null : 'monospace',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      modelText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: entry.model.isEmpty ? null : 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (entry.statusCode != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'HTTP ${entry.statusCode}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 分组小标题，右侧可带一个复制按钮。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.copyValue});

  final String title;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCopy = copyValue != null && copyValue!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, canCopy ? 0 : 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (canCopy)
            IconButton(
              tooltip: '复制$title',
              visualDensity: VisualDensity.compact,
              onPressed: () => _copyText(context, copyValue!, label: title),
              icon: const Icon(Icons.content_copy_outlined, size: 18),
            ),
        ],
      ),
    );
  }
}

/// 纯文本内容块（响应体、错误信息等）。
class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, this.errorTone = false});

  final String text;
  final bool errorTone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorTone
              ? colorScheme.error.withValues(alpha: 0.45)
              : colorScheme.outlineVariant,
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 空内容占位块。
class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

Future<void> _copyText(
  BuildContext context,
  String value, {
  String? label,
}) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(label == null ? '已复制' : '$label已复制'),
      duration: const Duration(seconds: 1),
    ),
  );
}

/// 请求体 JSON 块，可折叠 `messages` 数组。
class _JsonCard extends StatefulWidget {
  const _JsonCard({required this.jsonString});

  final String jsonString;

  @override
  State<_JsonCard> createState() => _JsonCardState();
}

class _JsonCardState extends State<_JsonCard> {
  static const double _lineHeight = 20.0;

  bool _collapsed = true;
  bool _hasMessages = false;
  int _foldStart = 0;
  int _foldEnd = 0;
  int _messageCount = 0;
  late List<String> _allLines;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  void _parse() {
    _allLines = widget.jsonString.split('\n');
    for (int i = 0; i < _allLines.length; i++) {
      if (!_allLines[i].contains('"messages"')) continue;
      _foldStart = i;
      int depth = 0;
      bool inArray = false;
      for (int j = i; j < _allLines.length; j++) {
        for (final ch in _allLines[j].runes) {
          final c = String.fromCharCode(ch);
          if (c == '[') {
            depth++;
            inArray = true;
          } else if (c == ']') {
            depth--;
            if (inArray && depth == 0) {
              _foldEnd = j;
              break;
            }
          }
        }
        if (_foldEnd > 0) break;
      }
      if (_foldEnd > _foldStart + 1) {
        _hasMessages = true;
        for (int j = _foldStart; j <= _foldEnd && j < _allLines.length; j++) {
          if (_allLines[j].contains('"role"')) _messageCount++;
        }
      }
      break;
    }
  }

  List<String> get _visibleLines {
    if (!_hasMessages || !_collapsed) return _allLines;
    final start = _allLines[_foldStart];
    final end = _allLines[_foldEnd];
    final bp = start.indexOf('[');
    final prefix = bp >= 0 ? start.substring(0, bp + 1) : start;
    final cp = end.indexOf(']');
    final suffix = cp >= 0 ? end.substring(cp) : end;
    return [
      ..._allLines.sublist(0, _foldStart),
      '$prefix /* $_messageCount 条消息 */ $suffix',
      ..._allLines.sublist(_foldEnd + 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lines = _visibleLines;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: _hasMessages ? 0 : 14,
        top: 12,
        right: 14,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: _hasMessages
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < lines.length; i++)
                  _buildLine(i, lines[i], colorScheme),
              ],
            )
          : SelectableText(
              widget.jsonString,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: _lineHeight / 13,
                color: colorScheme.onSurface,
              ),
            ),
    );
  }

  Widget _buildLine(int index, String text, ColorScheme colorScheme) {
    final isFoldLine = index == _foldStart;
    final isPlaceholder = _hasMessages && _collapsed && isFoldLine;
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: _lineHeight / 13,
      color: colorScheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: _lineHeight,
          child: isFoldLine
              ? GestureDetector(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  child: Icon(
                    _collapsed
                        ? Icons.keyboard_arrow_right_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        Expanded(
          child: isPlaceholder
              ? _buildPlaceholderText(text, colorScheme, textStyle)
              : Text(text, style: textStyle),
        ),
      ],
    );
  }

  Widget _buildPlaceholderText(
    String text,
    ColorScheme colorScheme,
    TextStyle baseStyle,
  ) {
    final cs = text.indexOf('/*');
    final ce = text.indexOf('*/') + 2;
    if (cs < 0 || ce <= cs) return Text(text, style: baseStyle);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, cs), style: baseStyle),
          TextSpan(
            text: text.substring(cs, ce),
            style: baseStyle.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          TextSpan(text: text.substring(ce), style: baseStyle),
        ],
      ),
    );
  }
}
