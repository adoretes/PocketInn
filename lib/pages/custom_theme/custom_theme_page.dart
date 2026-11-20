import 'package:flutter/material.dart';

import '../../data/app_settings.dart';
import '../../widgets/chat_markdown_body.dart';
import 'widgets/theme_font_family_tile.dart';
import 'widgets/theme_palette_picker.dart';

/// 主题配置页。
///
/// 采用与「通用设置」一致的 Material 3 分组卡片布局：顶部常驻聊天实时预览，
/// 下方按「主题外观 / 引号与阴影 / 文本样式」分组。宽屏（≥900）时预览固定在
/// 右侧两栏排布，窄屏时预览置顶单列滚动。
class CustomThemePage extends StatelessWidget {
  const CustomThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('主题配置')),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: _buildSettingsSections(
                                  context,
                                  settings,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _LivePreviewCard(settings: settings),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    _LivePreviewCard(settings: settings),
                    const SizedBox(height: 8),
                    ..._buildSettingsSections(context, settings),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建设置区分组（窄屏嵌入主列表，宽屏放入左栏）。
  List<Widget> _buildSettingsSections(
    BuildContext context,
    AppSettings settings,
  ) {
    final themeConfig = resolveThemeConfig(settings);
    final chatTextTheme = themeConfig.chatTextTheme;

    return <Widget>[
      const _SectionHeader('主题外观'),
      _SettingsGroup(
        children: [
          _ThemeColorRow(
            selectedIndex: resolveThemeColorPaletteIndex(settings),
            onChanged: (index) => updateThemeConfig(themeColorIndex: index),
          ),
          _groupDivider(context),
          _FontFamilyRow(
            fontFamily: themeConfig.customFontFamily,
            onChanged: (value) => updateThemeConfig(customFontFamily: value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const _SectionHeader('引号与阴影'),
      _SettingsGroup(
        children: [
          _QuoteStyleRow(
            value: chatTextTheme.quoteStyle,
            onChanged: (style) =>
                updateChatTextThemeSettings(quoteStyle: style),
          ),
          _groupDivider(context),
          _ShadowSwitchRow(
            value: chatTextTheme.enableMessageTextShadow,
            onChanged: (value) =>
                updateChatTextThemeSettings(enableMessageTextShadow: value),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const _SectionHeader('文本样式'),
      _SettingsGroup(
        children: [
          _BodyTextColorRow(
            settings: settings,
            lightValue: chatTextTheme.bodyTextColorPaletteIndex,
            darkValue: chatTextTheme.bodyTextColorDarkPaletteIndex,
            onChanged: (light, dark) => updateChatTextThemeSettings(
              bodyTextColorPaletteIndex: light,
              bodyTextColorDarkPaletteIndex: dark,
            ),
          ),
          _groupDivider(context),
          _TextStyleRow(
            settings: settings,
            title: '引号内容',
            icon: Icons.format_quote_rounded,
            value: chatTextTheme.quotedTextStyle,
            onChanged: (value) =>
                updateChatTextThemeSettings(quotedTextStyle: value),
          ),
          _groupDivider(context),
          _TextStyleRow(
            settings: settings,
            title: '括号内容',
            icon: Icons.code_rounded,
            value: chatTextTheme.bracketTextStyle,
            onChanged: (value) =>
                updateChatTextThemeSettings(bracketTextStyle: value),
          ),
          _groupDivider(context),
          _TextStyleRow(
            settings: settings,
            title: 'Markdown 斜体',
            icon: Icons.format_italic_rounded,
            value: chatTextTheme.italicTextStyle,
            onChanged: (value) =>
                updateChatTextThemeSettings(italicTextStyle: value),
          ),
          _groupDivider(context),
          _TextStyleRow(
            settings: settings,
            title: 'Markdown 加粗',
            icon: Icons.format_bold_rounded,
            value: chatTextTheme.boldTextStyle,
            onChanged: (value) =>
                updateChatTextThemeSettings(boldTextStyle: value),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }
}

// ---------------------------------------------------------------------------
// 实时预览
// ---------------------------------------------------------------------------

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({required this.settings});

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
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.45),
            colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.visibility_outlined,
                  size: 19,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '实时预览',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '下方设置会即时反映到示例对话中',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resolveThemeColor(settings),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                    ? '字体: ${themeConfig.customFontFamily}'
                    : '系统字体',
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ChatMarkdownBody(
                    text: _characterPreviewText,
                    settings: settings,
                    textColor: colorScheme.onSurface,
                    inlineCodeColor: colorScheme.surfaceContainerHigh,
                    codeBlockColor: colorScheme.surfaceContainerLow,
                    selectable: false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 分区与行：颜色
// ---------------------------------------------------------------------------

class _ThemeColorRow extends StatelessWidget {
  const _ThemeColorRow({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const _LeadingIcon(Icons.palette_outlined),
      title: const Text(
        '主题色',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '点击右侧色板选择主题主色',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: PalettePickerButton(
        selectedIndex: selectedIndex,
        onChanged: onChanged,
        swatchSize: 24,
      ),
    );
  }
}

class _FontFamilyRow extends StatelessWidget {
  const _FontFamilyRow({required this.fontFamily, required this.onChanged});

  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  void _showFontEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '自定义字体',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '输入字体族名称，或加载 .ttf / .otf 字体文件',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ThemeFontFamilyConfigTile(
                  fontFamily: fontFamily,
                  onChanged: onChanged,
                  flat: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFont = fontFamily != null && fontFamily!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const _LeadingIcon(Icons.font_download_outlined),
      title: const Text(
        '自定义字体',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          hasFont ? '当前：$fontFamily' : '系统默认字体',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => _showFontEditor(context),
    );
  }
}

// ---------------------------------------------------------------------------
// 分区与行：引号与阴影
// ---------------------------------------------------------------------------

class _QuoteStyleRow extends StatelessWidget {
  const _QuoteStyleRow({required this.value, required this.onChanged});

  final AppQuoteStyle value;
  final ValueChanged<AppQuoteStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const _LeadingIcon(Icons.format_quote_rounded),
      title: const Text(
        '引号样式',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '选择引号的显示样式',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 54, maxWidth: 64),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppQuoteStyle>(
            value: value,
            isExpanded: true,
            alignment: AlignmentDirectional.centerEnd,
            borderRadius: BorderRadius.circular(16),
            focusColor: Colors.transparent,
            dropdownColor: colorScheme.surface,
            iconEnabledColor: colorScheme.onSurfaceVariant,
            items: AppQuoteStyle.selectableValues.map((style) {
              return DropdownMenuItem<AppQuoteStyle>(
                value: style,
                child: Text(
                  '${style.leading}${style.trailing}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
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
    );
  }
}

class _ShadowSwitchRow extends StatelessWidget {
  const _ShadowSwitchRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const _LeadingIcon(Icons.auto_awesome_outlined),
      title: const Text(
        '聊天消息字体阴影',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '为正文文字增加柔和投影，提升可读性',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

// ---------------------------------------------------------------------------
// 分区与行：文本样式
// ---------------------------------------------------------------------------

class _BodyTextColorRow extends StatelessWidget {
  const _BodyTextColorRow({
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadingIcon(Icons.text_format_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正文颜色',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customEnabled ? '使用自定义正文颜色' : '跟随当前主题正文色',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
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
          if (customEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('示例正文', style: previewStyle)),
                const SizedBox(width: 12),
                DualPalettePickerButton(
                  lightIndex: effectiveLightIndex,
                  darkIndex: effectiveDarkIndex,
                  onChanged: (light, dark) => onChanged(light, dark),
                  swatchSize: 20,
                  lightBackground: lightColorScheme.surfaceContainerLow,
                  darkBackground: darkColorScheme.surfaceContainerLow,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TextStyleRow extends StatelessWidget {
  const _TextStyleRow({
    required this.settings,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final AppSettings settings;
  final String title;
  final IconData icon;
  final ChatTextStyleConfig value;
  final ValueChanged<ChatTextStyleConfig> onChanged;

  void _showEditor(BuildContext context) {
    final seedColor = resolveThemeColor(settings);
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    showModalBottomSheet<ChatTextStyleConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _TextStyleEditorSheet(
          title: title,
          initial: value,
          settings: settings,
          lightBackground: lightColorScheme.surfaceContainerLow,
          darkBackground: darkColorScheme.surfaceContainerLow,
        );
      },
    ).then((result) {
      if (result != null) {
        onChanged(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _LeadingIcon(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${value.fontStyleMode.label} · ${(value.opacity * 100).round()}%',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('示例', style: previewStyle.copyWith(fontSize: 15)),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () => _showEditor(context),
    );
  }
}

class _TextStyleEditorSheet extends StatefulWidget {
  const _TextStyleEditorSheet({
    required this.title,
    required this.initial,
    required this.settings,
    required this.lightBackground,
    required this.darkBackground,
  });

  final String title;
  final ChatTextStyleConfig initial;
  final AppSettings settings;
  final Color lightBackground;
  final Color darkBackground;

  @override
  State<_TextStyleEditorSheet> createState() => _TextStyleEditorSheetState();
}

class _TextStyleEditorSheetState extends State<_TextStyleEditorSheet> {
  late ChatTextStyleConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initial;
  }

  TextStyle get _previewStyle {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(widget.settings);
    final baseStyle = buildBaseMessageTextStyle(
      textColor: colorScheme.onSurface,
      brightness: colorScheme.brightness,
      enableShadow: chatTextTheme.enableMessageTextShadow,
    );
    return buildDecoratedChatTextStyle(
      baseStyle: baseStyle,
      config: _config,
      brightness: colorScheme.brightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '编辑「${widget.title}」',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text('示例文本 Aa 123', style: _previewStyle),
            ),
            const SizedBox(height: 18),
            _EditorLabel('颜色（浅色 / 深色）'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: DualPalettePickerButton(
                lightIndex: _config.paletteIndex,
                darkIndex: _config.darkPaletteIndex ?? _config.paletteIndex,
                onChanged: (light, dark) => setState(() {
                  _config = _config.copyWith(
                    paletteIndex: light,
                    darkPaletteIndex: dark,
                  );
                }),
                swatchSize: 22,
                lightBackground: widget.lightBackground,
                darkBackground: widget.darkBackground,
              ),
            ),
            const SizedBox(height: 18),
            _EditorLabel('样式'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChatTextFontStyleMode>(
                segments: [
                  for (final mode in ChatTextFontStyleMode.values)
                    ButtonSegment<ChatTextFontStyleMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                ],
                selected: {_config.fontStyleMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() {
                  _config = _config.copyWith(fontStyleMode: selection.first);
                }),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _EditorLabel('透明度'),
                Text(
                  '${(_config.opacity * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _config.opacity,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              onChanged: (next) => setState(() {
                _config = _config.copyWith(opacity: next);
              }),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_config),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorLabel extends StatelessWidget {
  const _EditorLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 通用视觉组件
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
