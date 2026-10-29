import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/models/variable_panel.dart';
import 'package:pocket_inn/pages/variable_panel_editor_page.dart';

class _EditorHarness {
  VariablePanelConfig? result;
}

void main() {
  const hp = ChatVariable(
    name: '好感度',
    type: ChatVariableType.number,
    value: '10',
    metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
  );
  const mp = ChatVariable(
    name: '体力',
    type: ChatVariableType.number,
    value: '3',
  );
  const mood = ChatVariable(
    name: '心情',
    type: ChatVariableType.enumType,
    value: '平静',
    metadata: ChatVariableMetadata(enumOptions: ['平静', '心动']),
  );
  const bio = ChatVariable(
    name: '简介',
    type: ChatVariableType.text,
    value: '一位旅人',
  );

  List<ChatVariable> defaultVariables() => const [hp, mp, mood, bio];

  Future<_EditorHarness> pumpEditor(
    WidgetTester tester, {
    List<ChatVariable>? variables,
    VariablePanelConfig? initialConfig,
  }) async {
    final harness = _EditorHarness();
    final actualVariables = variables ?? defaultVariables();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  harness.result = await Navigator.of(context)
                      .push<VariablePanelConfig>(
                        MaterialPageRoute(
                          builder: (_) => VariablePanelEditorPage(
                            variables: actualVariables,
                            initialConfig: initialConfig,
                          ),
                        ),
                      );
                },
                child: const Text('打开编辑器'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开编辑器'));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('未配置时按变量生成默认布局并可添加空白块', (tester) async {
    final harness = await pumpEditor(tester);

    // 默认布局预览：数值有范围→进度条，枚举→胶囊，文本→多行。
    expect(find.text('好感度'), findsOneWidget);
    expect(find.text('心情'), findsOneWidget);
    expect(find.text('简介'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('空白块'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('空白块'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('空白块'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.items.length, 5);
    expect(harness.result!.items.last.type, VariablePanelComponentType.blank);
  });

  testWidgets('编辑组件尺寸与标题后保存', (tester) async {
    final harness = await pumpEditor(tester);

    await tester.tap(find.text('好感度'));
    await tester.pumpAndSettle();

    // 默认进度条为 2x1，点一次「增加高度」变成 2x2。
    await tester.tap(find.byTooltip('增加高度'));
    await tester.pumpAndSettle();

    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == '自定义标题（可选）',
    );
    await tester.enterText(titleField, '生命');
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    final first = harness.result!.items.first;
    expect(first.width, 2);
    expect(first.height, 2);
    expect(first.title, '生命');
    expect(first.variableName, '好感度');
  });

  testWidgets('显式空配置不会回退成默认布局', (tester) async {
    final harness = await pumpEditor(
      tester,
      initialConfig: const VariablePanelConfig(items: []),
    );

    expect(find.text('还没有组件，从下方添加'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.items, isEmpty);
  });

  testWidgets('长按拖动可以调整组件顺序', (tester) async {
    final harness = await pumpEditor(
      tester,
      variables: const [hp, mp],
      initialConfig: VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'a',
            type: VariablePanelComponentType.text,
            variableName: '好感度',
          ),
          VariablePanelItem(
            id: 'b',
            type: VariablePanelComponentType.text,
            variableName: '体力',
          ),
        ],
      ),
    );

    final first = find.text('好感度');
    final second = find.text('体力');
    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(second));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.items.first.variableName, '体力');
    expect(harness.result!.items.last.variableName, '好感度');
  });

  testWidgets('有未保存改动时返回会二次确认', (tester) async {
    final harness = await pumpEditor(tester);

    await tester.scrollUntilVisible(
      find.text('空白块'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('空白块'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('空白块'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('添加组件'), findsOneWidget, reason: '选择继续编辑应停留在编辑页');
    expect(harness.result, isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '放弃'));
    await tester.pumpAndSettle();

    expect(find.text('打开编辑器'), findsOneWidget);
    expect(harness.result, isNull, reason: '放弃修改不应写回布局');
  });

  testWidgets('未改动时返回不弹确认', (tester) async {
    final harness = await pumpEditor(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('放弃修改？'), findsNothing);
    expect(harness.result, isNull);
  });

  testWidgets('恢复默认会补齐所有变量的默认组件', (tester) async {
    final harness = await pumpEditor(
      tester,
      initialConfig: const VariablePanelConfig(items: []),
    );

    await tester.tap(find.widgetWithText(TextButton, '恢复默认'));
    await tester.pumpAndSettle();

    expect(find.text('好感度'), findsOneWidget);
    expect(find.text('简介'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.items.length, 4);
  });
}
