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
  static const String _keyShowAvatar = 'app_show_avatar';
  static const String _keyBackgroundOpacity = 'app_background_opacity';
  static const String _keyInputGlassEffect = 'app_input_glass_effect';
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
    final showApiRequestLogEntry = storage.getBool(_keyShowApiRequestLogEntry);

    // 构建设置对象
    return AppSettings(
      colorMode: colorModeIndex != null
          ? AppColorMode.values[colorModeIndex]
          : AppColorMode.system,
      themePreset: themePresetIndex != null
          ? AppThemePreset.values[themePresetIndex]
          : AppThemePreset.sunset,
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
      storage.setBool(_keyShowAvatar, settings.showAvatar),
      storage.setDouble(_keyBackgroundOpacity, settings.backgroundOpacity),
      storage.setBool(_keyInputGlassEffect, settings.inputGlassEffect),
      storage.setBool(
        _keyShowApiRequestLogEntry,
        settings.showApiRequestLogEntry,
      ),
    ]);
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

  /// 更新是否显示 API 请求日志入口
  Future<void> updateShowApiRequestLogEntry(bool enabled) async {
    await StorageService.instance.setBool(_keyShowApiRequestLogEntry, enabled);
  }
}
