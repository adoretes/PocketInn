import 'package:flutter/material.dart';

import '../data/api_configs.dart';
import '../models/api_config.dart';

/// 分区卡片内相邻扁平行之间的细分隔线。
Widget flatSectionDivider(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
  );
}

/// 设置页分区卡片：标题 + 副标题 + 子项列表。
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.childGap = 16,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// 标题区与子项列表之间的间距。
  final double childGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: childGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// 设置项外壳：标题/副标题 + 右侧控件或箭头。
///
/// [subtitle] 为 Widget 以支持需要监听外部状态的副标题（如 API 选择）。
/// [flat] 为 true 时去掉边框与背景，作为分区卡片内的扁平列表行使用，
/// 避免框套框的嵌套外观。
class SettingsTileShell extends StatelessWidget {
  const SettingsTileShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = false,
    this.flat = false,
  });

  final String title;
  final Widget subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              subtitle,
            ],
          ),
        ),
        ?trailing,
        if (showChevron)
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ],
    );

    if (flat) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: content,
        ),
      );
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// 开关设置项。
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.flat = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SettingsTileShell(
      title: title,
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
      flat: flat,
    );
  }
}

/// 滑杆设置项。
class SettingsSliderTile extends StatelessWidget {
  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.displayValue,
    this.flat = false,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? displayValue;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue != null
                  ? displayValue!(value)
                  : '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );

    if (flat) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: content,
      );
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: content,
      ),
    );
  }
}

/// 模型选择设置项。null 表示跟随当前选中的 API 模型。
class ModelPickerTile extends StatelessWidget {
  const ModelPickerTile({
    super.key,
    required this.title,
    required this.modelId,
    required this.onChanged,
    this.flat = false,
  });

  final String title;
  final String? modelId;
  final ValueChanged<String?> onChanged;
  final bool flat;

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<List<ApiConfig>>(
            valueListenable: apiConfigsNotifier,
            builder: (context, configs, _) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                builder: (context, scrollController) {
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          title,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.follow_the_signs_outlined),
                        title: const Text('跟随当前选中模型'),
                        subtitle: const Text('使用聊天当前选中的 API 模型'),
                        trailing: modelId == null
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () {
                          onChanged(null);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      for (final provider in configs) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            provider.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final model in provider.models)
                          ListTile(
                            dense: true,
                            title: Text(model.modelId),
                            trailing: model.id == modelId
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () {
                              onChanged(model.id);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLabel = ValueListenableBuilder<List<ApiConfig>>(
      valueListenable: apiConfigsNotifier,
      builder: (context, configs, _) {
        // 已删除的模型 id 明确提示，避免被误认为「跟随当前选中模型」。
        final entry = findModelEntryById(modelId, configs);
        final String label;
        final Color labelColor;
        if (entry != null) {
          label = '${entry.provider.name} · ${entry.model.modelId}';
          labelColor = colorScheme.onSurfaceVariant;
        } else if (modelId != null) {
          label = '已选择的模型已被删除，将回退到当前选中模型';
          labelColor = colorScheme.error;
        } else {
          label = '跟随当前选中模型';
          labelColor = colorScheme.onSurfaceVariant;
        }
        return Text(label, style: TextStyle(fontSize: 13, color: labelColor));
      },
    );

    return SettingsTileShell(
      title: title,
      subtitle: currentLabel,
      onTap: () => _showPicker(context),
      showChevron: true,
      flat: flat,
    );
  }
}

/// 自定义提示词设置项。
///
/// [prompt] 为空串表示未自定义（使用内置默认）；「恢复默认」通过
/// [onChanged] 传回空串。保存时传回去除首尾空白后的文本。
class PromptEditorTile extends StatelessWidget {
  const PromptEditorTile({
    super.key,
    required this.title,
    required this.dialogTitle,
    required this.prompt,
    required this.defaultPrompt,
    required this.onChanged,
    this.defaultSubtitle = '默认',
    this.customSubtitle = '已自定义',
    this.hintText,
    this.minLines = 6,
    this.flat = false,
  });

  final String title;
  final String dialogTitle;
  final String prompt;
  final String defaultPrompt;
  final ValueChanged<String> onChanged;
  final String defaultSubtitle;
  final String customSubtitle;
  final String? hintText;
  final int minLines;
  final bool flat;

  void _showEditDialog(BuildContext context) {
    final hasCustom = prompt.trim().isNotEmpty;
    final controller = TextEditingController(
      text: hasCustom ? prompt : defaultPrompt,
    );
    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Text(dialogTitle),
          content: SizedBox(
            width: 520,
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: minLines,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                onChanged('');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('恢复默认'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null && context.mounted) {
        onChanged(result.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustom = prompt.trim().isNotEmpty;

    return SettingsTileShell(
      title: title,
      subtitle: Text(
        hasCustom ? customSubtitle : defaultSubtitle,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () => _showEditDialog(context),
      showChevron: true,
      flat: flat,
    );
  }
}
