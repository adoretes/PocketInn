import 'package:flutter/material.dart';

import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../models/api_config.dart';
import '../models/chat_memory.dart';
import '../services/chat_memory_service.dart';
import 'custom_theme/custom_theme_page.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('通用设置')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ColorModeDropdownTile(
                value: settings.colorMode,
                onChanged: (mode) => updateAppSettings(colorMode: mode),
              ),
              const SizedBox(height: 16),
              _ThemePresetDropdownTile(
                settings: settings,
                onChanged: (preset) => updateAppSettings(themePreset: preset),
              ),
              const SizedBox(height: 16),
              _NavigationSectionCard(
                title: '主题配置',
                subtitle: '编辑当前主题的颜色、引号、阴影、文本样式',
                icon: Icons.palette_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomThemePage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '聊天显示',
                subtitle: '自定义聊天界面显示选项',
                child: Column(
                  children: [
                    _SwitchTile(
                      title: '显示头像',
                      subtitle: '在消息旁边显示用户和角色头像',
                      value: settings.showAvatar,
                      onChanged: (value) =>
                          updateAppSettings(showAvatar: value),
                    ),
                    const SizedBox(height: 12),
                    _SliderTile(
                      title: '背景透明度',
                      subtitle: '调整角色背景图片的遮罩透明度',
                      value: settings.backgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) =>
                          updateAppSettings(backgroundOpacity: value),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: '输入框毛玻璃效果',
                      subtitle: '有角色背景时输入框使用半透明毛玻璃效果',
                      value: settings.inputGlassEffect,
                      onChanged: (value) =>
                          updateAppSettings(inputGlassEffect: value),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: '气泡毛玻璃效果',
                      subtitle: '有角色背景时用户气泡与 Gal 模式对话框、选项使用毛玻璃效果',
                      value: settings.bubbleGlassEffect,
                      onChanged: (value) =>
                          updateAppSettings(bubbleGlassEffect: value),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: '显示 API 请求日志入口',
                      subtitle: '在 API 状态弹窗中显示最近请求日志入口',
                      value: settings.showApiRequestLogEntry,
                      onChanged: (value) =>
                          updateAppSettings(showApiRequestLogEntry: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Gal 模式',
                subtitle: '视觉小说选项生成配置',
                child: Column(
                  children: [
                    _SwitchTile(
                      title: '自动生成选项',
                      subtitle: '角色回复后自动生成选项，关闭后仅可通过刷新按钮手动生成',
                      value: settings.galChoiceAutoGenerate,
                      onChanged: (value) =>
                          updateAppSettings(galChoiceAutoGenerate: value),
                    ),
                    const SizedBox(height: 12),
                    _SliderTile(
                      title: '选项数量',
                      subtitle: '每次生成的玩家选项数量',
                      value: settings.galChoiceCount.toDouble(),
                      min: kGalChoiceCountMin.toDouble(),
                      max: kGalChoiceCountMax.toDouble(),
                      divisions: kGalChoiceCountMax - kGalChoiceCountMin,
                      displayValue: (value) => '${value.toInt()} 个',
                      onChanged: (value) =>
                          updateAppSettings(galChoiceCount: value.toInt()),
                    ),
                    const SizedBox(height: 12),
                    _GalChoiceApiTile(modelId: settings.galChoiceApiModelId),
                    const SizedBox(height: 12),
                    _GalChoicePromptTile(prompt: settings.galChoicePrompt),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsPlaceholderPage extends StatelessWidget {
  const SettingsPlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 34, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorModeDropdownTile extends StatelessWidget {
  const _ColorModeDropdownTile({required this.value, required this.onChanged});

  final AppColorMode value;
  final ValueChanged<AppColorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '颜色模式',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '切换应用的亮暗外观',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 140),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppColorMode>(
                  value: value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  focusColor: Colors.transparent,
                  dropdownColor: colorScheme.surface,
                  iconEnabledColor: colorScheme.onSurfaceVariant,
                  items: AppColorMode.values.map((mode) {
                    return DropdownMenuItem<AppColorMode>(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            switch (mode) {
                              AppColorMode.system =>
                                Icons.brightness_auto_outlined,
                              AppColorMode.dark => Icons.dark_mode_outlined,
                              AppColorMode.light => Icons.light_mode_outlined,
                            },
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Text(mode.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      onChanged(mode);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePresetDropdownTile extends StatelessWidget {
  const _ThemePresetDropdownTile({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppThemePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '预设主题',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '切换当前使用的主题配置',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 140),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppThemePreset>(
                  value: settings.themePreset,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  focusColor: Colors.transparent,
                  dropdownColor: colorScheme.surface,
                  iconEnabledColor: colorScheme.onSurfaceVariant,
                  items: AppThemePreset.values.map((preset) {
                    final swatchColor = resolveThemeColor(
                      settings,
                      preset: preset,
                    );
                    return DropdownMenuItem<AppThemePreset>(
                      value: preset,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  swatchColor.withValues(alpha: 0.95),
                                  swatchColor.withValues(alpha: 0.62),
                                ],
                              ),
                              border: Border.all(
                                color: swatchColor.withValues(alpha: 0.24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(preset.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (preset) {
                    if (preset != null) {
                      onChanged(preset);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationSectionCard extends StatelessWidget {
  const _NavigationSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemorySettingsCard extends StatelessWidget {
  const MemorySettingsCard({super.key, required this.memoryConfig});

  final MemoryExtractionConfig memoryConfig;

  @override
  Widget build(BuildContext context) {
    final apiConfigs = apiConfigsNotifier.value;

    return _SectionCard(
      title: '长期记忆',
      subtitle: '自动提取对话中的关键信息，在后续对话中作为上下文参考',
      child: Column(
        children: [
          _SwitchTile(
            title: '启用长期记忆',
            subtitle: '系统自动提取和管理记忆点',
            value: memoryConfig.enabled,
            onChanged: (value) => updateMemoryExtractionConfig(enabled: value),
          ),
          if (memoryConfig.enabled) ...[
            const SizedBox(height: 12),
            _SliderTile(
              title: '提取间隔',
              subtitle: '每 X 轮对话提取一次记忆',
              value: memoryConfig.interval.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              displayValue: (v) => '${v.toInt()} 轮',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(interval: value.toInt()),
            ),
            const SizedBox(height: 12),
            _SliderTile(
              title: '最近对话轮数',
              subtitle: '拼入提示词的最近 N 轮对话',
              value: memoryConfig.recentRounds.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              displayValue: (v) => v.toInt() == 0 ? '无限制' : '${v.toInt()} 轮',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(recentRounds: value.toInt()),
            ),
            const SizedBox(height: 12),
            _SliderTile(
              title: '记忆节点数',
              subtitle: '拼入提示词的历史记忆节点数量',
              value: memoryConfig.recallCount.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              displayValue: (v) => v.toInt() == 0 ? '无限制' : '${v.toInt()} 个',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(recallCount: value.toInt()),
            ),
            if (apiConfigs.any((c) => c.models.isNotEmpty)) ...[
              const SizedBox(height: 12),
              _ExtractionModelSelector(
                apiConfigs: apiConfigs,
                selectedModelId: memoryConfig.extractionModelId,
                onChanged: (id) =>
                    updateMemoryExtractionConfig(extractionModelId: id),
              ),
            ],
            const SizedBox(height: 12),
            _CustomExtractionPromptTile(
              prompt: memoryConfig.customExtractionPrompt,
              onChanged: (value) =>
                  updateMemoryExtractionConfig(customExtractionPrompt: value),
            ),
            const SizedBox(height: 12),
            _CustomInjectionPromptTile(
              prompt: memoryConfig.customInjectionPrompt,
              onChanged: (value) =>
                  updateMemoryExtractionConfig(customInjectionPrompt: value),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomExtractionPromptTile extends StatelessWidget {
  const _CustomExtractionPromptTile({
    required this.prompt,
    required this.onChanged,
  });

  final String prompt;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustom = prompt.trim().isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasCustom
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.edit_note_outlined,
                  size: 20,
                  color: hasCustom
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '提取提示词',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCustom ? '已使用自定义提示词' : '点击编辑自定义提取提示词',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final initialText = prompt.isNotEmpty
        ? prompt
        : ChatMemoryService.memoryExtractionPrompt;
    final controller = TextEditingController(text: initialText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑提取提示词'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: '输入 System Prompt，指导 AI 如何提取记忆...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged('');
              Navigator.of(context).pop();
            },
            child: const Text('恢复默认'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      onChanged(result.trim());
    }
  }
}

class _CustomInjectionPromptTile extends StatelessWidget {
  const _CustomInjectionPromptTile({
    required this.prompt,
    required this.onChanged,
  });

  final String prompt;
  final ValueChanged<String> onChanged;

  static const String _defaultInjectionPrompt = '以下是角色记得的关于过去事件的信息：';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustom = prompt.trim().isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasCustom
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.input,
                  size: 20,
                  color: hasCustom
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '注入提示词',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCustom ? '已使用自定义注入提示词' : '点击编辑记忆注入时的提示词',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final initialText = prompt.isNotEmpty ? prompt : _defaultInjectionPrompt;
    final controller = TextEditingController(text: initialText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑注入提示词'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '输入记忆注入时使用的引导语...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged('');
              Navigator.of(context).pop();
            },
            child: const Text('恢复默认'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      onChanged(result.trim());
    }
  }
}

class _ExtractionModelSelector extends StatelessWidget {
  const _ExtractionModelSelector({
    required this.apiConfigs,
    this.selectedModelId,
    required this.onChanged,
  });

  final List<ApiConfig> apiConfigs;
  final String? selectedModelId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 收集所有 (provider, model) 对，用于下拉项展示
    final entries = flattenModelEntries(apiConfigs);

    // 校验当前选中的 id 是否仍有效，无效则视为未选（回退到"当前选中模型"）
    final currentValid =
        findModelEntryById(selectedModelId, apiConfigs) != null;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '提取模型',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '默认使用当前选中的模型',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: currentValid ? selectedModelId : null,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('使用当前选中模型'),
                ),
                for (final entry in entries)
                  DropdownMenuItem<String?>(
                    value: entry.model.id,
                    child: Text(
                      '${entry.provider.name} · ${entry.model.modelId.trim().isEmpty ? '(未填写 Model ID)' : entry.model.modelId}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置项卡片外壳：圆角卡片 + 标题/副标题 + 右侧控件或箭头。
///
/// [subtitle] 为 Widget 以支持需要监听外部状态的副标题（如 API 选择）。
class _SettingTileShell extends StatelessWidget {
  const _SettingTileShell({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = false,
  });

  final String title;
  final Widget subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          child: Row(
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
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SettingTileShell(
      title: title,
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.displayValue,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? displayValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
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
        ),
      ),
    );
  }
}

/// Gal 模式选项生成专用 API 选择。null 表示跟随当前选中的 API 模型。
class _GalChoiceApiTile extends StatelessWidget {
  const _GalChoiceApiTile({required this.modelId});

  final String? modelId;

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
                          '选项生成 API',
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
                          updateAppSettings(galChoiceApiModelId: null);
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
                              updateAppSettings(galChoiceApiModelId: model.id);
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

    return _SettingTileShell(
      title: '选项生成 API',
      subtitle: currentLabel,
      onTap: () => _showPicker(context),
      showChevron: true,
    );
  }
}

/// Gal 模式选项生成自定义提示词。null 表示使用内置默认。
class _GalChoicePromptTile extends StatelessWidget {
  const _GalChoicePromptTile({required this.prompt});

  final String? prompt;

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(
      text: prompt ?? kDefaultGalChoicePrompt,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('选项生成提示词'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: 8,
              decoration: const InputDecoration(
                hintText: '支持 {{user}}、{{char}}、{{count}} 占位符',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateAppSettings(galChoicePrompt: null);
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
    );
    if (result != null) {
      final trimmed = result.trim();
      updateAppSettings(
        galChoicePrompt:
            trimmed.isEmpty || trimmed == kDefaultGalChoicePrompt.trim()
            ? null
            : trimmed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingTileShell(
      title: '自定义提示词',
      subtitle: Text(
        prompt == null ? '默认' : '已自定义',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () => _edit(context),
      showChevron: true,
    );
  }
}
