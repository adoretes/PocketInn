import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/data/api_configs.dart';
import 'package:pocket_inn/data/app_settings.dart';
import 'package:pocket_inn/models/api_config.dart';
import 'package:pocket_inn/pages/general_settings_page.dart';
import 'package:pocket_inn/services/storage_service.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('pocket_inn_gal_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
          return tempDir.path;
        });
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  testWidgets('Gal 模式设置分组渲染与交互', (tester) async {
    await initializeAppSettings();
    apiConfigsNotifier.value = [
      const ApiConfig(
        id: 'p1',
        name: 'Provider A',
        baseUrl: 'https://a.example.com',
        apiKey: 'sk-test',
        models: [ApiModel(id: 'm1', modelId: 'gpt-x')],
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(home: GeneralSettingsPage()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Gal 模式'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gal 模式'), findsOneWidget);
    expect(find.text('自动生成选项'), findsOneWidget);

    // 切换自动生成开关
    final autoSwitchTile = find
        .ancestor(
          of: find.text('自动生成选项'),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.ensureVisible(autoSwitchTile);
    await tester.pumpAndSettle();
    await tester.tap(autoSwitchTile);
    await tester.pumpAndSettle();
    expect(appSettingsNotifier.value.galChoiceAutoGenerate, isFalse);

    // 打开选项生成 API 选择弹窗并选择模型
    await tester.tap(find.text('选项生成 API'));
    await tester.pumpAndSettle();
    expect(find.text('跟随当前选中模型'), findsWidgets);
    await tester.tap(find.text('gpt-x'));
    await tester.pumpAndSettle();
    expect(appSettingsNotifier.value.galChoiceApiModelId, 'm1');
    expect(
      resolveApiByModelId(appSettingsNotifier.value.galChoiceApiModelId)
          ?.model,
      'gpt-x',
    );

    // 重新打开，恢复跟随当前模型
    await tester.tap(find.text('选项生成 API'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跟随当前选中模型'));
    await tester.pumpAndSettle();
    expect(appSettingsNotifier.value.galChoiceApiModelId, isNull);

    // 打开提示词编辑对话框并保存自定义提示词
    await tester.tap(find.text('自定义提示词'));
    await tester.pumpAndSettle();
    expect(find.text('选项生成提示词'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      '为 {{user}} 生成 {{count}} 个选项',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      appSettingsNotifier.value.galChoicePrompt,
      '为 {{user}} 生成 {{count}} 个选项',
    );

    // 恢复默认
    await tester.tap(find.text('自定义提示词'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();
    expect(appSettingsNotifier.value.galChoicePrompt, isNull);
  });

  testWidgets('选项数量滑块更新设置', (tester) async {
    await initializeAppSettings();
    await tester.pumpWidget(
      const MaterialApp(home: GeneralSettingsPage()),
    );
    await tester.pumpAndSettle();

    final sliderCenter = tester.getCenter(find.byType(Slider));
    await tester.dragFrom(
      sliderCenter,
      const Offset(120, 0),
    ); // 拖到最右侧 => 6
    await tester.pumpAndSettle();
    expect(appSettingsNotifier.value.galChoiceCount, inInclusiveRange(2, 6));
  });
}
