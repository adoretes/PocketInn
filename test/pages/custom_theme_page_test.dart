import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/data/app_settings.dart';
import 'package:pocket_inn/pages/custom_theme/custom_theme_page.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  tearDownAll(() {
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() {
    appSettingsNotifier.value = const AppSettings();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CustomThemePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('主题配置页渲染分组与实时预览', (tester) async {
    await pumpPage(tester);

    expect(find.text('主题配置'), findsOneWidget);
    expect(find.text('实时预览'), findsOneWidget);
    expect(find.text('主题外观'), findsOneWidget);
    expect(find.text('引号与阴影'), findsOneWidget);
    expect(find.text('文本样式'), findsOneWidget);
    expect(find.text('主题色'), findsOneWidget);
    expect(find.text('自定义字体'), findsOneWidget);
    expect(find.text('引号样式'), findsOneWidget);
    expect(find.text('正文颜色'), findsOneWidget);
    expect(find.text('Markdown 加粗'), findsOneWidget);
  });

  testWidgets('点击文本样式行可打开编辑弹窗', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('引号内容'));
    await tester.pumpAndSettle();

    expect(find.text('编辑「引号内容」'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('编辑「引号内容」'), findsNothing);
  });

  testWidgets('窄屏滚动浏览无布局溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CustomThemePage()));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 16; i++) {
      await tester.drag(scrollable, const Offset(0, -320));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('窄屏打开文本样式编辑弹窗无溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CustomThemePage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('引号内容'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('引号内容'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('引号内容'));
    await tester.pumpAndSettle();

    expect(find.text('编辑「引号内容」'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换引号样式会立即更新设置', (tester) async {
    await pumpPage(tester);

    // 默认是中文引号，展开下拉后选择直角引号。
    await tester.tap(find.byType(DropdownButton<AppQuoteStyle>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('「」').last);
    await tester.pumpAndSettle();

    expect(
      appSettingsNotifier
          .value
          .themeConfigs[appSettingsNotifier.value.themePreset]!
          .chatTextTheme
          .quoteStyle,
      AppQuoteStyle.corner,
    );
  });
}
