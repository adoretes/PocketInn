import 'package:flutter/material.dart';

import 'data/api_configs.dart';
import 'data/app_settings.dart';
import 'data/mock_user_settings.dart';
import 'data/preset_selection.dart';
import 'pages/chat_page.dart';
import 'services/api_config_service.dart';
import 'services/api_request_log_service.dart';
import 'services/chat_database_service.dart';
import 'services/character_service.dart';
import 'services/preset_service.dart';
import 'services/storage_service.dart';
import 'services/world_book_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化储存服务
  await StorageService.instance.initialize();

  // 初始化世界书服务
  await WorldBookService.instance.initialize();

  // 初始化角色服务
  await CharacterService.instance.initialize();

  // 初始化预设服务
  await PresetService.instance.initialize();
  await initializeSelectedPreset();

  // 初始化 API 配置服务
  await ApiConfigService.instance.initialize();

  // 初始化 API 请求日志
  await ApiRequestLogService.instance.initialize();

  // 加载应用设置
  await initializeAppSettings();

  // 加载用户设定
  await initializeUserSettings();

  // 初始化聊天数据库
  await ChatDatabaseService.instance.initialize();

  // 加载 API 配置
  await initializeApiConfigs();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'PocketInn',
          themeMode: settings.colorMode.themeMode,
          theme: buildAppTheme(settings.themePreset, Brightness.light),
          darkTheme: buildAppTheme(settings.themePreset, Brightness.dark),
          home: const ChatPage(),
        );
      },
    );
  }
}
