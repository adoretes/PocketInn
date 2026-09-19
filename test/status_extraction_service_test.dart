import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/services/status_extraction_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import 'helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  tearDownAll(() async {
    tearDownPathProviderMocks(tempDir);
  });

  group('parseVariableOps 容错解析', () {
    test('标准 JSON 输出', () {
      final ops = parseVariableOps(
        '{"ops": [{"op": "add", "var": "好感度", "value": 5, "reason": "帮忙"},'
        ' {"op": "set", "var": "心情", "value": "开心"}]}',
      );
      expect(ops.length, 2);
      expect(ops[0].kind, VariableOpKind.add);
      expect(ops[0].variable, '好感度');
      expect(ops[0].value, '5');
      expect(ops[1].kind, VariableOpKind.set);
      expect(ops[1].value, '开心');
    });

    test('剥离 Markdown 围栏与杂文', () {
      final ops = parseVariableOps(
        '好的，以下是变化：\n```json\n{"ops": [{"op": "add", "var": "金币", "value": -3}]}\n```\n以上。',
      );
      expect(ops.length, 1);
      expect(ops[0].value, '-3');
    });

    test('接受裸数组输出', () {
      final ops = parseVariableOps('[{"op": "set", "name": "状态", "value": "疲惫"}]');
      expect(ops.length, 1);
      expect(ops[0].variable, '状态');
    });

    test('空 ops 与无变化输出', () {
      expect(parseVariableOps('{"ops": []}'), isEmpty);
      expect(parseVariableOps('没有发生变化。'), isEmpty);
      expect(parseVariableOps(''), isEmpty);
    });

    test('非法条目被过滤，其余保留', () {
      final ops = parseVariableOps(
        '{"ops": [{"op": "unknown", "var": "x", "value": 1},'
        ' {"op": "set", "var": "金币", "value": 9},'
        ' {"op": "add", "var": "", "value": 1}]}',
      );
      expect(ops.length, 1);
      expect(ops[0].variable, '金币');
    });

    test('JSON 前的孤立花括号不干扰解析', () {
      final ops = parseVariableOps(
        '变量{1}保持不变。真正的输出：{"ops": [{"op": "add", "var": "好感度", "value": 1}]}',
      );
      expect(ops.length, 1);
      expect(ops[0].variable, '好感度');
    });
  });

  group('buildStatusExtractionPrompt', () {
    VariableState stateWithHint() => VariableState.fromVariables({
      '好感度': const ChatVariable(
        name: '好感度',
        type: ChatVariableType.number,
        value: '10',
        metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
        changeHint: '帮她做事 +5，被冷落 -3',
      ),
      '心情': const ChatVariable(
        name: '心情',
        type: ChatVariableType.enumType,
        value: '平静',
        metadata: ChatVariableMetadata(enumOptions: ['平静', '心动']),
      ),
    });

    test('注入变量状态、约束与变化说明', () {
      final prompt = buildStatusExtractionPrompt(state: stateWithHint());

      expect(prompt, contains('"好感度": "10"'));
      expect(prompt, contains('"心情": "平静"'));
      expect(prompt, contains('数值范围（越界会被钳制）：好感度 0~100'));
      expect(prompt, contains('枚举取值（仅允许下列选项）：心情 平静/心动'));
      expect(prompt, contains('变量变化说明'));
      expect(prompt, contains('好感度：帮她做事 +5，被冷落 -3'));
    });

    test('无变化说明时不追加该段落', () {
      final prompt = buildStatusExtractionPrompt(
        state: VariableState.fromVariables({
          '好感度': const ChatVariable(
            name: '好感度',
            type: ChatVariableType.number,
            value: '10',
          ),
        }),
      );

      expect(prompt, isNot(contains('变量变化说明')));
    });

    test('自定义提示词替换 {{state}} 后同样追加说明', () {
      final prompt = buildStatusExtractionPrompt(
        state: stateWithHint(),
        customPrompt: '只输出 JSON。当前 {{state}}',
      );

      expect(prompt, startsWith('只输出 JSON。当前 {'));
      expect(prompt, contains('好感度：帮她做事 +5，被冷落 -3'));
    });
  });

  group('applyCardChangeHints', () {
    final state = VariableState.fromVariables({
      '好感度': const ChatVariable(
        name: '好感度',
        type: ChatVariableType.number,
        value: '10',
        changeHint: '旧说明',
      ),
      '心情': const ChatVariable(
        name: '心情',
        type: ChatVariableType.text,
        value: '平静',
        changeHint: '卡未声明，保留',
      ),
    });

    test('用角色卡声明覆盖同名说明，且不改动取值', () {
      final merged = applyCardChangeHints(state, {
        'data': {
          'extensions': {
            'variables': {
              '好感度': {
                'type': 'number',
                'value': '0',
                'changeHint': '新说明',
              },
            },
          },
        },
      });

      expect(merged['好感度']?.changeHint, '新说明');
      expect(merged['好感度']?.value, '10');
      expect(merged['心情']?.changeHint, '卡未声明，保留');
    });

    test('卡中变量未声明说明时清空旧说明', () {
      final merged = applyCardChangeHints(state, {
        'data': {
          'extensions': {
            'variables': {
              '好感度': {'type': 'number', 'value': '0'},
            },
          },
        },
      });

      expect(merged['好感度']?.changeHint, isNull);
    });

    test('空卡或无声明时原样返回', () {
      expect(applyCardChangeHints(state, {}), same(state));
      expect(
        applyCardChangeHints(state, {'data': {'extensions': {}}}),
        same(state),
      );
    });
  });

  group('StatusExtractionConfig', () {
    test('默认关闭，条数被钳制到合法区间', () {
      expect(statusExtractionNotifier.value.enabled, isFalse);

      updateStatusExtractionConfig(
        enabled: true,
        recentMessages: 999,
        extractionModelId: 'model-a',
      );
      var config = statusExtractionNotifier.value;
      expect(config.enabled, isTrue);
      expect(
        config.recentMessages,
        kStatusExtractionRecentMessagesMax,
      );
      expect(config.extractionModelId, 'model-a');

      updateStatusExtractionConfig(recentMessages: -5);
      expect(
        statusExtractionNotifier.value.recentMessages,
        kStatusExtractionRecentMessagesMin,
      );
    });

    test('配置持久化与重新加载往返', () async {
      updateStatusExtractionConfig(
        enabled: true,
        recentMessages: 12,
        customPrompt: '自定义 {{state}}',
      );

      // 模拟应用重启：重置为默认后从持久化加载。
      statusExtractionNotifier.value = const StatusExtractionConfig();
      await initializeStatusExtractionConfig();

      final config = statusExtractionNotifier.value;
      expect(config.enabled, isTrue);
      expect(config.recentMessages, 12);
      expect(config.customPrompt, '自定义 {{state}}');
    });

    tearDown(() {
      updateStatusExtractionConfig(
        enabled: false,
        extractionModelId: null,
        recentMessages: 6,
        customPrompt: '',
      );
    });
  });
}
