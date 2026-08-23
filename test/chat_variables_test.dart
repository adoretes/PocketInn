import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/chat_variables.dart';

void main() {
  group('VariableState.applyOps', () {
    test('set 创建新变量并按取值推断类型', () {
      final state = VariableState.empty().applyOps([
        const VariableOp(
          kind: VariableOpKind.set,
          variable: '好感度',
          value: '20',
        ),
        const VariableOp(
          kind: VariableOpKind.set,
          variable: '心情',
          value: '平静',
        ),
      ]);

      expect(state['好感度']?.type, ChatVariableType.number);
      expect(state['好感度']?.value, '20');
      expect(state['心情']?.type, ChatVariableType.text);
      expect(state['心情']?.value, '平静');
    });

    test('add 数值增减并格式化整数结果', () {
      const init = VariableOp(
        kind: VariableOpKind.set,
        variable: '好感度',
        value: '10',
      );
      final state = VariableState.empty().applyOps([
        init,
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '5.5',
        ),
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '好感度',
          value: '-6',
        ),
      ]);

      expect(state['好感度']?.value, '9.5');
    });

    test('add 在变量不存在时从 0 起加', () {
      final state = VariableState.empty().applyOps([
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '金币',
          value: '-3',
        ),
      ]);

      expect(state['金币']?.type, ChatVariableType.number);
      expect(state['金币']?.value, '-3');
    });

    test('数值结果受元数据 min/max 钳制', () {
      final state = VariableState.fromVariables({
        '生命': const ChatVariable(
          name: '生命',
          type: ChatVariableType.number,
          value: '95',
          metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
        ),
      }).applyOps([
        const VariableOp(kind: VariableOpKind.add, variable: '生命', value: '20'),
        const VariableOp(
          kind: VariableOpKind.add,
          variable: '生命',
          value: '-1000',
        ),
      ]);

      expect(state['生命']?.value, '0');
    });

    test('非法操作被丢弃且不中断整批', () {
      final state = VariableState.fromVariables({
        '心情': const ChatVariable(
          name: '心情',
          type: ChatVariableType.text,
          value: '平静',
        ),
      }).applyOps([
        // 文本变量无法 add：应被丢弃。
        const VariableOp(kind: VariableOpKind.add, variable: '心情', value: '1'),
        // 空值 set：应被丢弃。
        const VariableOp(kind: VariableOpKind.set, variable: '心情', value: ''),
        // 正常 set。
        const VariableOp(
          kind: VariableOpKind.set,
          variable: '心情',
          value: '动摇',
        ),
      ]);

      expect(state['心情']?.value, '动摇');
      expect(state.length, 1);
    });

    test('数值格式化去掉整数的尾随 .0', () {
      final state = VariableState.empty().applyOps([
        const VariableOp(
          kind: VariableOpKind.set,
          variable: '距离',
          value: '3.0',
        ),
      ]);

      expect(state['距离']?.value, '3');
    });
  });

  group('VariableState 序列化', () {
    test('toJson/fromJson 往返保留类型与元数据', () {
      final state = VariableState.fromVariables({
        '好感度': const ChatVariable(
          name: '好感度',
          type: ChatVariableType.number,
          value: '55',
          metadata: ChatVariableMetadata(
            minValue: 0,
            maxValue: 100,
            unit: '点',
          ),
        ),
        '状态': const ChatVariable(
          name: '状态',
          type: ChatVariableType.enumType,
          value: '心动',
          metadata: ChatVariableMetadata(enumOptions: ['平静', '心动']),
        ),
      });

      final restored = VariableState.decodeJson(state.encodeJson());
      expect(restored['好感度']?.value, '55');
      expect(restored['好感度']?.metadata?.maxValue, 100);
      expect(restored['好感度']?.metadata?.unit, '点');
      expect(restored['状态']?.type, ChatVariableType.enumType);
      expect(restored['状态']?.metadata?.enumOptions, ['平静', '心动']);
    });

    test('decodeJson 遇到非法输入返回空状态', () {
      expect(VariableState.decodeJson('not json').isEmpty, isTrue);
      expect(VariableState.decodeJson('[1,2]').isEmpty, isTrue);
    });

    test('macroMap 提供宏字符串表', () {
      final state = VariableState.fromVariables({
        '好感度': const ChatVariable(
          name: '好感度',
          type: ChatVariableType.number,
          value: '85',
        ),
      });
      expect(state.macroMap, {'好感度': '85'});
    });
  });

  group('VariableOp.fromJson 容错', () {
    test('接受同义字段名', () {
      final op = VariableOp.fromJson({
        'op': 'modify',
        'name': '好感度',
        'value': 66,
        'reason': '剧情推进',
      });
      expect(op?.kind, VariableOpKind.set);
      expect(op?.variable, '好感度');
      expect(op?.value, '66');
      expect(op?.reason, '剧情推进');
    });

    test('add 接受负数增量', () {
      final op = VariableOp.fromJson({
        'op': 'add',
        'var': '生命',
        'value': -5,
      });
      expect(op?.kind, VariableOpKind.add);
      expect(op?.value, '-5');
    });

    test('未知 op 或缺失字段返回 null', () {
      expect(VariableOp.fromJson({'op': 'explode', 'var': 'x', 'value': 1}), isNull);
      expect(VariableOp.fromJson({'op': 'set', 'value': 1}), isNull);
      expect(VariableOp.fromJson({'op': 'set', 'var': 'x'}), isNull);
      expect(VariableOp.fromJson('set'), isNull);
    });
  });
}
