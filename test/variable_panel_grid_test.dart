import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/models/variable_panel.dart';
import 'package:pocket_inn/widgets/variable_panel_detail_sheet.dart';
import 'package:pocket_inn/widgets/variable_panel_grid.dart';

void main() {
  VariablePanelItem item(
    String id, {
    int width = 1,
    int height = 1,
    VariablePanelComponentType type = VariablePanelComponentType.text,
    String? variable = 'v',
  }) {
    return VariablePanelItem(
      id: id,
      type: type,
      width: width,
      height: height,
      variableName: type == VariablePanelComponentType.blank ? null : variable,
    );
  }

  group('二维装箱', () {
    test('固定 4 列按行填充并在需要时换行', () {
      final layout = packVariablePanelItems([
        for (var i = 0; i < 6; i++) item('i$i'),
      ]);

      expect(layout.rows, 2);
      expect(layout.placements[0].column, 0);
      expect(layout.placements[0].row, 0);
      expect(layout.placements[3].column, 3);
      expect(layout.placements[3].row, 0);
      expect(layout.placements[4].column, 0);
      expect(layout.placements[4].row, 1);
    });

    test('宽组件占多列，后续组件补空位', () {
      final layout = packVariablePanelItems([
        item('wide', width: 2),
        item('a'),
        item('b'),
        item('c'),
      ]);

      expect(layout.placements[0].width, 2);
      expect(layout.placements[1].column, 2);
      expect(layout.placements[1].row, 0);
      expect(layout.placements[2].column, 3);
      expect(layout.placements[2].row, 0);
      expect(layout.placements[3].column, 0);
      expect(layout.placements[3].row, 1);
      expect(layout.rows, 2);
    });

    test('高组件跨行，后续组件从剩余空格继续', () {
      final layout = packVariablePanelItems([
        item('tall', height: 3),
        item('a'),
        item('b'),
        item('c'),
        item('d'),
        item('e'),
      ]);

      expect(layout.placements[0].height, 3);
      expect(layout.placements[1].column, 1);
      expect(layout.placements[1].row, 0);
      expect(layout.placements[3].column, 3);
      expect(layout.placements[3].row, 0);
      // 第一行已满，后续组件落到高组件旁边的第二行。
      expect(layout.placements[4].column, 1);
      expect(layout.placements[4].row, 1);
      expect(layout.rows, 3);
    });

    test('空白块与普通组件同等参与占位', () {
      final layout = packVariablePanelItems([
        item('space', width: 4, type: VariablePanelComponentType.blank),
        item('a'),
      ]);

      expect(layout.placements[0].width, 4);
      expect(layout.placements[1].row, 1);
      expect(layout.rows, 2);
    });

    test('宽高收敛到 1~4', () {
      final layout = packVariablePanelItems([
        item('a', width: 99, height: 0),
      ]);

      expect(layout.placements.single.width, kVariablePanelMaxWidth);
      expect(layout.placements.single.height, 1);
    });
  });

  group('数值范围归一化', () {
    test('默认范围与非法范围收敛', () {
      expect(VariableNumberRange.fromMetadata(null).min, 0);
      expect(VariableNumberRange.fromMetadata(null).max, 100);

      final onlyMin = VariableNumberRange.fromMetadata(
        const ChatVariableMetadata(minValue: 10),
      );
      expect(onlyMin.min, 10);
      expect(onlyMin.max, 110);

      final inverted = VariableNumberRange.fromMetadata(
        const ChatVariableMetadata(minValue: 5, maxValue: 5),
      );
      expect(inverted.min, 5);
      expect(inverted.max, 6);
    });

    test('比例收敛到 0~1', () {
      const range = VariableNumberRange(0, 100);
      expect(range.fractionOf(-10), 0);
      expect(range.fractionOf(25), 0.25);
      expect(range.fractionOf(120), 1);
    });
  });

  group('网格渲染', () {
    VariableState buildState() {
      return VariableState.fromVariables({
        'hp': const ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '25',
          metadata: ChatVariableMetadata(
            minValue: 0,
            maxValue: 100,
            unit: '%',
          ),
        ),
        'mood': const ChatVariable(
          name: 'mood',
          type: ChatVariableType.enumType,
          value: '低落',
          metadata: ChatVariableMetadata(enumOptions: ['愉快', '低落', '平静']),
        ),
        'desc': const ChatVariable(
          name: 'desc',
          type: ChatVariableType.text,
          value: '**粗体**\n第二行',
        ),
        'name': const ChatVariable(
          name: 'name',
          type: ChatVariableType.text,
          value: '艾琳',
        ),
      });
    }

    Future<void> pumpGrid(
      WidgetTester tester,
      VariablePanelConfig config, {
      VariableState? state,
      double width = 304,
      List<String>? declaredVariableNames,
      void Function(VariablePanelItem item, ChatVariable? variable)? onItemTap,
    }) async {
      final resolvedState = state ?? buildState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: VariablePanelGrid(
                    state: resolvedState,
                    config: config,
                    declaredVariableNames:
                        declaredVariableNames ??
                        [
                          for (final variable in resolvedState.variables)
                            variable.name,
                        ],
                    onItemTap: onItemTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('渲染五种组件且窄抽屉内不溢出', (tester) async {
      final config = VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'p',
            type: VariablePanelComponentType.progress,
            width: 2,
            height: 2,
            variableName: 'hp',
          ),
          VariablePanelItem(
            id: 'c',
            type: VariablePanelComponentType.capsule,
            width: 2,
            variableName: 'mood',
          ),
          VariablePanelItem(
            id: 'n',
            type: VariablePanelComponentType.text,
            variableName: 'name',
            showTitle: false,
          ),
          VariablePanelItem(
            id: 'cur',
            type: VariablePanelComponentType.cursor,
            variableName: 'hp',
          ),
          VariablePanelItem(
            id: 'multi',
            type: VariablePanelComponentType.multilineText,
            width: 2,
            height: 2,
            variableName: 'desc',
          ),
          VariablePanelItem(
            id: 'space',
            type: VariablePanelComponentType.blank,
            width: 2,
          ),
        ],
      );

      await pumpGrid(tester, config);

      expect(tester.takeException(), isNull);
      expect(find.text('hp'), findsNWidgets(2), reason: '进度条与游标各一个标题');
      expect(find.text('25%'), findsNWidgets(2), reason: '进度条与游标各一处');
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);

      // 胶囊只展示当前枚举值，其余选项不出现。
      expect(find.text('mood'), findsOneWidget);
      expect(find.text('低落'), findsOneWidget);
      expect(find.text('愉快'), findsNothing);
      expect(find.text('平静'), findsNothing);

      // 隐藏标题：变量名不作为标题出现，但值仍展示。
      expect(find.text('name'), findsNothing);
      expect(find.text('艾琳'), findsOneWidget);

      // 纯文本渲染：Markdown 标记原样展示。
      expect(find.textContaining('**粗体**'), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('1x1 游标与进度条在大字号下不溢出', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 304,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: VariablePanelGrid(
                      state: buildState(),
                      config: const VariablePanelConfig(
                        items: [
                          VariablePanelItem(
                            id: 'cursor',
                            type: VariablePanelComponentType.cursor,
                            variableName: 'hp',
                          ),
                          VariablePanelItem(
                            id: 'progress',
                            type: VariablePanelComponentType.progress,
                            variableName: 'hp',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('25%'), findsNWidgets(2));
    });

    testWidgets('显式布局末尾追加卡外新变量，跳过卡内隐藏变量', (tester) async {
      final state = VariableState.fromVariables({
        'hp': const ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '25',
        ),
        'hidden': const ChatVariable(
          name: 'hidden',
          type: ChatVariableType.text,
          value: '隐藏',
        ),
        'rage': const ChatVariable(
          name: 'rage',
          type: ChatVariableType.number,
          value: '7',
        ),
      });

      await pumpGrid(
        tester,
        const VariablePanelConfig(
          items: [
            VariablePanelItem(
              id: 'p',
              type: VariablePanelComponentType.text,
              variableName: 'hp',
            ),
          ],
        ),
        state: state,
        declaredVariableNames: const ['hp', 'hidden'],
      );

      expect(find.text('hp'), findsOneWidget);
      expect(find.text('hidden'), findsNothing, reason: '卡内声明但未布局的变量不追加');
      expect(find.text('rage'), findsOneWidget, reason: '卡外新变量追加到末尾');
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('点击组件打开只读详情', (tester) async {
      await pumpGrid(
        tester,
        const VariablePanelConfig(
          items: [
            VariablePanelItem(
              id: 'p',
              type: VariablePanelComponentType.progress,
              width: 2,
              height: 2,
              variableName: 'hp',
            ),
          ],
        ),
        onItemTap: (item, variable) => showVariablePanelDetail(
          tester.element(find.byType(VariablePanelGrid)),
          item: item,
          variable: variable,
        ),
      );

      await tester.tap(find.text('hp'));
      await tester.pumpAndSettle();

      expect(find.text('当前值'), findsOneWidget);
      expect(find.text('范围'), findsOneWidget);
      expect(find.text('0 ~ 100'), findsOneWidget);
      expect(find.text('单位'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      expect(find.text('进度'), findsOneWidget);
      expect(find.text('25%'), findsWidgets);
    });

    testWidgets('绑定变量缺失时展示占位且不抛异常', (tester) async {
      await pumpGrid(
        tester,
        const VariablePanelConfig(
          items: [
            VariablePanelItem(
              id: 'ghost',
              type: VariablePanelComponentType.progress,
              variableName: '不存在',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('不存在'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('显式空配置不渲染任何组件', (tester) async {
      await pumpGrid(
        tester,
        const VariablePanelConfig(items: []),
      );

      expect(find.byType(VariablePanelTile), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('固定 4 列，第 5 个组件换到下一行', (tester) async {
      await pumpGrid(
        tester,
        VariablePanelConfig(
          items: [
            for (var i = 0; i < 5; i++)
              VariablePanelItem(
                id: 'item$i',
                type: VariablePanelComponentType.text,
                variableName: i.isEven ? 'name' : 'desc',
              ),
          ],
        ),
      );

      final tiles = tester
          .widgetList<VariablePanelTile>(find.byType(VariablePanelTile))
          .toList();
      expect(tiles.length, 5);

      final positions = [
        for (final element in find.byType(VariablePanelTile).evaluate())
          (element.renderObject as RenderBox).localToGlobal(Offset.zero),
      ];
      expect(positions[3].dy, positions[0].dy);
      expect(positions[4].dy, greaterThan(positions[0].dy));
    });
  });
}
