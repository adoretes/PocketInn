import '../models/user_setting.dart';
import 'storage_service.dart';

/// 用户设定服务
///
/// 负责用户设定的持久化储存和管理
class UserSettingsService {
  UserSettingsService._();

  static final UserSettingsService instance = UserSettingsService._();

  // JSON 文件名
  static const String _filename = 'user_settings.json';

  // SharedPreferences 键名（用于储存选中的用户设定ID）
  static const String _keySelectedId = 'selected_user_setting_id';

  // 数据版本（用于未来数据迁移）
  static const int _dataVersion = 1;

  /// 加载所有用户设定
  Future<List<UserSetting>> loadAll() async {
    final storage = StorageService.instance;

    final data = await storage.readJsonMap(_filename);
    if (data == null) {
      // 首次使用，返回默认数据
      return defaultUserSettings;
    }

    // 检查数据版本
    final version = data['version'] as int? ?? 1;
    if (version != _dataVersion) {
      // 未来可以在这里处理数据迁移
      return defaultUserSettings;
    }

    final settingsList = data['settings'] as List<dynamic>?;
    if (settingsList == null || settingsList.isEmpty) {
      return defaultUserSettings;
    }

    return settingsList
        .map((json) => UserSetting.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 保存所有用户设定
  Future<void> saveAll(List<UserSetting> settings) async {
    final storage = StorageService.instance;

    final data = {
      'version': _dataVersion,
      'selectedId':
          await getSelectedId() ??
          (settings.isNotEmpty ? settings.first.id : null),
      'settings': settings.map((s) => s.toJson()).toList(),
    };

    await storage.writeJsonMap(_filename, data);
  }

  /// 添加用户设定
  Future<void> add(UserSetting setting) async {
    final settings = await loadAll();
    settings.add(setting);
    await saveAll(settings);
  }

  /// 更新用户设定
  Future<void> update(UserSetting setting) async {
    final settings = await loadAll();
    final index = settings.indexWhere((s) => s.id == setting.id);
    if (index != -1) {
      settings[index] = setting;
      await saveAll(settings);
    }
  }

  /// 删除用户设定
  ///
  /// 返回删除后的设定列表
  Future<List<UserSetting>> delete(String id) async {
    final settings = await loadAll();
    settings.removeWhere((s) => s.id == id);
    await saveAll(settings);

    // 如果删除的是当前选中的设定，更新选中ID
    final selectedId = await getSelectedId();
    if (selectedId == id && settings.isNotEmpty) {
      await setSelectedId(settings.first.id);
    }

    return settings;
  }

  /// 获取选中的用户设定ID
  Future<String?> getSelectedId() async {
    return StorageService.instance.getString(_keySelectedId);
  }

  /// 设置选中的用户设定ID
  Future<void> setSelectedId(String id) async {
    await StorageService.instance.setString(_keySelectedId, id);
  }

  /// 生成唯一ID
  String generateId() {
    return 'user-setting-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取当前选中的用户设定
  Future<UserSetting?> getSelected() async {
    final settings = await loadAll();
    final selectedId = await getSelectedId();

    if (selectedId == null || settings.isEmpty) {
      return settings.isNotEmpty ? settings.first : null;
    }

    return settings.firstWhere(
      (s) => s.id == selectedId,
      orElse: () => settings.first,
    );
  }

  /// 重置为默认数据
  Future<void> resetToDefault() async {
    await saveAll(defaultUserSettings);
    if (defaultUserSettings.isNotEmpty) {
      await setSelectedId(defaultUserSettings.first.id);
    }
  }
}
