import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/font_service.dart';
import '../widgets/chat_markdown_body.dart';

int _safePaletteIndex(int index) {
  if (index < 0) {
    return 0;
  }
  if (index >= customThemePalette.length) {
    return customThemePalette.length - 1;
  }
  return index;
}

Color _paletteColorAt(int index) {
  return customThemePalette[_safePaletteIndex(index)];
}

int _defaultBodyTextColorPaletteIndex(Brightness brightness) {
  return brightness == Brightness.dark ? 29 : 30;
}

const List<int> _orderedPaletteIndices = <int>[
  0,
  13,
  14,
  4,
  11,
  9,
  12,
  8,
  22,
  3,
  20,
  21,
  10,
  23,
  24,
  5,
  16,
  26,
  6,
  17,
  15,
  1,
  18,
  19,
  7,
  25,
  27,
  2,
  28,
  29,
  30,
  31,
];

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
                    _FontFamilyConfigTile(
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
                      value: chatTextTheme.bodyTextColorPaletteIndex,
                      onChanged: (value) => updateChatTextThemeSettings(
                        bodyTextColorPaletteIndex: value,
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
            _PalettePickerButton(
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
    required this.value,
    required this.onChanged,
  });

  final AppSettings settings;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);
    final customEnabled = value != null;
    final selectedIndex =
        value ?? _defaultBodyTextColorPaletteIndex(colorScheme.brightness);
    final effectiveTextColor = customEnabled
        ? _paletteColorAt(selectedIndex)
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
                    onChanged(enabled ? selectedIndex : null);
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
                  _PalettePickerButton(
                    selectedIndex: selectedIndex,
                    onChanged: onChanged,
                    swatchSize: 22,
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
    final previewBaseStyle = buildBaseMessageTextStyle(
      textColor: colorScheme.onSurface,
      brightness: colorScheme.brightness,
      enableShadow: chatTextTheme.enableMessageTextShadow,
    );
    final previewStyle = buildDecoratedChatTextStyle(
      baseStyle: previewBaseStyle,
      config: value,
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
                _PalettePickerButton(
                  selectedIndex: value.paletteIndex,
                  onChanged: (index) =>
                      onChanged(value.copyWith(paletteIndex: index)),
                  swatchSize: 22,
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

class _PalettePickerButton extends StatelessWidget {
  const _PalettePickerButton({
    required this.selectedIndex,
    required this.onChanged,
    required this.swatchSize,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double swatchSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = _paletteColorAt(selectedIndex);

    Future<void> openPalettePicker() async {
      final next = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          final sheetColorScheme = Theme.of(sheetContext).colorScheme;
          return _PalettePickerSheet(
            selectedIndex: selectedIndex,
            colorScheme: sheetColorScheme,
          );
        },
      );
      if (next != null && next != selectedIndex) {
        onChanged(next);
      }
    }

    return Semantics(
      button: true,
      label: '选择颜色',
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: openPalettePicker,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedColor,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PalettePickerSheet extends StatelessWidget {
  const _PalettePickerSheet({
    required this.selectedIndex,
    required this.colorScheme,
  });

  final int selectedIndex;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '选择颜色',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _paletteColorAt(selectedIndex),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ColorPaletteWrap(
              selectedIndex: selectedIndex,
              onChanged: (index) => Navigator.of(context).pop(index),
              activeBorderColor: colorScheme.primary,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPaletteWrap extends StatelessWidget {
  const _ColorPaletteWrap({
    required this.selectedIndex,
    required this.onChanged,
    required this.activeBorderColor,
    required this.size,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeBorderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paletteIndices = _orderedPaletteIndices
        .where((index) => index >= 0 && index < customThemePalette.length)
        .toList(growable: false);

    return GridView.count(
      crossAxisCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List<Widget>.generate(paletteIndices.length, (displayIndex) {
        final index = paletteIndices[displayIndex];
        final color = _paletteColorAt(index);
        final selected = selectedIndex == index;
        final iconColor =
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

        return InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected
                    ? activeBorderColor
                    : colorScheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: activeBorderColor.withValues(alpha: 0.24),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: size * 0.58, color: iconColor)
                : null,
          ),
        );
      }),
    );
  }
}

class _FontFamilyConfigTile extends StatefulWidget {
  const _FontFamilyConfigTile({
    required this.fontFamily,
    required this.onChanged,
  });

  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  @override
  State<_FontFamilyConfigTile> createState() => _FontFamilyConfigTileState();
}

class _FontFamilyConfigTileState extends State<_FontFamilyConfigTile> {
  late final TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.fontFamily ?? '');
  }

  @override
  void didUpdateWidget(covariant _FontFamilyConfigTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontFamily != widget.fontFamily) {
      _controller.text = widget.fontFamily ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitFontFamily() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(trimmed);
    }
  }

  Future<void> _pickFontFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final fileName = result.files.single.name;
      final dotIndex = fileName.lastIndexOf('.');
      final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;

      await FontService.instance.removeCustomFont();
      final destPath = await FontService.instance.installFontFile(
        filePath,
        baseName,
      );

      if (destPath != null) {
        await AppSettingsService.instance.saveCustomFontFilePath(destPath);
        widget.onChanged(baseName);
        _controller.text = baseName;
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _clearFont() async {
    await FontService.instance.removeCustomFont();
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFont = widget.fontFamily != null && widget.fontFamily!.isNotEmpty;

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
              '自定义字体',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '输入字体族名称，或加载 .ttf/.otf 字体文件',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '字体族名称',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged(null);
                        },
                      )
                    : null,
              ),
              onEditingComplete: _commitFontFamily,
              onSubmitted: (_) => _commitFontFamily(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFontFile,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open, size: 18),
                  label: Text(_loading ? '加载中...' : '加载字体文件'),
                ),
                if (hasFont) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearFont,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清除'),
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
