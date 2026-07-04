import 'package:flutter/material.dart';

import '../../data/app_settings.dart';
import '../../widgets/chat_markdown_body.dart';
import 'widgets/theme_font_family_tile.dart';
import 'widgets/theme_palette_picker.dart';

class CustomThemePage extends StatelessWidget {
  const CustomThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final themeConfig = resolveThemeConfig(settings);
        final chatTextTheme = themeConfig.chatTextTheme;

        return Scaffold(
          appBar: AppBar(title: const Text('主题配置')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: '主题颜色',
                child: Column(
                  children: [
                    ThemeFontFamilyConfigTile(
                      fontFamily: themeConfig.customFontFamily,
                      onChanged: (value) =>
                          updateThemeConfig(customFontFamily: value),
                    ),
                    const SizedBox(height: 12),
                    _ThemeColorPaletteTile(
                      selectedIndex: resolveThemeColorPaletteIndex(settings),
                      onChanged: (index) =>
                          updateThemeConfig(themeColorIndex: index),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '引号与阴影',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuoteStyleDropdownTile(
                      value: chatTextTheme.quoteStyle,
                      onChanged: (style) =>
                          updateChatTextThemeSettings(quoteStyle: style),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: '聊天消息字体阴影',
                      value: chatTextTheme.enableMessageTextShadow,
                      onChanged: (value) => updateChatTextThemeSettings(
                        enableMessageTextShadow: value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '文本样式',
                child: Column(
                  children: [
                    _BodyTextColorConfigTile(
                      settings: settings,
                      lightValue: chatTextTheme.bodyTextColorPaletteIndex,
                      darkValue: chatTextTheme.bodyTextColorDarkPaletteIndex,
                      onChanged: (light, dark) => updateChatTextThemeSettings(
                        bodyTextColorPaletteIndex: light,
                        bodyTextColorDarkPaletteIndex: dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TextStyleConfigTile(
                      settings: settings,
                      title: '引号内容',
                      value: chatTextTheme.quotedTextStyle,
                      onChanged: (value) =>
                          updateChatTextThemeSettings(quotedTextStyle: value),
                    ),
                    const SizedBox(height: 12),
                    _TextStyleConfigTile(
                      settings: settings,
                      title: '括号内容',
                      value: chatTextTheme.bracketTextStyle,
                      onChanged: (value) =>
                          updateChatTextThemeSettings(bracketTextStyle: value),
                    ),
                    const SizedBox(height: 12),
                    _TextStyleConfigTile(
                      settings: settings,
                      title: 'Markdown 斜体',
                      value: chatTextTheme.italicTextStyle,
                      onChanged: (value) =>
                          updateChatTextThemeSettings(italicTextStyle: value),
                    ),
                    const SizedBox(height: 12),
                    _TextStyleConfigTile(
                      settings: settings,
                      title: 'Markdown 加粗',
                      value: chatTextTheme.boldTextStyle,
                      onChanged: (value) =>
                          updateChatTextThemeSettings(boldTextStyle: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '效果预览',
                child: _ThemePreviewCard(settings: settings),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.settings});

  final AppSettings settings;

  static const String _userPreviewText =
      '请把“旅馆回声”写得更轻一些，把（动作描写）收住，再让 *尾音* 和 **关键词** 更有层次。';
  static const String _characterPreviewText =
      '她答道：「我会把月色留下。」然后略过（脚步声），只把 *语气* 放慢，再把 **结论** 说稳。';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeConfig = resolveThemeConfig(settings);
    final chatTextTheme = resolveActiveChatTextTheme(settings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                label:
                    '${chatTextTheme.quoteStyle.leading}${chatTextTheme.quoteStyle.trailing}',
                color: colorScheme.secondary,
              ),
              _PreviewChip(
                label: chatTextTheme.enableMessageTextShadow
                    ? '阴影已开启'
                    : '阴影已关闭',
                color: colorScheme.tertiary,
              ),
              _PreviewChip(
                label: themeConfig.customFontFamily != null
                    ? '自定义字体: ${themeConfig.customFontFamily}'
                    : '系统字体',
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: ChatMarkdownBody(
                    text: _userPreviewText,
                    settings: settings,
                    textColor: colorScheme.onPrimaryContainer,
                    inlineCodeColor: colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    codeBlockColor: colorScheme.primary.withValues(alpha: 0.08),
                    applyBodyTextColor: false,
                    selectable: false,
                  ),
                ),
              ),
              if (settings.showAvatar) ...[
                const SizedBox(width: 8),
                _PreviewAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  label: '我',
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (settings.showAvatar) ...[
                _PreviewAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  label: '角',
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ChatMarkdownBody(
                  text: _characterPreviewText,
                  settings: settings,
                  textColor: colorScheme.onSurface,
                  inlineCodeColor: colorScheme.surfaceContainerHigh,
                  codeBlockColor: colorScheme.surfaceContainerLow,
                  selectable: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _QuoteStyleDropdownTile extends StatelessWidget {
  const _QuoteStyleDropdownTile({required this.value, required this.onChanged});

  final AppQuoteStyle value;
  final ValueChanged<AppQuoteStyle> onChanged;

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
                    '引号',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '选择显示样式',
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
              constraints: const BoxConstraints(minWidth: 50, maxWidth: 60),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppQuoteStyle>(
                  alignment: AlignmentDirectional.center,
                  value: value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  focusColor: Colors.transparent,
                  dropdownColor: colorScheme.surface,
                  iconEnabledColor: colorScheme.onSurfaceVariant,
                  items: AppQuoteStyle.selectableValues.map((style) {
                    return DropdownMenuItem<AppQuoteStyle>(
                      value: style,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '${style.leading}${style.trailing}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (style) {
                    if (style != null) {
                      onChanged(style);
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

class _ThemeColorPaletteTile extends StatelessWidget {
  const _ThemeColorPaletteTile({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

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
                    '当前颜色',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '仅显示已选颜色，点击右侧展开完整色板',
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
            PalettePickerButton(
              selectedIndex: selectedIndex,
              onChanged: onChanged,
              swatchSize: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyTextColorConfigTile extends StatelessWidget {
  const _BodyTextColorConfigTile({
    required this.settings,
    required this.lightValue,
    required this.darkValue,
    required this.onChanged,
  });

  final AppSettings settings;
  final int? lightValue;
  final int? darkValue;
  final void Function(int? light, int? dark) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);
    final seedColor = resolveThemeColor(settings);
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final lightBackground = lightColorScheme.surfaceContainerLow;
    final darkBackground = darkColorScheme.surfaceContainerLow;
    final customEnabled = lightValue != null || darkValue != null;
    final effectiveLightIndex =
        lightValue ?? defaultBodyTextColorPaletteIndex(Brightness.light);
    final effectiveDarkIndex =
        darkValue ?? defaultBodyTextColorPaletteIndex(Brightness.dark);
    final effectiveTextColor = customEnabled
        ? (colorScheme.brightness == Brightness.dark
            ? paletteColorAt(effectiveDarkIndex)
            : paletteColorAt(effectiveLightIndex))
        : colorScheme.onSurface;
    final previewStyle = buildBaseMessageTextStyle(
      textColor: effectiveTextColor,
      brightness: colorScheme.brightness,
      enableShadow: chatTextTheme.enableMessageTextShadow,
    );

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '正文颜色',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customEnabled ? '使用自定义正文颜色' : '跟随当前主题正文色',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: customEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      onChanged(
                        defaultBodyTextColorPaletteIndex(Brightness.light),
                        defaultBodyTextColorPaletteIndex(Brightness.dark),
                      );
                    } else {
                      onChanged(null, null);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text('示例正文', style: previewStyle)),
                if (customEnabled) ...[
                  const SizedBox(width: 12),
                  DualPalettePickerButton(
                    lightIndex: effectiveLightIndex,
                    darkIndex: effectiveDarkIndex,
                    onChanged: (light, dark) =>
                        onChanged(light, dark),
                    swatchSize: 20,
                    lightBackground: lightBackground,
                    darkBackground: darkBackground,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextStyleConfigTile extends StatelessWidget {
  const _TextStyleConfigTile({
    required this.settings,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final AppSettings settings;
  final String title;
  final ChatTextStyleConfig value;
  final ValueChanged<ChatTextStyleConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);
    final seedColor = resolveThemeColor(settings);
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final lightBackground = lightColorScheme.surfaceContainerLow;
    final darkBackground = darkColorScheme.surfaceContainerLow;
    final previewBaseStyle = buildBaseMessageTextStyle(
      textColor: colorScheme.onSurface,
      brightness: colorScheme.brightness,
      enableShadow: chatTextTheme.enableMessageTextShadow,
    );
    final previewStyle = buildDecoratedChatTextStyle(
      baseStyle: previewBaseStyle,
      config: value,
      brightness: colorScheme.brightness,
    );

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
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text('示例文本', style: previewStyle)),
                const SizedBox(width: 12),
                DualPalettePickerButton(
                  lightIndex: value.paletteIndex,
                  darkIndex: value.darkPaletteIndex ?? value.paletteIndex,
                  onChanged: (light, dark) =>
                      onChanged(value.copyWith(
                        paletteIndex: light,
                        darkPaletteIndex: dark,
                      )),
                  swatchSize: 20,
                  lightBackground: lightBackground,
                  darkBackground: darkBackground,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '样式',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChatTextFontStyleMode>(
              initialValue: value.fontStyleMode,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: ChatTextFontStyleMode.values.map((mode) {
                return DropdownMenuItem<ChatTextFontStyleMode>(
                  value: mode,
                  child: Text(mode.label),
                );
              }).toList(),
              onChanged: (next) {
                if (next != null) {
                  onChanged(value.copyWith(fontStyleMode: next));
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '透明度',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(value.opacity * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: value.opacity,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              onChanged: (next) => onChanged(value.copyWith(opacity: next)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onChanged(!value),
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
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
