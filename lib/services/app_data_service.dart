import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../data/mock_user_settings.dart';
import '../data/preset_selection.dart';
import 'api_config_service.dart';
import 'api_request_log_service.dart';
import 'character_service.dart';
import 'chat_database_service.dart';
import 'preset_service.dart';
import 'remote_backup_settings_service.dart';
import 'storage_service.dart';
import 'user_settings_service.dart';
import 'world_book_service.dart';

class AppDataService {
  AppDataService._();

  static final AppDataService instance = AppDataService._();

  Future<void> clearAllData() async {
    // 先关闭数据库，释放文件锁，避免 Windows 上删除目录时文件被占用
    await ChatDatabaseService.instance.close();

    await StorageService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await WorldBookService.instance.clearAllData();
    await PresetService.instance.resetToDefaults();
    await ApiConfigService.instance.resetToDefaults();
    await UserSettingsService.instance.resetToDefault();
    await ApiRequestLogService.instance.clear();
    await RemoteBackupSettingsService.instance.clear();

    ChatDatabaseService.instance.resetIdSequence();
    await ChatDatabaseService.instance.initialize();
    ChatDatabaseService.instance.notifyDataChanged();

    await reloadAppState();
  }

  Future<void> reloadAppState() async {
    await ChatDatabaseService.instance.initialize();
    await initializeAppSettings();
    await initializeUserSettings();
    await initializeSelectedPreset();
    await initializeApiConfigs();
    await ApiRequestLogService.instance.reload();
  }
}
