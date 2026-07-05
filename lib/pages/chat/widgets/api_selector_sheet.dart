import 'package:flutter/material.dart';

import '../../../data/api_configs.dart';
import '../../../data/app_settings.dart';
import '../../../models/api_config.dart';
import '../../../services/openai_compatible_api_service.dart';

class ApiStatusInfo {
  const ApiStatusInfo({
    required this.isChecking,
    required this.modelId,
    required this.result,
  });

  final bool isChecking;
  final String? modelId;
  final ApiConnectionTestResult? result;

  String labelFor(String? targetModelId) {
    if (targetModelId == null) {
      return '未选择';
    }
    if (isChecking && modelId == targetModelId) {
      return '检查中';
    }
    if (modelId != targetModelId || result == null) {
      return '未检查';
    }
    if (result!.success) {
      return result!.isPartial ? '部分可用' : '在线';
    }
    return '异常';
  }

  Color colorFor(ColorScheme colorScheme, String? targetModelId) {
    if (targetModelId == null) {
      return colorScheme.outline;
    }
    if (isChecking && modelId == targetModelId) {
      return colorScheme.primary;
    }
    if (modelId != targetModelId || result == null) {
      return colorScheme.outline;
    }
    return result!.success
        ? (result!.isPartial ? Colors.orange : Colors.green)
        : colorScheme.error;
  }

  IconData iconFor(String? targetModelId) {
    if (targetModelId == null) {
      return Icons.hub_outlined;
    }
    if (isChecking && modelId == targetModelId) {
      return Icons.sync;
    }
    if (modelId != targetModelId || result == null) {
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
  const ApiStatusChip({
    super.key,
    required this.status,
    required this.targetModelId,
  });

  final ApiStatusInfo status;
  final String? targetModelId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = status.colorFor(colorScheme, targetModelId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelFor(targetModelId),
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
    final tuple = selectedApiModelTuple;
    final statusColor = status.colorFor(colorScheme, tuple?.model.id);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tuple == null
            ? 'API：未选择模型'
            : 'API：${tuple.provider.name} · ${tuple.model.modelId}（${status.labelFor(tuple.model.id)}）',
        style: IconButton.styleFrom(
          foregroundColor: statusColor,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.dashboard_outlined, size: 20),
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
  required Future<void> Function(String modelId) onSelectModel,
  required Future<void> Function() onRefreshStatus,
  required Future<void> Function() onOpenConfigPage,
  required Future<void> Function() onOpenRequestLogPage,
  required Future<void> Function() onOpenMemoryManager,
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
                return ValueListenableBuilder<String?>(
                  valueListenable: selectedApiModelIdNotifier,
                  builder: (context, selectedModelId, _) {
                    final settings = appSettingsNotifier.value;
                    final status = statusProvider();
                    final useStreaming = useStreamingProvider();
                    final isSending = isSendingProvider();
                    final tuple = selectedApiModelTuple;
                    final hasAnyModel = configs.any(
                      (c) => c.models.isNotEmpty,
                    );
                    return SizedBox(
                      height: screenHeight * 0.6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                leading: Icon(
                                  Icons.auto_awesome,
                                  color: colorScheme.primary,
                                ),
                                title: const Text('长期记忆'),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  await onOpenMemoryManager();
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'API 模型选择',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tuple == null
                                  ? (hasAnyModel
                                        ? '当前未选择模型'
                                        : '当前无可用模型')
                                  : '当前: ${tuple.provider.name} · ${tuple.model.modelId} · ${status.labelFor(tuple.model.id)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
                            else if (!hasAnyModel)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.smart_toy_outlined),
                                title: const Text('所有配置下都还没有模型'),
                                subtitle: const Text('请到配置页为某个 Provider 添加模型'),
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
                                    for (final provider in configs) ...[
                                      if (provider.models.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            provider.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        for (final model in provider.models)
                                          ListTile(
                                            contentPadding:
                                                EdgeInsets.zero,
                                            leading: Icon(
                                              model.id == selectedModelId
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_unchecked,
                                              color: model.id == selectedModelId
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                            title: Text(
                                              model.modelId.trim().isEmpty
                                                  ? '(未填写 Model ID)'
                                                  : model.modelId,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: model.id ==
                                                    selectedModelId
                                                ? ApiStatusChip(
                                                    status: status,
                                                    targetModelId:
                                                        model.id,
                                                  )
                                                : null,
                                            onTap: () async {
                                              Navigator.of(sheetContext).pop();
                                              await onSelectModel(model.id);
                                            },
                                          ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                TextButton.icon(
                                  onPressed: tuple == null
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
                                    icon: const Icon(
                                      Icons.receipt_long_outlined,
                                    ),
                                    label: const Text('请求日志'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}
