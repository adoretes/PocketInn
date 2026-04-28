import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

enum AppColorMode {
  system('跟随系统', ThemeMode.system),
  dark('深色', ThemeMode.dark),
  light('浅色', ThemeMode.light);

  const AppColorMode(this.label, this.themeMode);

  final String label;
  final ThemeMode themeMode;
}

enum AppThemePreset {
  sunset('日落橙', Color(0xFFE76F51)),
  ocean('海湾蓝', Color(0xFF277DA1)),
  slate('雾岩灰', Color(0xFF6B7280)),
  rose('玫瑰粉', Color(0xFFD95D8B)),
  amber('琥珀金', Color(0xFFB7791F)),
  custom('自定义', Color(0xFFE76F51));

  const AppThemePreset(this.label, this.seedColor);

  final String label;
  final Color seedColor;

  bool get isCustom => this == AppThemePreset.custom;
}

const List<Color> customThemePalette = <Color>[
  Color(0xFFE76F51),
  Color(0xFF277DA1),
  Color(0xFF6B7280),
  Color(0xFFD95D8B),
  Color(0xFFB7791F),
  Color(0xFF2D6A4F),
  Color(0xFF0E9594),
  Color(0xFF355070),
  Color(0xFFB23A48),
  Color(0xFF8D6E63),
  Color(0xFF5E60CE),
  Color(0xFF7F5539),
  Color(0xFFF28482),
  Color(0xFFF4A261),
  Color(0xFFE9C46A),
  Color(0xFF84A59D),
  Color(0xFF43AA8B),
  Color(0xFF4D908E),
  Color(0xFF577590),
  Color(0xFF3D5A80),
  Color(0xFF9D4EDD),
  Color(0xFFC77DFF),
  Color(0xFFC9184A),
  Color(0xFFA44A3F),
  Color(0xFF606C38),
  Color(0xFF1B4965),
  Color(0xFF2A9D8F),
  Color(0xFF264653),
];

enum AppQuoteStyle {
  curlyDouble('中文双引号', '“', '”'),
  corner('角引号', '「', '」'),
  doubleCorner('双角引号', '『', '』'),
  bookTitle('书名号', '《', '》'),
  asciiDouble('英文双引号', '"', '"');

  const AppQuoteStyle(this.label, this.leading, this.trailing);

  final String label;
  final String leading;
  final String trailing;

  static const List<AppQuoteStyle> selectableValues = <AppQuoteStyle>[
    AppQuoteStyle.curlyDouble,
    AppQuoteStyle.corner,
    AppQuoteStyle.doubleCorner,
    AppQuoteStyle.asciiDouble,
  ];
}

enum ChatTextFontStyleMode {
  platform('普通'),
  italic('斜体'),
  bold('加粗');

  const ChatTextFontStyleMode(this.label);

  final String label;
}

@immutable
class ChatTextStyleConfig {
  const ChatTextStyleConfig({
    this.paletteIndex = 0,
    this.fontStyleMode = ChatTextFontStyleMode.platform,
    this.opacity = 1.0,
  });

  final int paletteIndex;
  final ChatTextFontStyleMode fontStyleMode;
  final double opacity;

  ChatTextStyleConfig copyWith({
    int? paletteIndex,
    ChatTextFontStyleMode? fontStyleMode,
    double? opacity,
  }) {
    return ChatTextStyleConfig(
      paletteIndex: paletteIndex ?? this.paletteIndex,
      fontStyleMode: fontStyleMode ?? this.fontStyleMode,
      opacity: opacity ?? this.opacity,
    );
  }
}

@immutable
class ChatTextThemeSettings {
  const ChatTextThemeSettings({
    this.quoteStyle = AppQuoteStyle.curlyDouble,
    this.enableMessageTextShadow = false,
    this.quotedTextStyle = const ChatTextStyleConfig(
      paletteIndex: 0,
      fontStyleMode: ChatTextFontStyleMode.bold,
      opacity: 1.0,
    ),
    this.bracketTextStyle = const ChatTextStyleConfig(
      paletteIndex: 6,
      fontStyleMode: ChatTextFontStyleMode.platform,
      opacity: 0.9,
    ),
    this.italicTextStyle = const ChatTextStyleConfig(
      paletteIndex: 1,
      fontStyleMode: ChatTextFontStyleMode.italic,
      opacity: 0.65,
    ),
    this.boldTextStyle = const ChatTextStyleConfig(
      paletteIndex: 4,
      fontStyleMode: ChatTextFontStyleMode.bold,
      opacity: 1.0,
    ),
  });

  final AppQuoteStyle quoteStyle;
  final bool enableMessageTextShadow;
  final ChatTextStyleConfig quotedTextStyle;
  final ChatTextStyleConfig bracketTextStyle;
  final ChatTextStyleConfig italicTextStyle;
  final ChatTextStyleConfig boldTextStyle;

  ChatTextThemeSettings copyWith({
    AppQuoteStyle? quoteStyle,
    bool? enableMessageTextShadow,
    ChatTextStyleConfig? quotedTextStyle,
    ChatTextStyleConfig? bracketTextStyle,
    ChatTextStyleConfig? italicTextStyle,
    ChatTextStyleConfig? boldTextStyle,
  }) {
    return ChatTextThemeSettings(
      quoteStyle: quoteStyle ?? this.quoteStyle,
      enableMessageTextShadow:
          enableMessageTextShadow ?? this.enableMessageTextShadow,
      quotedTextStyle: quotedTextStyle ?? this.quotedTextStyle,
      bracketTextStyle: bracketTextStyle ?? this.bracketTextStyle,
      italicTextStyle: italicTextStyle ?? this.italicTextStyle,
      boldTextStyle: boldTextStyle ?? this.boldTextStyle,
    );
  }
}

@immutable
class AppThemeConfig {
  const AppThemeConfig({
    required this.themeColorIndex,
    this.chatTextTheme = const ChatTextThemeSettings(),
  });

  final int themeColorIndex;
  final ChatTextThemeSettings chatTextTheme;

  AppThemeConfig copyWith({
    int? themeColorIndex,
    ChatTextThemeSettings? chatTextTheme,
  }) {
    return AppThemeConfig(
      themeColorIndex: themeColorIndex ?? this.themeColorIndex,
      chatTextTheme: chatTextTheme ?? this.chatTextTheme,
    );
  }
}

const Map<AppThemePreset, AppThemeConfig> defaultAppThemeConfigs =
    <AppThemePreset, AppThemeConfig>{
      AppThemePreset.sunset: AppThemeConfig(
        themeColorIndex: 0,
        chatTextTheme: ChatTextThemeSettings(
          quotedTextStyle: ChatTextStyleConfig(
            paletteIndex: 0,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
          bracketTextStyle: ChatTextStyleConfig(
            paletteIndex: 6,
            fontStyleMode: ChatTextFontStyleMode.platform,
            opacity: 0.9,
          ),
          italicTextStyle: ChatTextStyleConfig(
            paletteIndex: 1,
            fontStyleMode: ChatTextFontStyleMode.italic,
            opacity: 0.65,
          ),
          boldTextStyle: ChatTextStyleConfig(
            paletteIndex: 4,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
        ),
      ),
      AppThemePreset.ocean: AppThemeConfig(
        themeColorIndex: 1,
        chatTextTheme: ChatTextThemeSettings(
          quotedTextStyle: ChatTextStyleConfig(
            paletteIndex: 1,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
          bracketTextStyle: ChatTextStyleConfig(
            paletteIndex: 6,
            fontStyleMode: ChatTextFontStyleMode.platform,
            opacity: 0.88,
          ),
          italicTextStyle: ChatTextStyleConfig(
            paletteIndex: 7,
            fontStyleMode: ChatTextFontStyleMode.italic,
            opacity: 0.68,
          ),
          boldTextStyle: ChatTextStyleConfig(
            paletteIndex: 1,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
        ),
      ),
      AppThemePreset.slate: AppThemeConfig(
        themeColorIndex: 2,
        chatTextTheme: ChatTextThemeSettings(
          quotedTextStyle: ChatTextStyleConfig(
            paletteIndex: 2,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
          bracketTextStyle: ChatTextStyleConfig(
            paletteIndex: 7,
            fontStyleMode: ChatTextFontStyleMode.platform,
            opacity: 0.88,
          ),
          italicTextStyle: ChatTextStyleConfig(
            paletteIndex: 9,
            fontStyleMode: ChatTextFontStyleMode.italic,
            opacity: 0.72,
          ),
          boldTextStyle: ChatTextStyleConfig(
            paletteIndex: 2,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
        ),
      ),
      AppThemePreset.rose: AppThemeConfig(
        themeColorIndex: 3,
        chatTextTheme: ChatTextThemeSettings(
          quotedTextStyle: ChatTextStyleConfig(
            paletteIndex: 3,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
          bracketTextStyle: ChatTextStyleConfig(
            paletteIndex: 10,
            fontStyleMode: ChatTextFontStyleMode.platform,
            opacity: 0.88,
          ),
          italicTextStyle: ChatTextStyleConfig(
            paletteIndex: 8,
            fontStyleMode: ChatTextFontStyleMode.italic,
            opacity: 0.72,
          ),
          boldTextStyle: ChatTextStyleConfig(
            paletteIndex: 3,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
        ),
      ),
      AppThemePreset.amber: AppThemeConfig(
        themeColorIndex: 4,
        chatTextTheme: ChatTextThemeSettings(
          quotedTextStyle: ChatTextStyleConfig(
            paletteIndex: 4,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
          bracketTextStyle: ChatTextStyleConfig(
            paletteIndex: 9,
            fontStyleMode: ChatTextFontStyleMode.platform,
            opacity: 0.88,
          ),
          italicTextStyle: ChatTextStyleConfig(
            paletteIndex: 7,
            fontStyleMode: ChatTextFontStyleMode.italic,
            opacity: 0.7,
          ),
          boldTextStyle: ChatTextStyleConfig(
            paletteIndex: 4,
            fontStyleMode: ChatTextFontStyleMode.bold,
            opacity: 1.0,
          ),
        ),
      ),
      AppThemePreset.custom: AppThemeConfig(
        themeColorIndex: 0,
        chatTextTheme: ChatTextThemeSettings(),
      ),
    };

@immutable
class AppSettings {
  const AppSettings({
    this.colorMode = AppColorMode.system,
    this.themePreset = AppThemePreset.sunset,
    this.themeConfigs = defaultAppThemeConfigs,
    this.showAvatar = true,
    this.backgroundOpacity = 0.85,
    this.inputGlassEffect = true,
    this.showApiRequestLogEntry = true,
  });

  final AppColorMode colorMode;
  final AppThemePreset themePreset;
  final Map<AppThemePreset, AppThemeConfig> themeConfigs;

  /// 是否显示聊天头像
  final bool showAvatar;

  /// 聊天背景透明度 (0.0 - 1.0)
  final double backgroundOpacity;

  /// 输入框是否使用毛玻璃效果
  final bool inputGlassEffect;

  /// 是否在 API 状态弹窗中显示请求日志入口
  final bool showApiRequestLogEntry;

  AppSettings copyWith({
    AppColorMode? colorMode,
    AppThemePreset? themePreset,
    Map<AppThemePreset, AppThemeConfig>? themeConfigs,
    bool? showAvatar,
    double? backgroundOpacity,
    bool? inputGlassEffect,
    bool? showApiRequestLogEntry,
  }) {
    return AppSettings(
      colorMode: colorMode ?? this.colorMode,
      themePreset: themePreset ?? this.themePreset,
      themeConfigs: themeConfigs ?? this.themeConfigs,
      showAvatar: showAvatar ?? this.showAvatar,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      inputGlassEffect: inputGlassEffect ?? this.inputGlassEffect,
      showApiRequestLogEntry:
          showApiRequestLogEntry ?? this.showApiRequestLogEntry,
    );
  }
}

final ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier(
  const AppSettings(),
);

/// 初始化应用设置（从持久化储存加载）
Future<void> initializeAppSettings() async {
  final settings = await AppSettingsService.instance.load();
  appSettingsNotifier.value = settings;
}

void updateAppSettings({
  AppColorMode? colorMode,
  AppThemePreset? themePreset,
  Map<AppThemePreset, AppThemeConfig>? themeConfigs,
  bool? showAvatar,
  double? backgroundOpacity,
  bool? inputGlassEffect,
  bool? showApiRequestLogEntry,
}) {
  appSettingsNotifier.value = appSettingsNotifier.value.copyWith(
    colorMode: colorMode,
    themePreset: themePreset,
    themeConfigs: themeConfigs,
    showAvatar: showAvatar,
    backgroundOpacity: backgroundOpacity,
    inputGlassEffect: inputGlassEffect,
    showApiRequestLogEntry: showApiRequestLogEntry,
  );

  // 持久化保存
  AppSettingsService.instance.save(appSettingsNotifier.value);
}

void updateThemeConfig({
  AppThemePreset? preset,
  int? themeColorIndex,
  AppQuoteStyle? quoteStyle,
  bool? enableMessageTextShadow,
  ChatTextStyleConfig? quotedTextStyle,
  ChatTextStyleConfig? bracketTextStyle,
  ChatTextStyleConfig? italicTextStyle,
  ChatTextStyleConfig? boldTextStyle,
}) {
  final current = appSettingsNotifier.value;
  final targetPreset = preset ?? current.themePreset;
  final currentConfig = resolveThemeConfig(current, preset: targetPreset);
  final nextThemeConfigs = Map<AppThemePreset, AppThemeConfig>.from(
    current.themeConfigs,
  );

  nextThemeConfigs[targetPreset] = currentConfig.copyWith(
    themeColorIndex: themeColorIndex,
    chatTextTheme: currentConfig.chatTextTheme.copyWith(
      quoteStyle: quoteStyle,
      enableMessageTextShadow: enableMessageTextShadow,
      quotedTextStyle: quotedTextStyle,
      bracketTextStyle: bracketTextStyle,
      italicTextStyle: italicTextStyle,
      boldTextStyle: boldTextStyle,
    ),
  );

  updateAppSettings(
    themeConfigs: Map<AppThemePreset, AppThemeConfig>.unmodifiable(
      nextThemeConfigs,
    ),
  );
}

void updateChatTextThemeSettings({
  AppQuoteStyle? quoteStyle,
  bool? enableMessageTextShadow,
  ChatTextStyleConfig? quotedTextStyle,
  ChatTextStyleConfig? bracketTextStyle,
  ChatTextStyleConfig? italicTextStyle,
  ChatTextStyleConfig? boldTextStyle,
}) {
  updateThemeConfig(
    quoteStyle: quoteStyle,
    enableMessageTextShadow: enableMessageTextShadow,
    quotedTextStyle: quotedTextStyle,
    bracketTextStyle: bracketTextStyle,
    italicTextStyle: italicTextStyle,
    boldTextStyle: boldTextStyle,
  );
}

AppThemeConfig resolveThemeConfig(
  AppSettings settings, {
  AppThemePreset? preset,
}) {
  final resolvedPreset = preset ?? settings.themePreset;
  return settings.themeConfigs[resolvedPreset] ??
      defaultAppThemeConfigs[resolvedPreset]!;
}

int resolveThemeColorPaletteIndex(
  AppSettings settings, {
  AppThemePreset? preset,
}) {
  final resolvedPreset = preset ?? settings.themePreset;
  final fallbackIndex = defaultAppThemeConfigs[resolvedPreset]!.themeColorIndex;
  final index = resolveThemeConfig(
    settings,
    preset: resolvedPreset,
  ).themeColorIndex;
  if (index < 0 || index >= customThemePalette.length) {
    return fallbackIndex;
  }
  return index;
}

Color resolveThemeColor(AppSettings settings, {AppThemePreset? preset}) {
  return customThemePalette[resolveThemeColorPaletteIndex(
    settings,
    preset: preset,
  )];
}

ChatTextThemeSettings resolveActiveChatTextTheme(AppSettings settings) {
  return resolveThemeConfig(settings).chatTextTheme;
}

ChatTextThemeSettings resolveChatTextTheme(
  AppSettings settings, {
  AppThemePreset? preset,
}) {
  return resolveThemeConfig(settings, preset: preset).chatTextTheme;
}

ThemeData buildAppTheme(AppSettings settings, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: resolveThemeColor(settings),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    ),
  );
}
