import 'package:flutter/material.dart';

import '../../../data/api_configs.dart';
import '../../../data/app_settings.dart';
import '../../../models/api_config.dart';
import '../../../services/openai_compatible_api_service.dart';

class ApiStatusInfo {
  const ApiStatusInfo({
    required this.isChecking,
    required this.configId,
    required this.result,
  });

  final bool isChecking;
  final String? configId;
  final ApiConnectionTestResult? result;

  String labelFor(ApiConfig config) {
    if (isChecking && configId == config.id) {
      return '检查中';
    }
    if (configId != config.id || result == null) {
      return '未检查';
    }
    if (result!.success) {
      return result!.isPartial ? '部分可用' : '在线';
    }
    return '异常';
  }

  Color colorFor(ColorScheme colorScheme, ApiConfig? config) {
    if (config == null) {
      return colorScheme.outline;
    }
    if (isChecking && configId == config.id) {
      return colorScheme.primary;
    }
    if (configId != config.id || result == null) {
      return colorScheme.outline;
    }
    return result!.success
        ? (result!.isPartial ? Colors.orange : Colors.green)
        : colorScheme.error;
  }

  IconData iconFor(ApiConfig? config) {
    if (config == null) {
      return Icons.hub_outlined;
    }
    if (isChecking && configId == config.id) {
      return Icons.sync;
    }
    if (configId != config.id || result == null) {
      return Icons.help_outline;
    }
    return result!.success
        ? (result!.isPartial
              ? Icons.cloud_queue_outlined
              : Icons.cloud_done_outlined)
        : Icons.cloud_off_outlined;
  }
}

class ApiStatusChip extends StatelessWidget {
  const ApiStatusChip({super.key, required this.status, required this.config});

  final ApiStatusInfo status;
  final ApiConfig config;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = status.colorFor(colorScheme, config);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelFor(config),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}

class ApiStatusActionButton extends StatelessWidget {
  const ApiStatusActionButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final ApiStatusInfo status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = enabledApiConfig;
    final statusColor = status.colorFor(colorScheme, config);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onPressed,
        tooltip: config == null
            ? 'API：未配置'
            : 'API：${config.name}（${status.labelFor(config)}）',
        style: IconButton.styleFrom(
          foregroundColor: statusColor,
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(status.iconFor(config), size: 20),
      ),
    );
  }
}

Future<void> showApiSelectorSheet({
  required BuildContext context,
  required ApiStatusInfo Function() statusProvider,
  required bool Function() useStreamingProvider,
  required bool Function() isSendingProvider,
  required ValueChanged<bool> onStreamingChanged,
  required Future<void> Function(ApiConfig target) onSelectConfig,
  required Future<void> Function() onRefreshStatus,
  required Future<void> Function() onOpenConfigPage,
  required Future<void> Function() onOpenRequestLogPage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final screenHeight = MediaQuery.of(sheetContext).size.height;
      return StatefulBuilder(
        builder: (context, sheetSetState) {
          return SafeArea(
            child: ValueListenableBuilder<List<ApiConfig>>(
              valueListenable: apiConfigsNotifier,
              builder: (context, configs, _) {
                final currentConfig = enabledApiConfig;
                final settings = appSettingsNotifier.value;
                final status = statusProvider();
                final useStreaming = useStreamingProvider();
                final isSending = isSendingProvider();
                return SizedBox(
                  height: screenHeight * 0.6,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API 选择',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentConfig == null
                              ? '当前未启用 API 配置'
                              : '当前: ${currentConfig.name} · ${status.labelFor(currentConfig)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('流式输出'),
                          subtitle: Text(
                            useStreaming ? '实时显示回复内容' : '等待完整回复后再显示',
                          ),
                          value: useStreaming,
                          onChanged: isSending
                              ? null
                              : (value) {
                                  onStreamingChanged(value);
                                  sheetSetState(() {});
                                },
                        ),
                        const SizedBox(height: 8),
                        if (configs.isEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.hub_outlined),
                            title: const Text('暂无 API 配置'),
                            subtitle: const Text('先添加配置后才能切换和检测状态'),
                            trailing: FilledButton.tonal(
                              onPressed: () async {
                                Navigator.of(sheetContext).pop();
                                await onOpenConfigPage();
                              },
                              child: const Text('去配置'),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView(
                              children: [
                                for (final item in configs)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      item.id == currentConfig?.id
                                          ? Icons.check_circle
                                          : Icons.hub_outlined,
                                      color: item.id == currentConfig?.id
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      item.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      item.model.trim().isEmpty
                                          ? item.baseUrl
                                          : '${item.model} · ${item.baseUrl}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: item.id == currentConfig?.id
                                        ? ApiStatusChip(
                                            status: status,
                                            config: item,
                                          )
                                        : null,
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await onSelectConfig(item);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            TextButton.icon(
                              onPressed: currentConfig == null
                                  ? null
                                  : () async {
                                      Navigator.of(sheetContext).pop();
                                      await onRefreshStatus();
                                    },
                              icon: const Icon(Icons.sync),
                              label: const Text('刷新状态'),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                Navigator.of(sheetContext).pop();
                                await onOpenConfigPage();
                              },
                              icon: const Icon(Icons.settings_outlined),
                              label: const Text('管理配置'),
                            ),
                            if (settings.showApiRequestLogEntry)
                              TextButton.icon(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await onOpenRequestLogPage();
                                },
                                icon: const Icon(Icons.receipt_long_outlined),
                                label: const Text('请求日志'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
