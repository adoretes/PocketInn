import 'package:flutter/foundation.dart';

import '../models/user_setting.dart';
import '../services/user_settings_service.dart';

export '../models/user_setting.dart' show UserSetting, defaultUserSettings;

/// 用户设定列表通知器
final ValueNotifier<List<UserSetting>> userSettingsNotifier =
    ValueNotifier<List<UserSetting>>([]);

/// 选中的用户设定ID通知器
final ValueNotifier<String?> selectedUserSettingIdNotifier =
    ValueNotifier<String?>(null);

/// 获取当前选中的用户设定
UserSetting? get selectedUserSetting {
  final settings = userSettingsNotifier.value;
  final selectedId = selectedUserSettingIdNotifier.value;

  if (settings.isEmpty) return null;
  if (selectedId == null) return settings.first;

  return settings.firstWhere(
    (setting) => setting.id == selectedId,
    orElse: () => settings.first,
  );
}

/// 初始化用户设定（从持久化储存加载）
Future<void> initializeUserSettings() async {
  final settings = await UserSettingsService.instance.loadAll();
  final selectedId = await UserSettingsService.instance.getSelectedId();

  userSettingsNotifier.value = settings;
  selectedUserSettingIdNotifier.value =
      selectedId ?? (settings.isNotEmpty ? settings.first.id : null);
}

/// 更新用户设定列表
Future<void> updateUserSettings({
  required List<UserSetting> settings,
  String? selectedId,
}) async {
  final nextSettings = List<UserSetting>.unmodifiable(settings);
  final nextSelectedId =
      selectedId ?? (nextSettings.isNotEmpty ? nextSettings.first.id : null);

  // 检查选中的ID是否有效
  final hasSelected =
      nextSelectedId != null &&
      nextSettings.any((item) => item.id == nextSelectedId);
  final validSelectedId = hasSelected
      ? nextSelectedId
      : (nextSettings.isNotEmpty ? nextSettings.first.id : null);

  userSettingsNotifier.value = nextSettings;
  selectedUserSettingIdNotifier.value = validSelectedId;

  // 持久化保存
  await UserSettingsService.instance.saveAll(nextSettings);
  if (validSelectedId != null) {
    await UserSettingsService.instance.setSelectedId(validSelectedId);
  }
}

/// 添加用户设定
Future<void> addUserSetting(UserSetting setting) async {
  final settings = List<UserSetting>.from(userSettingsNotifier.value);
  settings.add(setting);

  userSettingsNotifier.value = List<UserSetting>.unmodifiable(settings);
  await UserSettingsService.instance.add(setting);
}

/// 更新单个用户设定
Future<void> updateUserSetting(UserSetting setting) async {
  final settings = List<UserSetting>.from(userSettingsNotifier.value);
  final index = settings.indexWhere((s) => s.id == setting.id);

  if (index != -1) {
    settings[index] = setting;
    userSettingsNotifier.value = List<UserSetting>.unmodifiable(settings);
    await UserSettingsService.instance.update(setting);
  }
}

/// 删除用户设定
Future<void> deleteUserSetting(String id) async {
  final settings = List<UserSetting>.from(userSettingsNotifier.value);
  settings.removeWhere((s) => s.id == id);

  // 如果删除的是当前选中的设定，更新选中ID
  final selectedId = selectedUserSettingIdNotifier.value;
  String? newSelectedId = selectedId;
  if (selectedId == id && settings.isNotEmpty) {
    newSelectedId = settings.first.id;
  }

  userSettingsNotifier.value = List<UserSetting>.unmodifiable(settings);
  selectedUserSettingIdNotifier.value = newSelectedId;

  await UserSettingsService.instance.delete(id);
}

/// 设置选中的用户设定
Future<void> setSelectedUserSetting(String id) async {
  selectedUserSettingIdNotifier.value = id;
  await UserSettingsService.instance.setSelectedId(id);
}

/// 生成新的用户设定ID
String generateUserSettingId() {
  return UserSettingsService.instance.generateId();
}
