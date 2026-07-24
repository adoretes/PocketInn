import 'package:get_it/get_it.dart';

import '../data/api_configs.dart' as api_configs;
import '../data/app_settings.dart' as app_settings;
import '../data/mock_user_settings.dart' as mock_user_settings;
import '../data/preset_selection.dart' as preset_selection;
import '../services/api_config_service.dart';
import '../services/api_request_log_service.dart';
import '../services/app_backup_service.dart';
import '../services/app_data_service.dart';
import '../services/app_settings_service.dart';
import '../services/character_service.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/chat_memory_service.dart' as chat_memory;
import '../services/chat_service.dart';
import '../services/font_service.dart';
import '../services/i_openai_api_service.dart';
import '../services/openai_compatible_api_service.dart';
import '../services/preset_service.dart';
import '../services/remote_backup_settings_service.dart';
import '../services/remote_backup_service.dart';
import '../services/storage_service.dart';
import '../services/user_settings_service.dart';
import '../services/world_book_service.dart';

/// 全局 DI 容器。
///
/// 新代码优先用 `getIt<XxxService>()`；旧代码保留 `XxxService.instance`
/// 不变，避免一次性大改回归。两者指向同一实例，互相兼容。
final getIt = GetIt.instance;

/// 初始化所有 service 与全局状态。
///
/// 注册顺序与原 [main.dart] 中的初始化顺序一致，保证依赖关系正确。
/// 顶层 mutation 函数（如 [api_configs.initializeApiConfigs]）不属于
/// 具体 service，仍通过函数调用执行。
Future<void> setupServiceLocator() async {
  // 1. 储存服务（其余 service 依赖它）
  getIt.registerSingleton<StorageService>(StorageService.instance);
  await getIt<StorageService>().initialize();

  // 2. 世界书服务
  getIt.registerSingleton<WorldBookService>(WorldBookService.instance);
  await getIt<WorldBookService>().initialize();

  // 3. 角色服务
  getIt.registerSingleton<CharacterService>(CharacterService.instance);
  await getIt<CharacterService>().initialize();

  // 4. 预设服务 + 选中预设
  getIt.registerSingleton<PresetService>(PresetService.instance);
  await getIt<PresetService>().initialize();
  await preset_selection.initializeSelectedPreset();

  // 5. API 配置服务
  getIt.registerSingleton<ApiConfigService>(ApiConfigService.instance);
  await getIt<ApiConfigService>().initialize();

  // 6. API 请求日志
  getIt.registerSingleton<ApiRequestLogService>(ApiRequestLogService.instance);
  await getIt<ApiRequestLogService>().initialize();

  // 7. 应用设置（顶层函数，依赖 StorageService）
  await app_settings.initializeAppSettings();

  // 8. 自定义字体
  getIt.registerSingleton<FontService>(FontService.instance);
  await getIt<FontService>().initializeCustomFont();

  // 9. 用户设定（顶层函数）
  await mock_user_settings.initializeUserSettings();

  // 10. 聊天数据库
  getIt.registerSingleton<ChatDatabaseService>(ChatDatabaseService.instance);
  await getIt<ChatDatabaseService>().initialize();

  // 11. 长期记忆配置（顶层函数）
  await chat_memory.initializeMemoryConfig();

  // 12. API 配置列表（顶层函数）
  await api_configs.initializeApiConfigs();

  // 其余无 initialize() 的 service 注册为懒加载单例（保持与 instance 同一实例）
  getIt.registerLazySingleton<AppBackupService>(
    () => AppBackupService.instance,
  );
  getIt.registerLazySingleton<AppDataService>(() => AppDataService.instance);
  getIt.registerLazySingleton<RemoteBackupSettingsService>(
    () => RemoteBackupSettingsService.instance,
  );
  getIt.registerLazySingleton<RemoteBackupService>(
    () => RemoteBackupService.instance,
  );
  getIt.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService.instance,
  );
  getIt.registerLazySingleton<ChatService>(() => ChatService.instance);
  getIt.registerLazySingleton<ChatCharacterResolver>(
    () => ChatCharacterResolver.instance,
  );
  getIt.registerLazySingleton<IOpenAiApiService>(
    () => OpenAICompatibleApiService.instance,
  );
  getIt.registerLazySingleton<OpenAICompatibleApiService>(
    () => OpenAICompatibleApiService.instance,
  );
  getIt.registerLazySingleton<UserSettingsService>(
    () => UserSettingsService.instance,
  );
  getIt.registerLazySingleton<chat_memory.ChatMemoryService>(
    () => chat_memory.ChatMemoryService.instance,
  );

  // 注：ChatVariableService 全部为静态方法，无 instance 单例，无需注册。
}
