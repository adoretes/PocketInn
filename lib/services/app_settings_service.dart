import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import 'storage_service.dart';

/// 应用设置服务
///
/// 负责应用设置的持久化储存和管理
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  // SharedPreferences 键名
  static const String _keyColorMode = 'app_color_mode';
  static const String _keyThemePreset = 'app_theme_preset';
  static const String _keyThemeConfigs = 'app_theme_configs';
  static const String _keyCustomThemeColorIndex =
      'app_custom_theme_color_index';
  static const String _keyQuoteStyle = 'app_quote_style';
  static const String _keyEnableMessageTextShadow =
      'app_enable_message_text_shadow';
  static const String _legacyKeyQuotedTextStyle = 'app_quoted_text_style';
  static const String _legacyKeyBracketTextStyle = 'app_bracket_text_style';
  static const String _legacyKeyItalicTextStyle = 'app_italic_text_style';
  static const String _legacyKeyBoldTextStyle = 'app_bold_text_style';
  static const String _keyQuotedTextColorIndex = 'app_quoted_text_color_index';
  static const String _keyQuotedTextFontStyle = 'app_quoted_text_font_style';
  static const String _keyQuotedTextOpacity = 'app_quoted_text_opacity';
  static const String _keyBracketTextColorIndex =
      'app_bracket_text_color_index';
  static const String _keyBracketTextFontStyle = 'app_bracket_text_font_style';
  static const String _keyBracketTextOpacity = 'app_bracket_text_opacity';
  static const String _keyItalicTextColorIndex = 'app_italic_text_color_index';
  static const String _keyItalicTextFontStyle = 'app_italic_text_font_style';
  static const String _keyItalicTextOpacity = 'app_italic_text_opacity';
  static const String _keyBoldTextColorIndex = 'app_bold_text_color_index';
  static const String _keyBoldTextFontStyle = 'app_bold_text_font_style';
  static const String _keyBoldTextOpacity = 'app_bold_text_opacity';
  static const String _keyShowAvatar = 'app_show_avatar';
  static const String _keyBackgroundOpacity = 'app_background_opacity';
  static const String _keyInputGlassEffect = 'app_input_glass_effect';
  static const String _keyCustomFontFamily = 'app_custom_font_family';
  static const String _keyCustomFontFilePath = 'app_custom_font_file_path';
  static const String _keyShowApiRequestLogEntry =
      'app_show_api_request_log_entry';

  /// 加载应用设置
  Future<AppSettings> load() async {
    final storage = StorageService.instance;

    // 读取各个设置项
    final colorModeIndex = storage.getInt(_keyColorMode);
    final themePresetIndex = storage.getInt(_keyThemePreset);
    final showAvatar = storage.getBool(_keyShowAvatar);
    final backgroundOpacity = storage.getDouble(_keyBackgroundOpacity);
    final inputGlassEffect = storage.getBool(_keyInputGlassEffect);
    final customFontFamily = storage.getString(_keyCustomFontFamily);
    storage.getString(_keyCustomFontFilePath);
    final showApiRequestLogEntry = storage.getBool(_keyShowApiRequestLogEntry);
    final themePreset = _enumValueOrDefault(
      AppThemePreset.values,
      themePresetIndex,
      AppThemePreset.sunset,
    );

    // 构建设置对象
    return AppSettings(
      colorMode: _enumValueOrDefault(
        AppColorMode.values,
        colorModeIndex,
        AppColorMode.system,
      ),
      themePreset: themePreset,
      themeConfigs: _loadThemeConfigs(
        storage: storage,
        activePreset: themePreset,
        legacyCustomFontFamily: customFontFamily,
      ),
      showAvatar: showAvatar ?? true,
      backgroundOpacity: backgroundOpacity ?? 0.85,
      inputGlassEffect: inputGlassEffect ?? true,
      showApiRequestLogEntry: showApiRequestLogEntry ?? true,
    );
  }

  /// 保存应用设置
  Future<void> save(AppSettings settings) async {
    final storage = StorageService.instance;

    await Future.wait([
      storage.setInt(_keyColorMode, settings.colorMode.index),
      storage.setInt(_keyThemePreset, settings.themePreset.index),
      storage.setString(
        _keyThemeConfigs,
        _encodeThemeConfigs(settings.themeConfigs),
      ),
      storage.setBool(_keyShowAvatar, settings.showAvatar),
      storage.setDouble(_keyBackgroundOpacity, settings.backgroundOpacity),
      storage.setBool(_keyInputGlassEffect, settings.inputGlassEffect),
      storage.setBool(
        _keyShowApiRequestLogEntry,
        settings.showApiRequestLogEntry,
      ),
    ]);

    final currentConfig = resolveThemeConfig(settings);
    if (currentConfig.customFontFamily != null) {
      await storage.setString(
        _keyCustomFontFamily,
        currentConfig.customFontFamily!,
      );
    } else {
      await storage.remove(_keyCustomFontFamily);
    }
  }

  /// 更新颜色模式
  Future<void> updateColorMode(AppColorMode mode) async {
    await StorageService.instance.setInt(_keyColorMode, mode.index);
  }

  /// 更新主题预设
  Future<void> updateThemePreset(AppThemePreset preset) async {
    await StorageService.instance.setInt(_keyThemePreset, preset.index);
  }

  /// 更新是否显示头像
  Future<void> updateShowAvatar(bool show) async {
    await StorageService.instance.setBool(_keyShowAvatar, show);
  }

  /// 更新背景透明度
  Future<void> updateBackgroundOpacity(double opacity) async {
    await StorageService.instance.setDouble(_keyBackgroundOpacity, opacity);
  }

  /// 更新输入框毛玻璃效果
  Future<void> updateInputGlassEffect(bool enabled) async {
    await StorageService.instance.setBool(_keyInputGlassEffect, enabled);
  }

  /// 保持自定义字体文件路径
  Future<void> saveCustomFontFilePath(String? path) async {
    final storage = StorageService.instance;
    if (path == null) {
      await storage.remove(_keyCustomFontFilePath);
    } else {
      await storage.setString(_keyCustomFontFilePath, path);
    }
  }

  /// 获取已知的自定义字体文件路径
  String? getCustomFontFilePath() {
    return StorageService.instance.getString(_keyCustomFontFilePath);
  }

  /// 获取已知的自定义字体族名称
  String? getCustomFontFamily() {
    return StorageService.instance.getString(_keyCustomFontFamily);
  }

  /// 更新是否显示 API 请求日志入口
  Future<void> updateShowApiRequestLogEntry(bool enabled) async {
    await StorageService.instance.setBool(_keyShowApiRequestLogEntry, enabled);
  }

  T _enumValueOrDefault<T>(List<T> values, int? index, T fallback) {
    if (index == null || index < 0 || index >= values.length) {
      return fallback;
    }
    return values[index];
  }

  Map<AppThemePreset, AppThemeConfig> _loadThemeConfigs({
    required StorageService storage,
    required AppThemePreset activePreset,
    required String? legacyCustomFontFamily,
  }) {
    final encoded = storage.getString(_keyThemeConfigs);
    if (encoded != null && encoded.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        final data = _asMap(decoded);
        if (data != null) {
          return _decodeThemeConfigs(
            data,
            legacyCustomFontFamily: legacyCustomFontFamily,
          );
        }
      } on Object catch (error, stack) {
        // 持久化主题配置损坏时回退到 legacy keys，仅记录日志。
        debugPrint(
          'app_settings_service: theme configs parse failed: '
          '$error\n$stack',
        );
      }
    }

    return _loadLegacyThemeConfigs(
      storage: storage,
      activePreset: activePreset,
      legacyCustomFontFamily: legacyCustomFontFamily,
    );
  }

  Map<AppThemePreset, AppThemeConfig> _decodeThemeConfigs(
    Map<String, dynamic> data, {
    required String? legacyCustomFontFamily,
  }) {
    final themeConfigs = <AppThemePreset, AppThemeConfig>{};

    for (final preset in AppThemePreset.values) {
      final baseFallback = defaultAppThemeConfigs[preset]!;
      themeConfigs[preset] = _decodeThemeConfig(
        _asMap(data[preset.name]),
        fallback: legacyCustomFontFamily == null
            ? baseFallback
            : baseFallback.copyWith(customFontFamily: legacyCustomFontFamily),
      );
    }

    return Map<AppThemePreset, AppThemeConfig>.unmodifiable(themeConfigs);
  }

  AppThemeConfig _decodeThemeConfig(
    Map<String, dynamic>? data, {
    required AppThemeConfig fallback,
  }) {
    if (data == null) {
      return fallback;
    }

    return AppThemeConfig(
      themeColorIndex: _normalizePaletteIndex(
        _asInt(data['themeColorIndex']),
        fallback.themeColorIndex,
      ),
      customFontFamily:
          _asString(data['customFontFamily']) ?? fallback.customFontFamily,
      chatTextTheme: _decodeChatTextTheme(
        _asMap(data['chatTextTheme']),
        fallback: fallback.chatTextTheme,
      ),
    );
  }

  ChatTextThemeSettings _decodeChatTextTheme(
    Map<String, dynamic>? data, {
    required ChatTextThemeSettings fallback,
  }) {
    if (data == null) {
      return fallback;
    }

    return ChatTextThemeSettings(
      quoteStyle: _enumValueOrDefault(
        AppQuoteStyle.values,
        _asInt(data['quoteStyle']),
        fallback.quoteStyle,
      ),
      enableMessageTextShadow:
          _asBool(data['enableMessageTextShadow']) ??
          fallback.enableMessageTextShadow,
      bodyTextColorPaletteIndex: _normalizeNullablePaletteIndex(
        _asInt(data['bodyTextColorPaletteIndex']),
      ),
      bodyTextColorDarkPaletteIndex: _normalizeNullablePaletteIndex(
        _asInt(data['bodyTextColorDarkPaletteIndex']),
      ),
      quotedTextStyle: _decodeTextStyleConfig(
        _asMap(data['quotedTextStyle']),
        fallback: fallback.quotedTextStyle,
      ),
      bracketTextStyle: _decodeTextStyleConfig(
        _asMap(data['bracketTextStyle']),
        fallback: fallback.bracketTextStyle,
      ),
      italicTextStyle: _decodeTextStyleConfig(
        _asMap(data['italicTextStyle']),
        fallback: fallback.italicTextStyle,
      ),
      boldTextStyle: _decodeTextStyleConfig(
        _asMap(data['boldTextStyle']),
        fallback: fallback.boldTextStyle,
      ),
    );
  }

  ChatTextStyleConfig _decodeTextStyleConfig(
    Map<String, dynamic>? data, {
    required ChatTextStyleConfig fallback,
  }) {
    if (data == null) {
      return fallback;
    }

    return ChatTextStyleConfig(
      paletteIndex: _normalizePaletteIndex(
        _asInt(data['paletteIndex']),
        fallback.paletteIndex,
      ),
      darkPaletteIndex: _normalizeNullablePaletteIndex(
        _asInt(data['darkPaletteIndex']),
      ),
      fontStyleMode: _enumValueOrDefault(
        ChatTextFontStyleMode.values,
        _asInt(data['fontStyleMode']),
        fallback.fontStyleMode,
      ),
      opacity: _normalizeOpacity(_asDouble(data['opacity']), fallback.opacity),
    );
  }

  Map<AppThemePreset, AppThemeConfig> _loadLegacyThemeConfigs({
    required StorageService storage,
    required AppThemePreset activePreset,
    required String? legacyCustomFontFamily,
  }) {
    final themeConfigs = <AppThemePreset, AppThemeConfig>{
      for (final entry in defaultAppThemeConfigs.entries)
        entry.key: legacyCustomFontFamily == null
            ? entry.value
            : entry.value.copyWith(customFontFamily: legacyCustomFontFamily),
    };

    final customFallback = defaultAppThemeConfigs[AppThemePreset.custom]!;
    final customThemeColorIndex = _normalizePaletteIndex(
      storage.getInt(_keyCustomThemeColorIndex),
      customFallback.themeColorIndex,
    );
    themeConfigs[AppThemePreset.custom] = legacyCustomFontFamily == null
        ? customFallback.copyWith(themeColorIndex: customThemeColorIndex)
        : customFallback.copyWith(
            themeColorIndex: customThemeColorIndex,
            customFontFamily: legacyCustomFontFamily,
          );

    final activeFallback = themeConfigs[activePreset]!;
    themeConfigs[activePreset] = activeFallback.copyWith(
      chatTextTheme: _loadLegacyChatTextTheme(
        storage,
        fallback: activeFallback.chatTextTheme,
      ),
    );

    return Map<AppThemePreset, AppThemeConfig>.unmodifiable(themeConfigs);
  }

  ChatTextThemeSettings _loadLegacyChatTextTheme(
    StorageService storage, {
    required ChatTextThemeSettings fallback,
  }) {
    final quoteStyleIndex = storage.getInt(_keyQuoteStyle);
    final enableMessageTextShadow = storage.getBool(
      _keyEnableMessageTextShadow,
    );
    final quotedTextColorIndex = storage.getInt(_keyQuotedTextColorIndex);
    final quotedTextFontStyle = storage.getInt(_keyQuotedTextFontStyle);
    final quotedTextOpacity = storage.getDouble(_keyQuotedTextOpacity);
    final bracketTextColorIndex = storage.getInt(_keyBracketTextColorIndex);
    final bracketTextFontStyle = storage.getInt(_keyBracketTextFontStyle);
    final bracketTextOpacity = storage.getDouble(_keyBracketTextOpacity);
    final italicTextColorIndex = storage.getInt(_keyItalicTextColorIndex);
    final italicTextFontStyle = storage.getInt(_keyItalicTextFontStyle);
    final italicTextOpacity = storage.getDouble(_keyItalicTextOpacity);
    final boldTextColorIndex = storage.getInt(_keyBoldTextColorIndex);
    final boldTextFontStyle = storage.getInt(_keyBoldTextFontStyle);
    final boldTextOpacity = storage.getDouble(_keyBoldTextOpacity);

    return ChatTextThemeSettings(
      quoteStyle: _enumValueOrDefault(
        AppQuoteStyle.values,
        quoteStyleIndex,
        fallback.quoteStyle,
      ),
      enableMessageTextShadow:
          enableMessageTextShadow ?? fallback.enableMessageTextShadow,
      bodyTextColorPaletteIndex: fallback.bodyTextColorPaletteIndex,
      quotedTextStyle: _loadTextStyleConfig(
        colorIndex: quotedTextColorIndex,
        fontStyleIndex: quotedTextFontStyle,
        opacity: quotedTextOpacity,
        legacyPresetIndex: storage.getInt(_legacyKeyQuotedTextStyle),
        fallback: fallback.quotedTextStyle,
      ),
      bracketTextStyle: _loadTextStyleConfig(
        colorIndex: bracketTextColorIndex,
        fontStyleIndex: bracketTextFontStyle,
        opacity: bracketTextOpacity,
        legacyPresetIndex: storage.getInt(_legacyKeyBracketTextStyle),
        fallback: fallback.bracketTextStyle,
      ),
      italicTextStyle: _loadTextStyleConfig(
        colorIndex: italicTextColorIndex,
        fontStyleIndex: italicTextFontStyle,
        opacity: italicTextOpacity,
        legacyPresetIndex: storage.getInt(_legacyKeyItalicTextStyle),
        fallback: fallback.italicTextStyle,
      ),
      boldTextStyle: _loadTextStyleConfig(
        colorIndex: boldTextColorIndex,
        fontStyleIndex: boldTextFontStyle,
        opacity: boldTextOpacity,
        legacyPresetIndex: storage.getInt(_legacyKeyBoldTextStyle),
        fallback: fallback.boldTextStyle,
      ),
    );
  }

  String _encodeThemeConfigs(Map<AppThemePreset, AppThemeConfig> themeConfigs) {
    final data = <String, dynamic>{};

    for (final preset in AppThemePreset.values) {
      final fallback = defaultAppThemeConfigs[preset]!;
      final config = themeConfigs[preset] ?? fallback;
      data[preset.name] = <String, dynamic>{
        'themeColorIndex': _normalizePaletteIndex(
          config.themeColorIndex,
          fallback.themeColorIndex,
        ),
        'customFontFamily': config.customFontFamily,
        'chatTextTheme': _encodeChatTextTheme(config.chatTextTheme),
      };
    }

    return jsonEncode(data);
  }

  Map<String, dynamic> _encodeChatTextTheme(ChatTextThemeSettings settings) {
    return <String, dynamic>{
      'quoteStyle': settings.quoteStyle.index,
      'enableMessageTextShadow': settings.enableMessageTextShadow,
      'bodyTextColorPaletteIndex': settings.bodyTextColorPaletteIndex,
      'bodyTextColorDarkPaletteIndex': settings.bodyTextColorDarkPaletteIndex,
      'quotedTextStyle': _encodeTextStyleConfig(settings.quotedTextStyle),
      'bracketTextStyle': _encodeTextStyleConfig(settings.bracketTextStyle),
      'italicTextStyle': _encodeTextStyleConfig(settings.italicTextStyle),
      'boldTextStyle': _encodeTextStyleConfig(settings.boldTextStyle),
    };
  }

  Map<String, dynamic> _encodeTextStyleConfig(ChatTextStyleConfig config) {
    return <String, dynamic>{
      'paletteIndex': _normalizePaletteIndex(config.paletteIndex, 0),
      'darkPaletteIndex': _normalizeNullablePaletteIndex(
        config.darkPaletteIndex,
      ),
      'fontStyleMode': config.fontStyleMode.index,
      'opacity': _normalizeOpacity(config.opacity, 1.0),
    };
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    return null;
  }

  String? _asString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  ChatTextStyleConfig _loadTextStyleConfig({
    required int? colorIndex,
    required int? fontStyleIndex,
    required double? opacity,
    required int? legacyPresetIndex,
    required ChatTextStyleConfig fallback,
  }) {
    if (colorIndex == null && fontStyleIndex == null && opacity == null) {
      if (legacyPresetIndex != null) {
        return _legacyPresetToTextStyleConfig(legacyPresetIndex);
      }
      return fallback;
    }

    return ChatTextStyleConfig(
      paletteIndex: _normalizePaletteIndex(colorIndex, fallback.paletteIndex),
      fontStyleMode: _enumValueOrDefault(
        ChatTextFontStyleMode.values,
        fontStyleIndex,
        fallback.fontStyleMode,
      ),
      opacity: _normalizeOpacity(opacity, fallback.opacity),
    );
  }

  int _normalizePaletteIndex(int? index, int fallback) {
    if (index == null || index < 0 || index >= customThemePalette.length) {
      return fallback;
    }
    return index;
  }

  int? _normalizeNullablePaletteIndex(int? index) {
    if (index == null || index < 0 || index >= customThemePalette.length) {
      return null;
    }
    return index;
  }

  double _normalizeOpacity(double? value, double fallback) {
    if (value == null) {
      return fallback;
    }
    return value.clamp(0.0, 1.0);
  }

  ChatTextStyleConfig _legacyPresetToTextStyleConfig(int index) {
    switch (index) {
      case 0:
        return const ChatTextStyleConfig(
          paletteIndex: 0,
          fontStyleMode: ChatTextFontStyleMode.bold,
          opacity: 1.0,
        );
      case 1:
        return const ChatTextStyleConfig(
          paletteIndex: 6,
          fontStyleMode: ChatTextFontStyleMode.platform,
          opacity: 0.85,
        );
      case 2:
        return const ChatTextStyleConfig(
          paletteIndex: 3,
          fontStyleMode: ChatTextFontStyleMode.bold,
          opacity: 1.0,
        );
      case 3:
        return const ChatTextStyleConfig(
          paletteIndex: 2,
          fontStyleMode: ChatTextFontStyleMode.platform,
          opacity: 0.72,
        );
      case 4:
        return const ChatTextStyleConfig(
          paletteIndex: 4,
          fontStyleMode: ChatTextFontStyleMode.bold,
          opacity: 1.0,
        );
      case 5:
        return const ChatTextStyleConfig(
          paletteIndex: 7,
          fontStyleMode: ChatTextFontStyleMode.platform,
          opacity: 0.88,
        );
      default:
        return const ChatTextStyleConfig();
    }
  }
}
