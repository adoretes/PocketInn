import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/regex_rule_group_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';

import 'helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await WorldBookService.instance.initialize();
    await CharacterService.instance.initialize();
    await RegexRuleGroupService.instance.initialize();
  });

  tearDownAll(() {
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await StorageService.instance.clearAllData();
    await WorldBookService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await RegexRuleGroupService.instance.resetToDefaults();
  });

  test('创建角色时提取角色卡正则并绑定规则组', () async {
    final record = await CharacterService.instance.createFromCard(
      cardJson: _buildCardWithRegex(),
    );

    expect(record.cardData['extensions']['regex_scripts'], hasLength(2));
    final groupId =
        record.cardData['extensions'][CharacterService
                .cardRegexRuleGroupExtensionKey]
            as String;
    final group = await RegexRuleGroupService.instance.loadById(groupId);

    expect(group, isNotNull);
    expect(group!.name, '正则测试 - 正则');
    expect(group.rules, hasLength(2));
    expect(group.rules.first.name, '隐藏日志');
    expect(group.rules.first.applyOnDisplay, isTrue);
    expect(group.rules.first.applyToAssistant, isTrue);
    expect(group.rules.first.applyToUser, isFalse);
    expect(group.rules.last.findRegex, r'<(?:img)>.*?</(?:img)>');
  });

  test('重复同步复用同一规则组，不产生重复组', () async {
    final created = await CharacterService.instance.createFromCard(
      cardJson: _buildCardWithRegex(),
    );

    final sync = await CharacterService.instance.syncCardRegexRules(created);

    expect(sync.group, isNotNull);
    expect(sync.group!.rules, hasLength(2));
    expect(
      await RegexRuleGroupService.instance.loadAllSummaries(),
      hasLength(1),
    );
  });
}

Map<String, dynamic> _buildCardWithRegex() {
  final card = CharacterService.instance.buildEmptyCard();
  final data = Map<String, dynamic>.from(card['data'] as Map);
  data['name'] = '正则测试';
  data['extensions'] = {
    'regex_scripts': [
      {
        'id': 'card-rule-1',
        'scriptName': '隐藏日志',
        'findRegex': r'<details>[\s\S]*?</details>',
        'replaceString': '*后台日志已封录*',
        'disabled': false,
        'placement': [2],
        'markdownOnly': true,
        'promptOnly': false,
      },
      {
        'id': 'card-rule-2',
        'scriptName': '插图',
        'findRegex': r'/<(?:img)>.*?</(?:img)>/g',
        'replaceString': r'<center>$1</center>',
        'disabled': false,
        'placement': [2],
        'markdownOnly': true,
        'promptOnly': false,
      },
    ],
  };
  return {...card, 'data': data};
}
