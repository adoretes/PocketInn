import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/error_handler.dart';
import 'core/service_locator.dart';
import 'data/app_settings.dart';
import 'pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册全局错误处理：避免 release 模式红屏，统一记录未捕获异常
  ErrorWidget.builder = buildAppErrorWidget;
  registerGlobalErrorHandlers();

  // 通过 DI 容器统一注册并初始化所有 service（顺序见 service_locator.dart）
  await setupServiceLocator();

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
          theme: buildAppTheme(settings, Brightness.light),
          darkTheme: buildAppTheme(settings, Brightness.dark),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          home: const ChatPage(),
        );
      },
    );
  }
}
