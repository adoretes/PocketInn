import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/world_book.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_env.dart';

void main() {
  group('WorldBookEntry SillyTavern 兼容', () {
    test('归一化不支持的注入位置，并保留未建模字段', () {
      final entry = WorldBookEntry.fromSillyTavern({
        'key': ['龙'],
        'keysecondary': ['剑'],
        'content': '龙的设定',
        'comment': '龙',
        'constant': false,
        'selective': true,
        'selectiveLogic': 2,
        'order': 7,
        'position': 4,
        'depth': 3,
        'sticky': 1,
        'cooldown': 2,
        'delay': 3,
        'probability': 60,
        'useProbability': true,
        'group': '设定组',
        'role': 1,
        'excludeRecursion': true,
        'disable': true,
      }, 'entry-0');

      expect(entry.position, 1);
      expect(entry.isEnabled, isFalse);
      expect(entry.order, 7);
      expect(entry.extensions['probability'], 60);
      expect(entry.extensions['group'], '设定组');

      final exported = entry.toSillyTavernJson(3);
      expect(exported['position'], 1);
      expect(exported['disable'], isTrue);
      expect(exported['selectiveLogic'], 2);
      expect(exported['probability'], 60);
      expect(exported['useProbability'], isTrue);
      expect(exported['group'], '设定组');
      expect(exported['role'], 1);
      expect(exported['excludeRecursion'], isTrue);
    });

    test('兼容 V2 角色书字段（keys / enabled / insertion_order）', () {
      final entry = WorldBookEntry.fromSillyTavern({
        'keys': ['港区'],
        'secondary_keys': ['夜晚'],
        'content': '港区夜景',
        'insertion_order': 5,
        'position': 'after_char',
        'enabled': false,
      }, 'entry-1');

      expect(entry.key, ['港区']);
      expect(entry.keysecondary, ['夜晚']);
      expect(entry.order, 5);
      expect(entry.position, 1);
      expect(entry.isEnabled, isFalse);
    });

    test('selectiveLogic 越界值时归一化为默认逻辑', () {
      final entry = WorldBookEntry.fromSillyTavern({
        'key': ['龙'],
        'content': 'x',
        'selectiveLogic': 9,
      }, 'entry-2');

      expect(entry.selectiveLogic, 0);

      final exported = entry
          .copyWith(selectiveLogic: -1)
          .toSillyTavernJson(0);
      expect(exported['selectiveLogic'], 0);
    });
  });

  group('WorldBook 导入', () {
    test('覆盖条目的字段差异并按数字顺序排列', () {
      final content = jsonEncode({
        'entries': {
          '1': {
            'key': ['b'],
            'content': 'B',
            'position': 4,
          },
          '0': {
            'keys': ['a'],
            'content': 'A',
            'position': 0,
            'enabled': false,
          },
        },
      });

      final book = WorldBook.fromSillyTavernJson(content);

      expect(book.entries.map((entry) => entry.content), ['A', 'B']);
      expect(book.entries.first.isEnabled, isFalse);
      expect(book.entries.last.position, 1);
    });
  });

  test('服务生成的 ID 不重复', () {
    final ids = {
      for (var i = 0; i < 100; i++) WorldBookService.instance.generateId(),
    };
    expect(ids, hasLength(100));
  });

  group('索引自愈', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = setUpPathProviderMocks();
      SharedPreferences.setMockInitialValues({});
      await StorageService.instance.initialize();
      await WorldBookService.instance.initialize();
    });

    tearDownAll(() {
      tearDownPathProviderMocks(tempDir);
    });

    setUp(() async {
      await StorageService.instance.clearAllData();
      await WorldBookService.instance.clearAllData();
    });

    test('索引文件损坏时按目录重建，不会丢书', () async {
      final book = await WorldBookService.instance.create(name: '损坏索引测试');
      await StorageService.instance.writeJsonFile(
        'world_books_index.json',
        '{ not valid json',
      );

      final infos = await WorldBookService.instance.loadAllIndexInfo();
      expect(infos.map((info) => info.id), contains(book.id));

      // 重建后索引可正常读取，后续保存不会覆盖掉其它书
      final reloaded = await WorldBookService.instance.loadAllIndexInfo();
      expect(reloaded, hasLength(1));
      expect(reloaded.single.id, book.id);
    });
  });
}
