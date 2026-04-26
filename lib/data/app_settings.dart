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
  amber('琥珀金', Color(0xFFB7791F));

  const AppThemePreset(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}

@immutable
class AppSettings {
  const AppSettings({
    this.colorMode = AppColorMode.system,
    this.themePreset = AppThemePreset.sunset,
    this.showAvatar = true,
    this.backgroundOpacity = 0.85,
    this.inputGlassEffect = true,
    this.showApiRequestLogEntry = true,
  });

  final AppColorMode colorMode;
  final AppThemePreset themePreset;

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
    bool? showAvatar,
    double? backgroundOpacity,
    bool? inputGlassEffect,
    bool? showApiRequestLogEntry,
  }) {
    return AppSettings(
      colorMode: colorMode ?? this.colorMode,
      themePreset: themePreset ?? this.themePreset,
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
  bool? showAvatar,
  double? backgroundOpacity,
  bool? inputGlassEffect,
  bool? showApiRequestLogEntry,
}) {
  appSettingsNotifier.value = appSettingsNotifier.value.copyWith(
    colorMode: colorMode,
    themePreset: themePreset,
    showAvatar: showAvatar,
    backgroundOpacity: backgroundOpacity,
    inputGlassEffect: inputGlassEffect,
    showApiRequestLogEntry: showApiRequestLogEntry,
  );

  // 持久化保存
  AppSettingsService.instance.save(appSettingsNotifier.value);
}

ThemeData buildAppTheme(AppThemePreset preset, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: preset.seedColor,
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
