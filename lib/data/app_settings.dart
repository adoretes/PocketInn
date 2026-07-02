// ignore_for_file: invalid_annotation_target

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/app_settings_service.dart';

part 'app_settings.freezed.dart';

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
  Color(0xFFFFFFFF),
  Color(0xFFF3F4F6),
  Color(0xFF1F2937),
  Color(0xFF000000),
];

enum AppQuoteStyle {
  curlyDouble('中文引号', '“', '”', '‘', '’'),
  corner('直角引号', '「', '」', '『', '』'),
  doubleCorner('双角引号', '『', '』', '「', '」'),
  asciiDouble('英文引号', '"', '"', "'", "'");

  const AppQuoteStyle(
    this.label,
    this.leading,
    this.trailing,
    this.leadingSingle,
    this.trailingSingle,
  );

  final String label;
  final String leading;
  final String trailing;
  final String leadingSingle;
  final String trailingSingle;

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

@freezed
abstract class ChatTextStyleConfig with _$ChatTextStyleConfig {
  const ChatTextStyleConfig._();

  const factory ChatTextStyleConfig({
    @Default(0) int paletteIndex,
    int? darkPaletteIndex,
    @Default(ChatTextFontStyleMode.platform)
    ChatTextFontStyleMode fontStyleMode,
    @Default(1.0) double opacity,
  }) = _ChatTextStyleConfig;

  int resolvePaletteIndex(Brightness brightness) {
    return brightness == Brightness.dark
        ? (darkPaletteIndex ?? paletteIndex)
        : paletteIndex;
  }
}

@freezed
abstract class ChatTextThemeSettings with _$ChatTextThemeSettings {
  const ChatTextThemeSettings._();

  const factory ChatTextThemeSettings({
    @Default(AppQuoteStyle.curlyDouble) AppQuoteStyle quoteStyle,
    @Default(false) bool enableMessageTextShadow,
    int? bodyTextColorPaletteIndex,
    int? bodyTextColorDarkPaletteIndex,
    @Default(ChatTextStyleConfig(
      paletteIndex: 0,
      fontStyleMode: ChatTextFontStyleMode.bold,
      opacity: 1.0,
    ))
    ChatTextStyleConfig quotedTextStyle,
    @Default(ChatTextStyleConfig(
      paletteIndex: 6,
      fontStyleMode: ChatTextFontStyleMode.platform,
      opacity: 0.9,
    ))
    ChatTextStyleConfig bracketTextStyle,
    @Default(ChatTextStyleConfig(
      paletteIndex: 1,
      fontStyleMode: ChatTextFontStyleMode.italic,
      opacity: 0.65,
    ))
    ChatTextStyleConfig italicTextStyle,
    @Default(ChatTextStyleConfig(
      paletteIndex: 4,
      fontStyleMode: ChatTextFontStyleMode.bold,
      opacity: 1.0,
    ))
    ChatTextStyleConfig boldTextStyle,
  }) = _ChatTextThemeSettings;

  int? resolveBodyTextColorPaletteIndex(Brightness brightness) {
    return brightness == Brightness.dark
        ? (bodyTextColorDarkPaletteIndex ?? bodyTextColorPaletteIndex)
        : bodyTextColorPaletteIndex;
  }
}

@freezed
abstract class AppThemeConfig with _$AppThemeConfig {
  const AppThemeConfig._();

  const factory AppThemeConfig({
    required int themeColorIndex,
    /// 用户自定义字体族名称，null 表示使用系统默认字体
    String? customFontFamily,
    @Default(ChatTextThemeSettings()) ChatTextThemeSettings chatTextTheme,
  }) = _AppThemeConfig;
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

@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(AppColorMode.system) AppColorMode colorMode,
    @Default(AppThemePreset.sunset) AppThemePreset themePreset,
    @Default(defaultAppThemeConfigs)
    Map<AppThemePreset, AppThemeConfig> themeConfigs,
    /// 是否显示聊天头像
    @Default(true) bool showAvatar,
    /// 聊天背景透明度 (0.0 - 1.0)
    @Default(0.85) double backgroundOpacity,
    /// 输入框是否使用毛玻璃效果
    @Default(true) bool inputGlassEffect,
    /// 是否在 API 状态弹窗中显示请求日志入口
    @Default(true) bool showApiRequestLogEntry,
  }) = _AppSettings;
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
  var newSettings = appSettingsNotifier.value;
  if (colorMode != null) {
    newSettings = newSettings.copyWith(colorMode: colorMode);
  }
  if (themePreset != null) {
    newSettings = newSettings.copyWith(themePreset: themePreset);
  }
  if (themeConfigs != null) {
    newSettings = newSettings.copyWith(themeConfigs: themeConfigs);
  }
  if (showAvatar != null) {
    newSettings = newSettings.copyWith(showAvatar: showAvatar);
  }
  if (backgroundOpacity != null) {
    newSettings = newSettings.copyWith(backgroundOpacity: backgroundOpacity);
  }
  if (inputGlassEffect != null) {
    newSettings = newSettings.copyWith(inputGlassEffect: inputGlassEffect);
  }
  if (showApiRequestLogEntry != null) {
    newSettings = newSettings.copyWith(
      showApiRequestLogEntry: showApiRequestLogEntry,
    );
  }
  appSettingsNotifier.value = newSettings;

  // 持久化保存
  AppSettingsService.instance.save(appSettingsNotifier.value);
}

const Object _unset = Object();

void updateThemeConfig({
  AppThemePreset? preset,
  int? themeColorIndex,
  Object? customFontFamily = _unset,
  AppQuoteStyle? quoteStyle,
  bool? enableMessageTextShadow,
  Object? bodyTextColorPaletteIndex = _unset,
  Object? bodyTextColorDarkPaletteIndex = _unset,
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

  var newChatTextTheme = currentConfig.chatTextTheme;
  if (quoteStyle != null) {
    newChatTextTheme = newChatTextTheme.copyWith(quoteStyle: quoteStyle);
  }
  if (enableMessageTextShadow != null) {
    newChatTextTheme = newChatTextTheme.copyWith(
      enableMessageTextShadow: enableMessageTextShadow,
    );
  }
  if (quotedTextStyle != null) {
    newChatTextTheme = newChatTextTheme.copyWith(
      quotedTextStyle: quotedTextStyle,
    );
  }
  if (bracketTextStyle != null) {
    newChatTextTheme = newChatTextTheme.copyWith(
      bracketTextStyle: bracketTextStyle,
    );
  }
  if (italicTextStyle != null) {
    newChatTextTheme = newChatTextTheme.copyWith(
      italicTextStyle: italicTextStyle,
    );
  }
  if (boldTextStyle != null) {
    newChatTextTheme = newChatTextTheme.copyWith(boldTextStyle: boldTextStyle);
  }
  if (bodyTextColorPaletteIndex != _unset) {
    newChatTextTheme = newChatTextTheme.copyWith(
      bodyTextColorPaletteIndex: bodyTextColorPaletteIndex as int?,
    );
  }
  if (bodyTextColorDarkPaletteIndex != _unset) {
    newChatTextTheme = newChatTextTheme.copyWith(
      bodyTextColorDarkPaletteIndex: bodyTextColorDarkPaletteIndex as int?,
    );
  }

  var newConfig = currentConfig.copyWith(chatTextTheme: newChatTextTheme);
  if (themeColorIndex != null) {
    newConfig = newConfig.copyWith(themeColorIndex: themeColorIndex);
  }
  if (customFontFamily != _unset) {
    newConfig = newConfig.copyWith(
      customFontFamily: customFontFamily as String?,
    );
  }

  nextThemeConfigs[targetPreset] = newConfig;

  updateAppSettings(
    themeConfigs: Map<AppThemePreset, AppThemeConfig>.unmodifiable(
      nextThemeConfigs,
    ),
  );
}

void updateChatTextThemeSettings({
  AppQuoteStyle? quoteStyle,
  bool? enableMessageTextShadow,
  Object? bodyTextColorPaletteIndex = _unset,
  Object? bodyTextColorDarkPaletteIndex = _unset,
  ChatTextStyleConfig? quotedTextStyle,
  ChatTextStyleConfig? bracketTextStyle,
  ChatTextStyleConfig? italicTextStyle,
  ChatTextStyleConfig? boldTextStyle,
}) {
  updateThemeConfig(
    quoteStyle: quoteStyle,
    enableMessageTextShadow: enableMessageTextShadow,
    bodyTextColorPaletteIndex: bodyTextColorPaletteIndex,
    bodyTextColorDarkPaletteIndex: bodyTextColorDarkPaletteIndex,
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

String? resolveCustomFontFamily(
  AppSettings settings, {
  AppThemePreset? preset,
}) {
  return resolveThemeConfig(settings, preset: preset).customFontFamily;
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
    fontFamily: resolveCustomFontFamily(settings),
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
