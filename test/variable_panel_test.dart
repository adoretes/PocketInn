import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/models/variable_panel.dart';

void main() {
  Map<String, dynamic> cardWith(Map<String, dynamic>? panel) {
    return {
      'data': {
        'extensions': {
          'variablePanel': ?panel,
        },
      },
    };
  }

  const progressItem = VariablePanelItem(
    id: 'a',
    type: VariablePanelComponentType.progress,
    width: 2,
    height: 1,
    variableName: 'hp',
  );

  group('面板配置编解码', () {
    test('往返保留宽高、标题与空白块', () {
      final config = VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'a',
            type: VariablePanelComponentType.progress,
            width: 2,
            height: 1,
            variableName: 'hp',
            title: '生命',
          ),
          VariablePanelItem(
            id: 'b',
            type: VariablePanelComponentType.text,
            width: 1,
            height: 3,
            variableName: '名字',
            showTitle: false,
          ),
          VariablePanelItem(
            id: 'c',
            type: VariablePanelComponentType.blank,
            width: 3,
            height: 2,
          ),
        ],
      );

      final decoded = decodeVariablePanelConfig(cardWith(config.toJson()));
      expect(decoded, isNotNull);
      final parsed = decoded!;
      expect(parsed.items.length, 3);

      final progress = parsed.items[0];
      expect(progress.type, VariablePanelComponentType.progress);
      expect(progress.width, 2);
      expect(progress.height, 1);
      expect(progress.variableName, 'hp');
      expect(progress.displayTitle, '生命');

      final text = parsed.items[1];
      expect(text.width, 1);
      expect(text.height, 3);
      expect(text.showTitle, isFalse);
      expect(text.variableName, '名字');

      final blank = parsed.items[2];
      expect(blank.type, VariablePanelComponentType.blank);
      expect(blank.variableName, isNull);
      expect(blank.width, 3);
      expect(blank.height, 2);
    });

    test('缺失扩展返回 null；显式空面板保留为空', () {
      expect(decodeVariablePanelConfig(cardWith(null)), isNull);
      expect(decodeVariablePanelConfig(const {}), isNull);

      final empty = decodeVariablePanelConfig(
        cardWith({'version': 1, 'items': <dynamic>[]}),
      );
      expect(empty, isNotNull);
      expect(empty!.isEmpty, isTrue);
    });

    test('未知类型跳过、尺寸收敛、重复 id 去重', () {
      final decoded = decodeVariablePanelConfig(
        cardWith({
          'items': [
            {'id': 'x', 'type': 'unknown', 'var': 'hp'},
            {'id': 'dup', 'type': 'text', 'var': 'a', 'w': 9, 'h': 9},
            {'id': 'dup', 'type': 'blank', 'w': 0, 'h': 0},
          ],
        }),
      )!;

      expect(decoded.items.length, 2);
      expect(decoded.items[0].width, kVariablePanelMaxWidth);
      expect(decoded.items[0].height, kVariablePanelMaxHeight);
      expect(decoded.items[1].width, 1);
      expect(decoded.items[1].height, 1);
      expect(decoded.items[0].id, isNot(decoded.items[1].id));
    });

    test('缺少绑定变量的普通组件被跳过，空白块保留', () {
      final decoded = decodeVariablePanelConfig(
        cardWith({
          'items': [
            {'type': 'text'},
            {'type': 'blank', 'w': 2, 'h': 2},
          ],
        }),
      )!;

      expect(decoded.items.length, 1);
      expect(decoded.items.single.type, VariablePanelComponentType.blank);
      expect(decoded.items.single.width, 2);
      expect(decoded.items.single.height, 2);
    });
  });

  group('默认布局', () {
    test('按变量类型生成组件与尺寸', () {
      final config = VariablePanelConfig.defaultForVariables([
        const ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '10',
          metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
        ),
        const ChatVariable(
          name: 'atk',
          type: ChatVariableType.number,
          value: '3',
        ),
        const ChatVariable(
          name: 'mood',
          type: ChatVariableType.text,
          value: '平静',
        ),
        const ChatVariable(
          name: 'stance',
          type: ChatVariableType.enumType,
          value: '中立',
          metadata: ChatVariableMetadata(enumOptions: ['中立', '敌对']),
        ),
        const ChatVariable(
          name: 'freeEnum',
          type: ChatVariableType.enumType,
          value: '未知',
        ),
      ]);

      expect(config.items.length, 5);
      expect(config.items[0].type, VariablePanelComponentType.progress);
      expect(config.items[0].width, 2);
      expect(config.items[0].height, 1);
      expect(config.items[1].type, VariablePanelComponentType.text);
      expect(config.items[1].width, 1);
      expect(config.items[1].height, 1);
      expect(config.items[2].type, VariablePanelComponentType.multilineText);
      expect(config.items[2].width, 2);
      expect(config.items[2].height, 2);
      expect(config.items[3].type, VariablePanelComponentType.capsule);
      expect(config.items[3].width, 2);
      expect(config.items[3].height, 1);
      expect(config.items[4].type, VariablePanelComponentType.text);
      expect(config.items[4].width, 1);
      expect(config.items[4].height, 1);
      expect(config.items.map((item) => item.id).toSet().length, 5);
    });
  });

  group('变量变更同步', () {
    test('新增变量追加默认组件', () {
      final config = VariablePanelConfig(items: [progressItem]);
      final next = config.afterVariableUpdated(
        current: const ChatVariable(
          name: 'mana',
          type: ChatVariableType.number,
          value: '5',
        ),
      );

      expect(next.items.length, 2);
      expect(next.items.last.variableName, 'mana');
      expect(next.items.last.type, VariablePanelComponentType.text);
      expect(next.items.first.id, 'a');
    });

    test('显式空面板新增变量时不自动追加组件', () {
      const empty = VariablePanelConfig(items: []);
      final next = empty.afterVariableUpdated(
        current: const ChatVariable(
          name: 'mana',
          type: ChatVariableType.number,
          value: '5',
        ),
      );

      expect(next.items, isEmpty);
    });

    test('改名更新全部绑定', () {
      final config = VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'a',
            type: VariablePanelComponentType.text,
            variableName: 'hp',
          ),
          VariablePanelItem(
            id: 'b',
            type: VariablePanelComponentType.text,
            variableName: 'hp',
          ),
          VariablePanelItem(
            id: 'c',
            type: VariablePanelComponentType.text,
            variableName: 'mp',
          ),
        ],
      );
      final next = config.afterVariableUpdated(
        previous: const ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '1',
        ),
        current: const ChatVariable(
          name: '生命',
          type: ChatVariableType.number,
          value: '1',
        ),
      );

      expect(next.items[0].variableName, '生命');
      expect(next.items[1].variableName, '生命');
      expect(next.items[2].variableName, 'mp');
    });

    test('改类型替换不兼容组件并保留标题与尺寸', () {
      final config = VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'a',
            type: VariablePanelComponentType.progress,
            width: 2,
            height: 1,
            variableName: 'hp',
            title: '生命',
          ),
        ],
      );
      final next = config.afterVariableUpdated(
        previous: const ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '1',
        ),
        current: const ChatVariable(
          name: 'hp',
          type: ChatVariableType.text,
          value: '重伤',
        ),
      );

      final item = next.items.single;
      expect(item.type, VariablePanelComponentType.multilineText);
      expect(item.width, 2);
      expect(item.height, 1);
      expect(item.displayTitle, '生命');
    });

    test('删除变量移除绑定组件，保留空白块', () {
      final config = VariablePanelConfig(
        items: [
          progressItem,
          const VariablePanelItem(
            id: 'space',
            type: VariablePanelComponentType.blank,
          ),
        ],
      );
      final next = config.afterVariableRemoved('hp');

      expect(next.items.length, 1);
      expect(next.items.single.type, VariablePanelComponentType.blank);
    });

    test('withoutMissingVariables 清理死绑定', () {
      final config = VariablePanelConfig(
        items: [progressItem],
      );
      final next = config.withoutMissingVariables([
        const ChatVariable(
          name: 'mp',
          type: ChatVariableType.number,
          value: '1',
        ),
      ]);

      expect(next.items, isEmpty);
    });
  });

  group('运行期变量追加', () {
    test('末尾追加卡外变量，跳过卡内声明但未布局的变量', () {
      final items = appendRuntimeVariables(
        VariablePanelConfig(items: [progressItem]),
        [
          const ChatVariable(
            name: 'hp',
            type: ChatVariableType.number,
            value: '10',
          ),
          const ChatVariable(
            name: 'mood',
            type: ChatVariableType.text,
            value: '平静',
          ),
          const ChatVariable(
            name: 'rage',
            type: ChatVariableType.number,
            value: '7',
          ),
        ],
        declaredVariableNames: const ['hp', 'mood'],
      );

      expect(items.length, 2);
      expect(items.first.id, 'a');
      expect(items.last.variableName, 'rage');
      expect(items.last.type, VariablePanelComponentType.text);
      expect(items.last.width, 1);
      expect(items.last.height, 1);
    });

    test('显式空布局保持为空', () {
      final items = appendRuntimeVariables(
        const VariablePanelConfig(items: []),
        [
          const ChatVariable(
            name: 'rage',
            type: ChatVariableType.number,
            value: '7',
          ),
        ],
      );

      expect(items, isEmpty);
    });

    test('空白块布局同样可以追加', () {
      final items = appendRuntimeVariables(
        const VariablePanelConfig(
          items: [
            VariablePanelItem(
              id: 'space',
              type: VariablePanelComponentType.blank,
            ),
          ],
        ),
        [
          const ChatVariable(
            name: 'rage',
            type: ChatVariableType.number,
            value: '7',
          ),
        ],
      );

      expect(items.length, 2);
      expect(items.last.variableName, 'rage');
    });
  });

  group('moveItem', () {
    test('按目标位置移动并忽略越界', () {
      final config = VariablePanelConfig(
        items: const [
          VariablePanelItem(
            id: 'a',
            type: VariablePanelComponentType.text,
            variableName: 'a',
          ),
          VariablePanelItem(
            id: 'b',
            type: VariablePanelComponentType.text,
            variableName: 'b',
          ),
          VariablePanelItem(
            id: 'c',
            type: VariablePanelComponentType.text,
            variableName: 'c',
          ),
        ],
      );

      expect(
        config.moveItem(0, 2).items.map((item) => item.id),
        ['b', 'c', 'a'],
      );
      expect(config.moveItem(2, 0).items.map((item) => item.id), [
        'c',
        'a',
        'b',
      ]);
      expect(config.moveItem(-1, 0), same(config));
      expect(config.moveItem(0, 3), same(config));
      expect(config.moveItem(1, 1), same(config));
    });
  });

  group('运行时配置', () {
    test('null 回退默认布局，显式空配置保持为空', () {
      const variables = [
        ChatVariable(
          name: 'hp',
          type: ChatVariableType.number,
          value: '1',
        ),
      ];

      final generated = resolveVariablePanelConfig(null, variables);
      expect(generated.items.length, 1);
      expect(generated.items.single.variableName, 'hp');

      final empty = resolveVariablePanelConfig(
        const VariablePanelConfig(items: []),
        variables,
      );
      expect(empty.isEmpty, isTrue);
    });
  });
}
