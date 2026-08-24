import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../widgets/settings_controls.dart';
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
              SettingsSectionCard(
                title: '聊天显示',
                subtitle: '自定义聊天界面显示选项',
                childGap: 12,
                child: Column(
                  children: [
                    SettingsSwitchTile(
                      title: '显示头像',
                      subtitle: '在消息旁边显示用户和角色头像',
                      value: settings.showAvatar,
                      onChanged: (value) =>
                          updateAppSettings(showAvatar: value),
                      flat: true,
                    ),
                    flatSectionDivider(context),
                    SettingsSliderTile(
                      title: '背景透明度',
                      subtitle: '调整角色背景图片的遮罩透明度',
                      value: settings.backgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) =>
                          updateAppSettings(backgroundOpacity: value),
                      flat: true,
                    ),
                    flatSectionDivider(context),
                    SettingsSwitchTile(
                      title: '输入框毛玻璃效果',
                      subtitle: '有角色背景时输入框使用半透明毛玻璃效果',
                      value: settings.inputGlassEffect,
                      onChanged: (value) =>
                          updateAppSettings(inputGlassEffect: value),
                      flat: true,
                    ),
                    flatSectionDivider(context),
                    SettingsSwitchTile(
                      title: '气泡毛玻璃效果',
                      subtitle:
                          '有角色背景时用户气泡与 Gal 模式对话框、选项使用毛玻璃效果',
                      value: settings.bubbleGlassEffect,
                      onChanged: (value) =>
                          updateAppSettings(bubbleGlassEffect: value),
                      flat: true,
                    ),
                    flatSectionDivider(context),
                    SettingsSwitchTile(
                      title: '显示 API 请求日志入口',
                      subtitle: '在 API 状态弹窗中显示最近请求日志入口',
                      value: settings.showApiRequestLogEntry,
                      onChanged: (value) =>
                          updateAppSettings(showApiRequestLogEntry: value),
                      flat: true,
                    ),
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
