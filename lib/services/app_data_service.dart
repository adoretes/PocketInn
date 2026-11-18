import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../data/mock_user_settings.dart';
import '../data/preset_selection.dart';
import 'api_config_service.dart';
import 'api_request_log_service.dart';
import 'character_service.dart';
import 'chat_database_service.dart';
import 'preset_service.dart';
import 'regex_rule_group_service.dart';
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
    await RegexRuleGroupService.instance.resetToDefaults();
    await ApiConfigService.instance.resetToDefaults();
    await UserSettingsService.instance.resetToDefault();
    await ApiRequestLogService.instance.clear();
    await RemoteBackupSettingsService.instance.clear();

    ChatDatabaseService.instance.resetIdSequence();
    await ChatDatabaseService.instance.initialize();

    await reloadAppState();
  }

  /// 重新从磁盘加载全部应用状态。
  ///
  /// 恢复备份等操作会直接替换磁盘上的数据库与文件，内存里的服务缓存
  /// （聊天列表快照、当前会话、记忆求值缓存等）不会随之失效，因此这里
  /// 在重载完成后广播一次变更信号，通知各界面重新拉取数据。
  Future<void> reloadAppState() async {
    await ChatDatabaseService.instance.initialize();
    await initializeAppSettings();
    await initializeUserSettings();
    await initializeSelectedPreset();
    await initializeApiConfigs();
    await ApiRequestLogService.instance.reload();
    RegexRuleGroupService.instance.invalidateCache();

    // 数据库被整体替换：广播会话与记忆数据变更，让左侧聊天列表、聊天页
    // 及记忆面板丢弃旧缓存并重新加载（否则恢复备份后列表仍是旧快照）。
    ChatDatabaseService.instance.notifyDataChanged();
    ChatDatabaseService.instance.notifyMemoryChanged();
  }
}
