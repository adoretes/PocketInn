import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/pages/char_edit_page.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';

import '../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await WorldBookService.instance.initialize();
  });

  tearDownAll(() async {
    tearDownPathProviderMocks(tempDir);
  });

  Map<String, dynamic> minimalCard() => {
    'spec': 'chara_card_v2',
    'spec_version': '2.0',
    'data': <String, dynamic>{
      'name': '艾琳',
      'description': '测试角色',
      'first_mes': '你好',
    },
  };

  testWidgets('未声明变量的卡首次添加变量并保存不抛异常且正确写卡', (tester) async {
    RoleEditSavePayload? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        home: RoleEditPage(
          characterData: minimalCard(),
          onSave: (payload) async {
            savedPayload = payload;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初始状态变量区块在「高级设置」内，先滚动并展开。
    await tester.scrollUntilVisible(
      find.text('高级设置'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('添加变量'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('添加变量'));
    await tester.pumpAndSettle();

    // 对话框：填变量名与初始值（此前 const 空列表在此步抛
    // UnsupportedError: Cannot remove from an unmodifiable list）。
    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), '好感度');
    await tester.enterText(dialogFields.at(1), '10');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('好感度'), findsOneWidget, reason: '变量应显示在列表中');

    // 保存整卡（AppBar 保存按钮）。注：不要用 tapAt 盲点收起键盘——
    // 命中「选择世界书」会弹出底部选择器，其模态遮罩会挡住保存按钮。
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    final payload = savedPayload;
    expect(payload, isNotNull, reason: '应触发保存回调');
    final variables = decodeCardVariables(payload!.cardJson);
    expect(variables.length, 1);
    expect(variables.single.name, '好感度');
    expect(variables.single.value, '10');
  });

  testWidgets('编辑已有变量保存后覆盖同名项', (tester) async {
    final card = minimalCard();
    (card['data'] as Map<String, dynamic>)['extensions'] = {
      'variables': encodeCardVariables([
        const ChatVariable(
          name: '好感度',
          type: ChatVariableType.number,
          value: '0',
        ),
      ]),
    };

    RoleEditSavePayload? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        home: RoleEditPage(
          characterData: card,
          onSave: (payload) async {
            savedPayload = payload;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 变量区块在「高级设置」内，先展开再编辑。
    await tester.scrollUntilVisible(
      find.text('高级设置'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();

    // 编辑既有变量，改为新值。
    await tester.scrollUntilVisible(
      find.byTooltip('编辑'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('编辑'));
    await tester.pumpAndSettle();
    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(1), '25');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    final variables = decodeCardVariables(savedPayload!.cardJson);
    expect(variables.length, 1, reason: '同名编辑应覆盖而非追加');
    expect(variables.single.value, '25');
  });
}
