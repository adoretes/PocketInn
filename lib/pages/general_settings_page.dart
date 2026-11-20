import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import 'custom_theme/custom_theme_page.dart';

/// 通用设置页：Material 3 风格的设置列表。
///
/// 采用 M3 的「分组卡片 + ListTile」布局：分区小标题使用主题色，
/// 每个设置项统一为左侧图标徽标、标题/副标题、右侧控件的结构。
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              const _SectionHeader('外观与主题'),
              _SettingsGroup(
                children: [
                  _ColorModeRow(
                    value: settings.colorMode,
                    onChanged: (mode) => updateAppSettings(colorMode: mode),
                  ),
                  _groupDivider(context),
                  _ThemePresetRow(
                    settings: settings,
                    onTap: () => _showThemePresetPicker(context),
                  ),
                  _groupDivider(context),
                  _NavigationRow(
                    icon: Icons.color_lens_outlined,
                    title: '主题配置',
                    subtitle: '编辑当前主题的颜色、文本样式等',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CustomThemePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _SectionHeader('聊天显示'),
              _SettingsGroup(
                children: [
                  _SwitchRow(
                    icon: Icons.account_circle_outlined,
                    title: '显示头像',
                    subtitle: '在消息旁边显示用户和角色头像',
                    value: settings.showAvatar,
                    onChanged: (value) => updateAppSettings(showAvatar: value),
                  ),
                  _groupDivider(context),
                  _SliderRow(
                    icon: Icons.opacity_outlined,
                    title: '背景透明度',
                    subtitle: '调整角色背景图片的遮罩透明度',
                    value: settings.backgroundOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) =>
                        updateAppSettings(backgroundOpacity: value),
                  ),
                  _groupDivider(context),
                  _SwitchRow(
                    icon: Icons.blur_on_outlined,
                    title: '输入框毛玻璃效果',
                    subtitle: '有角色背景时输入框使用半透明毛玻璃效果',
                    value: settings.inputGlassEffect,
                    onChanged: (value) =>
                        updateAppSettings(inputGlassEffect: value),
                  ),
                  _groupDivider(context),
                  _SwitchRow(
                    icon: Icons.bubble_chart_outlined,
                    title: '气泡毛玻璃效果',
                    subtitle: '用户气泡与 Gal 模式对话框、选项使用毛玻璃效果',
                    value: settings.bubbleGlassEffect,
                    onChanged: (value) =>
                        updateAppSettings(bubbleGlassEffect: value),
                  ),
                  _groupDivider(context),
                  _SwitchRow(
                    icon: Icons.receipt_long_outlined,
                    title: '显示 API 请求日志入口',
                    subtitle: '在 API 状态弹窗中显示最近请求日志入口',
                    value: settings.showApiRequestLogEntry,
                    onChanged: (value) =>
                        updateAppSettings(showApiRequestLogEntry: value),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 底部弹出式预设主题选择器（M3 列表 + 勾选标记）。
  void _showThemePresetPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<AppSettings>(
            valueListenable: appSettingsNotifier,
            builder: (context, current, _) {
              final textTheme = Theme.of(context).textTheme;
              final colorScheme = Theme.of(context).colorScheme;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Text(
                        '预设主题',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final preset in AppThemePreset.values)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        leading: _ThemeSwatch(
                          color: resolveThemeColor(current, preset: preset),
                          size: 26,
                        ),
                        title: Text(preset.label),
                        trailing: preset == current.themePreset
                            ? Icon(
                                Icons.check_rounded,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          updateAppSettings(themePreset: preset);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 视觉组件
// ---------------------------------------------------------------------------

/// 分区小标题，M3 设置页常见的主题色 label。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// 分组卡片：圆角容器内承载一组设置行。
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// 分组内相邻行之间的分隔线，缩进与文字对齐。
Widget _groupDivider(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    thickness: 1,
    indent: 72,
    endIndent: 16,
    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
  );
}

/// 行首的圆角图标徽标。
class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: colorScheme.primary),
    );
  }
}

/// 主题色圆形色板。
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.62),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
    );
  }
}

/// 颜色模式行：标题 + 分段按钮（M3 SegmentedButton）。
class _ColorModeRow extends StatelessWidget {
  const _ColorModeRow({required this.value, required this.onChanged});

  final AppColorMode value;
  final ValueChanged<AppColorMode> onChanged;

  IconData _iconFor(AppColorMode mode) {
    return switch (mode) {
      AppColorMode.system => Icons.brightness_auto_outlined,
      AppColorMode.dark => Icons.dark_mode_outlined,
      AppColorMode.light => Icons.light_mode_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadingIcon(Icons.brightness_6_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '颜色模式',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '切换应用的亮暗外观',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppColorMode>(
              segments: [
                for (final mode in AppColorMode.values)
                  ButtonSegment<AppColorMode>(
                    value: mode,
                    icon: Icon(_iconFor(mode), size: 15),
                    label: Text(mode.label, maxLines: 1, softWrap: false),
                  ),
              ],
              selected: {value},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onChanged(selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 预设主题行：点击弹出底部选择器。
class _ThemePresetRow extends StatelessWidget {
  const _ThemePresetRow({required this.settings, required this.onTap});

  final AppSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: const _LeadingIcon(Icons.style_outlined),
      title: Text(
        '预设主题',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '当前：${settings.themePreset.label}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeSwatch(color: resolveThemeColor(settings), size: 22),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 页面跳转行。
class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _LeadingIcon(icon),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// 开关行。
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _LeadingIcon(icon),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

/// 滑杆行：标题/副标题 + 百分比 + 滑杆。
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(value * 100).toInt()}%',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            // 轨道两端与上方文字对齐：左端缩进到标题文字处，右端贴齐内容右缘。
            padding: const EdgeInsets.only(left: 56, right: 8),
          ),
        ],
      ),
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
