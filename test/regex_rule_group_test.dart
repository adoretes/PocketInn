import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/regex_rule_group.dart';
import 'package:pocket_inn/services/regex_rule_group_service.dart';
import 'package:pocket_inn/services/regex_replacement_service.dart';

const _sampleStRule = {
  'id': '74ceb5c0-0fdf-4f44-a128-3492fdb773bd',
  'scriptName': '选项',
  'findRegex': r'〖(.*?)〗\n〖1：(.*?)；2：(.*?)；3：(.*?)〗',
  'replaceString': '选项框',
  'trimStrings': [],
  'placement': [2],
  'disabled': false,
  'markdownOnly': true,
  'promptOnly': false,
  'runOnEdit': false,
  'substituteRegex': 0,
  'minDepth': null,
  'maxDepth': null,
};

void main() {
  group('RegexRuleGroup 原生序列化', () {
    test('storage round-trip 保留字段与顺序', () {
      final group = RegexRuleGroup(
        id: 'group-1',
        name: '测试组',
        updatedAt: DateTime(2026, 1, 2, 3, 4),
        rules: [
          RegexRule(
            id: 'rule-1',
            name: '规则A',
            findRegex: r'<CoT>[\n\s\S]*</CoT>',
            replaceString: '',
            applyToUser: true,
            applyToAssistant: false,
            minDepth: 2,
            maxDepth: null,
            applyOnWrite: false,
            applyOnDisplay: true,
            applyOnSend: true,
          ),
          RegexRule(
            id: 'rule-2',
            name: '规则B',
            findRegex: r'\[(\d+)\]',
            replaceString: r'#$1',
            applyToUser: false,
            applyToAssistant: true,
            enabled: false,
          ),
        ],
      );

      final restored = RegexRuleGroup.fromStorageJson(group.toStorageJson());

      expect(restored.id, 'group-1');
      expect(restored.name, '测试组');
      expect(restored.rules, hasLength(2));
      expect(restored.rules[0].name, '规则A');
      expect(restored.rules[0].applyToUser, isTrue);
      expect(restored.rules[0].applyToAssistant, isFalse);
      expect(restored.rules[0].minDepth, 2);
      expect(restored.rules[0].maxDepth, isNull);
      expect(restored.rules[0].applyOnWrite, isFalse);
      expect(restored.rules[0].applyOnDisplay, isTrue);
      expect(restored.rules[0].applyOnSend, isTrue);
      expect(restored.rules[1].enabled, isFalse);
      expect(restored.rules[1].replaceString, r'#$1');
      expect(restored.rules[1].applyOnWrite, isTrue);
      expect(restored.rules[1].applyOnSend, isFalse);
      expect(restored.rules[1].applyOnDisplay, isFalse);
    });

    test('导出 JSON 移除 id 与 updated_at，导入可还原', () {
      final group = RegexRuleGroup(
        id: 'group-1',
        name: '测试组',
        updatedAt: DateTime(2026),
        rules: [
          RegexRule(
            id: 'rule-1',
            name: '规则A',
            findRegex: 'a',
            replaceString: 'b',
          ),
        ],
      );

      final exported = jsonDecode(group.exportJsonString());
      expect(exported, isA<Map<String, dynamic>>());
      expect((exported as Map<String, dynamic>)['id'], isNull);
      expect(exported['updated_at'], isNull);
      expect(exported['rules'], isA<List<dynamic>>());

      final restored = RegexRuleGroup.fromExportJson(
        exported,
        id: 'group-new',
        now: DateTime(2027),
      );
      expect(restored!.id, 'group-new');
      expect(restored.name, '测试组');
      expect(restored.rules.single.name, '规则A');
      expect(restored.updatedAt.year, 2027);
    });
  });

  group('SillyTavern 兼容导入', () {
    test('单规则对象导入为规则组内的一条规则', () {
      final result = RegexRuleGroupService.parseStRulesFromJson(
        jsonEncode(_sampleStRule),
      );

      expect(result.rules, hasLength(1));
      expect(result.warnings, hasLength(1));
      expect(result.warnings.first, contains('trimStrings'));

      final rule = result.rules.single;
      expect(rule.name, '选项');
      expect(rule.findRegex, _sampleStRule['findRegex']);
      expect(rule.replaceString, '选项框');
      expect(rule.enabled, isTrue);
      expect(rule.applyOnDisplay, isTrue);
      expect(rule.applyOnWrite, isFalse);
      expect(rule.applyOnSend, isFalse);
      expect(rule.applyToUser, isFalse);
      expect(rule.applyToAssistant, isTrue);
      expect(rule.minDepth, isNull);
      expect(rule.maxDepth, isNull);
      expect(rule.extra['trimStrings'], isEmpty);
      expect(rule.extra['substituteRegex'], 0);
      expect(rule.extra.containsKey('id'), isFalse);
      expect(rule.extra.containsKey('scriptName'), isFalse);
      expect(rule.extra.containsKey('markdownOnly'), isFalse);
      expect(rule.extra.containsKey('promptOnly'), isFalse);
    });

    test('规则数组导入为多条规则', () {
      final result = RegexRuleGroupService.parseStRulesFromJson(
        jsonEncode([
          _sampleStRule,
          {..._sampleStRule, 'scriptName': '切除思考'},
        ]),
      );

      expect(result.rules, hasLength(2));
      expect(result.rules.map((r) => r.name).toList(), ['选项', '切除思考']);
      expect(result.rules[0].id, isNot(result.rules[1].id));
      expect(result.warnings, hasLength(2));
    });

    test('无效 ST JSON 抛出导入异常', () {
      expect(
        () => RegexRuleGroupService.parseStRulesFromJson('{"foo": 1}'),
        throwsA(isA<RegexRuleGroupImportException>()),
      );
      expect(
        () => RegexRuleGroupService.parseStRulesFromJson('[1, 2]'),
        throwsA(isA<RegexRuleGroupImportException>()),
      );
      expect(
        () => RegexRuleGroupService.parseStRulesFromJson('[]'),
        throwsA(isA<RegexRuleGroupImportException>()),
      );
    });

    test('disabled 为 true 时启用状态取反', () {
      final rule = RegexRule.fromSillyTavernJson({
        ..._sampleStRule,
        'scriptName': '停用规则',
        'disabled': true,
      });
      expect(rule.enabled, isFalse);
    });

    test('placement 位掩码映射用户与助手范围', () {
      final userOnly = RegexRule.fromSillyTavernJson(
        {..._sampleStRule, 'placement': [1]},
      );
      expect(userOnly.applyToUser, isTrue);
      expect(userOnly.applyToAssistant, isFalse);

      final both = RegexRule.fromSillyTavernJson(
        {..._sampleStRule, 'placement': [1, 2]},
      );
      expect(both.applyToUser, isTrue);
      expect(both.applyToAssistant, isTrue);
    });

    test('promptOnly 映射为仅发送，默认映射为写入', () {
      final promptOnly = RegexRule.fromSillyTavernJson({
        ..._sampleStRule,
        'markdownOnly': false,
        'promptOnly': true,
      });
      expect(promptOnly.applyOnSend, isTrue);
      expect(promptOnly.applyOnWrite, isFalse);
      expect(promptOnly.applyOnDisplay, isFalse);

      final normal = RegexRule.fromSillyTavernJson({
        ..._sampleStRule,
        'markdownOnly': false,
        'promptOnly': false,
      });
      expect(normal.applyOnWrite, isTrue);
      expect(normal.applyOnSend, isFalse);
      expect(normal.applyOnDisplay, isFalse);
    });

    test('无效正则保留但可被校验识别', () {
      final rule = RegexRule(
        id: 'rule-1',
        name: '坏规则',
        findRegex: '(',
        replaceString: '',
      );
      expect(rule.validateRegex(), isNotNull);

      final ok = RegexRule(
        id: 'rule-2',
        name: '好规则',
        findRegex: r'\d+',
        replaceString: '',
      );
      expect(ok.validateRegex(), isNull);
    });
  });

  group('RegexReplacementService 执行', () {
    final service = RegexReplacementService();

    List<RegexRuleGroup> groupsFor(List<RegexRule> rules) => [
          RegexRuleGroup(
            id: 'group-1',
            name: '测试组',
            rules: rules,
            updatedAt: DateTime(2026),
          ),
        ];

    test('按顺序执行并支持捕获组替换', () {
      final result = service.applyToMessage(
        text: '价格 [100] 元',
        groups: groupsFor([
          RegexRule(
            id: 'r1',
            name: '加#',
            findRegex: r'\[(\d+)\]',
            replaceString: r'#$1',
          ),
        ]),
        isUserMessage: true,
        depth: 0,
      );

      expect(result.text, '价格 #100 元');
      expect(result.modified, isTrue);
      expect(result.matchedRules, 1);
    });

    test('作用范围过滤：助手规则不影响用户消息', () {
      final result = service.applyToMessage(
        text: '你好',
        groups: groupsFor([
          RegexRule(
            id: 'r1',
            name: '仅助手',
            findRegex: '你好',
            replaceString: '再见',
            applyToUser: false,
            applyToAssistant: true,
          ),
        ]),
        isUserMessage: true,
        depth: 0,
      );

      expect(result.text, '你好');
      expect(result.modified, isFalse);
    });

    test('深度范围过滤', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '最近2条',
          findRegex: 'X',
          replaceString: 'Y',
          minDepth: 0,
          maxDepth: 1,
        ),
      ]);

      expect(
        service
            .applyToMessage(text: 'X', groups: groups, isUserMessage: true, depth: 0)
            .text,
        'Y',
      );
      expect(
        service
            .applyToMessage(text: 'X', groups: groups, isUserMessage: true, depth: 1)
            .text,
        'Y',
      );
      expect(
        service
            .applyToMessage(text: 'X', groups: groups, isUserMessage: true, depth: 2)
            .text,
        'X',
      );
    });

    test('写入规则仅在 store 阶段应用', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '写入',
          findRegex: 'A',
          replaceString: 'B',
          applyOnWrite: true,
          applyOnSend: false,
          applyOnDisplay: false,
        ),
      ]);

      expect(
        service
            .applyToMessage(text: 'A', groups: groups, isUserMessage: true, depth: 0)
            .text,
        'B',
      );
      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.request,
            )
            .text,
        'A',
      );
      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.display,
            )
            .text,
        'A',
      );
    });

    test('显示规则仅在 display 阶段应用', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '仅显示',
          findRegex: 'A',
          replaceString: 'B',
          applyOnWrite: false,
          applyOnSend: false,
          applyOnDisplay: true,
        ),
      ]);

      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.display,
            )
            .text,
        'B',
      );
      expect(
        service
            .applyToMessage(text: 'A', groups: groups, isUserMessage: true, depth: 0)
            .text,
        'A',
      );
      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.request,
            )
            .text,
        'A',
      );
    });

    test('发送规则仅在 request 阶段应用，不影响写入', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '仅发送',
          findRegex: 'A',
          replaceString: 'B',
          applyOnWrite: false,
          applyOnSend: true,
          applyOnDisplay: false,
        ),
      ]);

      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.request,
            )
            .text,
        'B',
      );
      expect(
        service
            .applyToMessage(text: 'A', groups: groups, isUserMessage: true, depth: 0)
            .text,
        'A',
      );
      expect(
        service
            .applyToMessage(
              text: 'A',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.display,
            )
            .text,
        'A',
      );
    });

    test('写入规则不参与请求列表替换（入库后请求即已替换）', () {
      final messages = [
        {'role': 'user', 'content': 'user A'},
      ];
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '写入',
          findRegex: 'A',
          replaceString: 'B',
          applyOnWrite: true,
          applyOnSend: false,
        ),
      ]);

      final result = service.applyToRequestMessages(
        messages: messages,
        groups: groups,
      );
      expect(result.single['content'], 'user A');
    });

    test('显示阶段不应用非显示规则（避免重复替换）', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '普通规则',
          findRegex: 'A',
          replaceString: 'B',
        ),
      ]);

      expect(
        service
            .applyToMessage(
              text: 'B',
              groups: groups,
              isUserMessage: true,
              depth: 0,
              mode: RegexExecutionMode.display,
            )
            .text,
        'B',
      );
    });

    test('禁用规则与无效正则跳过且不阻断后续规则', () {
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '禁用',
          findRegex: 'A',
          replaceString: 'B',
          enabled: false,
        ),
        RegexRule(id: 'r2', name: '无效', findRegex: '(', replaceString: 'C'),
        RegexRule(id: 'r3', name: '有效', findRegex: 'A', replaceString: 'D'),
      ]);

      final result = service.applyToMessage(
        text: 'A',
        groups: groups,
        isUserMessage: true,
        depth: 0,
      );
      expect(result.text, 'D');
      expect(result.modified, isTrue);
      expect(result.matchedRules, 1);
    });

    test('请求消息列表按角色与深度应用规则', () {
      final messages = [
        {'role': 'system', 'content': 'system'},
        {'role': 'assistant', 'content': 'assistant A'},
        {'role': 'user', 'content': 'user A'},
      ];
      final groups = groupsFor([
        RegexRule(
          id: 'r1',
          name: '替换A',
          findRegex: 'A',
          replaceString: 'B',
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ]);

      final result = service.applyToRequestMessages(
        messages: messages,
        groups: groups,
      );

      expect(result[0]['content'], 'system');
      expect(result[1]['content'], 'assistant B');
      expect(result[2]['content'], 'user B');
    });

    test('多行匹配', () {
      final result = service.applyToMessage(
        text: 'line1\nline2',
        groups: groupsFor([
          RegexRule(
            id: 'r1',
            name: '跨行',
            findRegex: r'line1\nline2',
            replaceString: 'merged',
          ),
        ]),
        isUserMessage: true,
        depth: 0,
      );
      expect(result.text, 'merged');
    });

    test(r"JS 风格替换语义：$$、$&、$`、$'、命名组", () {
      final group = groupsFor([
        RegexRule(
          id: 'r1',
          name: '语义',
          findRegex: r'(?<w>l)\w+',
          replaceString: r"$$-$<w>-[$&]-[$`]-[$']",
        ),
      ]);

      final result = service.applyToMessage(
        text: 'a big lion',
        groups: group,
        isUserMessage: true,
        depth: 0,
      );
      expect(result.text, r'a big $-l-[lion]-[a big ]-[]');
    });

    test('超出捕获组数量的引用保留字面量', () {
      final result = service.applyToMessage(
        text: '[1]',
        groups: groupsFor([
          RegexRule(
            id: 'r1',
            name: '组引用',
            findRegex: r'\[(\d)\]',
            replaceString: r'$2',
          ),
        ]),
        isUserMessage: true,
        depth: 0,
      );
      expect(result.text, r'$2');
    });
  });
}
