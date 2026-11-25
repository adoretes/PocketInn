import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_request_log_service.dart';
import 'api_request_log_context_view.dart';
import 'api_request_log_format.dart';

/// 单条 API 请求日志的详情页。
///
/// 顶部在「上下文」与「原始请求」之间切换：上下文按提示词组装顺序流式阅读，
/// 原始请求保留原有的状态、用量、请求体、响应与错误信息。
class ApiRequestLogDetailPage extends StatefulWidget {
  const ApiRequestLogDetailPage({super.key, required this.entry});

  final ApiRequestLogEntry entry;

  @override
  State<ApiRequestLogDetailPage> createState() =>
      _ApiRequestLogDetailPageState();
}

class _ApiRequestLogDetailPageState extends State<ApiRequestLogDetailPage> {
  // 0: 上下文, 1: 原始请求
  int _selectedIndex = 0;

  // 缓存两个页面，切换时只改 IndexedStack 的 index，避免重建长列表导致闪烁。
  late Widget _contextView;
  late Widget _originalRequestView;

  @override
  void initState() {
    super.initState();
    _buildTabViews();
  }

  @override
  void didUpdateWidget(covariant ApiRequestLogDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entry, widget.entry)) {
      _buildTabViews();
    }
  }

  void _buildTabViews() {
    _contextView = RepaintBoundary(
      child: ApiRequestLogContextView(entry: widget.entry),
    );
    _originalRequestView = RepaintBoundary(
      child: _OriginalRequestView(entry: widget.entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('请求详情')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DetailSwitchBar(
              selectedIndex: _selectedIndex,
              onChanged: (index) {
                if (index == _selectedIndex) {
                  return;
                }
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: IndexedStack(
                index: _selectedIndex,
                children: [_contextView, _originalRequestView],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「原始请求」页：保留详情页原有的状态、用量、请求体、响应与错误信息。
class _OriginalRequestView extends StatelessWidget {
  const _OriginalRequestView({required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final usage = entry.usage;
    final usageText = usage == null || usage.isEmpty
        ? null
        : formatApiRequestLogUsage(usage);
    final errorMessage = entry.errorMessage?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
    );
  }
}

/// 顶部状态横幅：HTTP 状态、配置、模型与思考强度、时间与耗时。
///
/// 只呈现两行紧凑信息，背景沿用按状态着色的渐变。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = entry.success ? Colors.green : colorScheme.error;
    final effort = formatApiRequestLogReasoningEffort(entry.requestBody);
    final modelText = entry.model.isEmpty ? '未填写' : entry.model;
    final modelWithEffort = effort == null || effort.isEmpty
        ? modelText
        : '$modelText · $effort';
    final metaText =
        '${formatApiRequestLogTime(entry.timestamp)} · 耗时 ${entry.durationMs} ms';

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
            colorScheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (entry.statusCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'HTTP ${entry.statusCode}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              Text(
                entry.configName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                modelWithEffort,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            metaText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
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
        color: colorScheme.surfaceContainerLowest,
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
        color: colorScheme.surfaceContainerLowest,
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
        color: colorScheme.surfaceContainerLowest,
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

/// 详情页顶部的两段式切换条：上下文 / 原始请求。
class _DetailSwitchBar extends StatelessWidget {
  const _DetailSwitchBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentPillItem(
              label: '上下文',
              selected: selectedIndex == 0,
              selectedBackground: colorScheme.secondaryContainer,
              selectedColor: colorScheme.onSecondaryContainer,
              unselectedColor: colorScheme.onSurfaceVariant,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegmentPillItem(
              label: '原始请求',
              selected: selectedIndex == 1,
              selectedBackground: colorScheme.secondaryContainer,
              selectedColor: colorScheme.onSecondaryContainer,
              unselectedColor: colorScheme.onSurfaceVariant,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentPillItem extends StatelessWidget {
  const _SegmentPillItem({
    required this.label,
    required this.selected,
    required this.selectedBackground,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedBackground;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? selectedColor : unselectedColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
