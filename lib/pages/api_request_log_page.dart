import 'package:flutter/material.dart';

import '../services/api_request_log_service.dart';
import 'api_request_log_detail_page.dart';
import 'api_request_log_format.dart';

/// API 请求日志列表页：展示最近请求摘要，点击进入单条详情。
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
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return _LogListItem(entry: entry);
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.receipt_long_outlined,
              size: 44,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '最近还没有 API 请求日志',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '发送请求后会自动记录最近十条日志',
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

/// 单条日志的摘要卡片，点击进入详情页。
class _LogListItem extends StatelessWidget {
  const _LogListItem({required this.entry});

  final ApiRequestLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = entry.success ? Colors.green : colorScheme.error;
    final metadata = [
      formatApiRequestLogTime(entry.timestamp),
      if (entry.statusCode != null) 'HTTP ${entry.statusCode}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ApiRequestLogDetailPage(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Semantics(
                label: entry.success ? '请求成功' : '请求失败',
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: statusColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.configName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.durationMs} ms',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
