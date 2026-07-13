import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_request_log_service.dart';

class ApiRequestLogPage extends StatelessWidget {
  const ApiRequestLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ApiRequestLogEntry>>(
      valueListenable: ApiRequestLogService.instance.logsNotifier,
      builder: (context, logs, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('API 请求日志'),
            actions: [
              if (logs.isNotEmpty)
                IconButton(
                  tooltip: '清空日志',
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: logs.isEmpty
              ? const Center(child: Text('最近还没有 API 请求日志'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return _LogCard(entry: entry);
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空请求日志'),
          content: const Text('将删除本地保存的最近十条 API 请求日志。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (shouldClear == true) {
      await ApiRequestLogService.instance.clear();
    }
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = entry.success ? Colors.green : colorScheme.error;
    final summary = [
      '${entry.method} ${_pathLabel(entry.endpoint)}',
      if (entry.statusCode != null) 'HTTP ${entry.statusCode}',
      '${entry.durationMs} ms',
    ].join('  ·  ');

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Icon(
            entry.success ? Icons.check_circle_outline : Icons.error_outline,
            color: statusColor,
          ),
          title: Text(
            entry.configName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${_formatDateTime(entry.timestamp)}\n$summary'),
          ),
          children: [
            _FieldBlock(
              label: '模型',
              value: entry.model.isEmpty ? '未填写' : entry.model,
            ),
            const SizedBox(height: 12),
            _FieldBlock(label: '请求地址', value: entry.endpoint),
            const SizedBox(height: 12),
            entry.requestBody.isEmpty
                ? _FieldBlock(label: '请求体', value: '无', copyValue: null)
                : _CollapsibleJsonBlock(
                    label: '请求体',
                    jsonString: entry.requestBody,
                    copyValue: entry.requestBody,
                  ),
            const SizedBox(height: 12),
            _FieldBlock(
              label: '响应',
              value: entry.responseBody.isEmpty ? '无' : entry.responseBody,
              copyValue: entry.responseBody,
            ),
            if (entry.errorMessage != null &&
                entry.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _FieldBlock(
                label: '错误',
                value: entry.errorMessage!,
                copyValue: entry.errorMessage!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute:$second';
  }

  String _pathLabel(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null) {
      return endpoint;
    }
    final path = uri.path.isEmpty ? '/' : uri.path;
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
}

class _CollapsibleJsonBlock extends StatefulWidget {
  const _CollapsibleJsonBlock({
    required this.label,
    required this.jsonString,
    required this.copyValue,
  });

  final String label;
  final String jsonString;
  final String? copyValue;

  @override
  State<_CollapsibleJsonBlock> createState() => _CollapsibleJsonBlockState();
}

class _CollapsibleJsonBlockState extends State<_CollapsibleJsonBlock> {
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
          if (c == '[') { depth++; inArray = true; } else if (c == ']') {
            depth--;
            if (inArray && depth == 0) { _foldEnd = j; break; }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (widget.copyValue != null &&
                widget.copyValue!.trim().isNotEmpty)
              IconButton(
                tooltip: '复制',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.copyValue!),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('${widget.label}已复制')));
                  }
                },
                icon: const Icon(Icons.content_copy_outlined, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: _hasMessages ? 0 : 12,
            top: 12,
            right: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: _hasMessages ? _buildLines(lines, colorScheme) : SelectableText(widget.jsonString),
        ),
      ],
    );
  }

  Widget _buildLines(List<String> lines, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++)
          _buildLine(i, lines[i], colorScheme),
      ],
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
                    _collapsed ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_down_rounded,
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

  Widget _buildPlaceholderText(String text, ColorScheme colorScheme, TextStyle baseStyle) {
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

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.value, this.copyValue});

  final String label;
  final String value;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (copyValue != null && copyValue!.trim().isNotEmpty)
              IconButton(
                tooltip: '复制',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: copyValue!));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$label已复制')));
                  }
                },
                icon: const Icon(Icons.content_copy_outlined, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: SelectableText(value),
        ),
      ],
    );
  }
}
