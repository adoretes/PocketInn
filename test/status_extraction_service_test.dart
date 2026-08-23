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
