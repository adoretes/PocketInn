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

  group('世界书条目身份修复', () {
    test('只修复缺失和重复 ID，并预留后续合法 ID', () {
      final entries = <Map<String, dynamic>>[
        {},
        {'id': null},
        {'id': ''},
        {'id': '  '},
        {'id': 'entry-0'},
        {'id': 'entry-0'},
        {'id': 'entry-1'},
      ];
      final json = <String, dynamic>{
        'id': 'wb-identity',
        'name': '身份测试',
        'entries': [
          for (var i = 0; i < entries.length; i++)
            {
              ...entries[i],
              'comment': '同名条目',
              'content': '内容-$i',
              'isEnabled': i.isEven,
              'extensions': {'probability': 60},
            },
        ],
      };

      final book = WorldBook.fromJson(json);
      expect(book.entries.map((entry) => entry.id), [
        'entry-2',
        'entry-3',
        'entry-4',
        'entry-5',
        'entry-0',
        'entry-6',
        'entry-1',
      ]);
      expect(book.entries.map((entry) => entry.content), [
        for (var i = 0; i < entries.length; i++) '内容-$i',
      ]);
      expect(book.entries.every((entry) => entry.comment == '同名条目'), isTrue);
      expect(book.entries.map((entry) => entry.isEnabled), [
        true,
        false,
        true,
        false,
        true,
        false,
        true,
      ]);
      expect(
        book.entries.every((entry) => entry.extensions['probability'] == 60),
        isTrue,
      );
      expect(identical(book.withUniqueEntryIds(), book), isTrue);
      expect(WorldBook.fromJson(json), book);
      expect(WorldBook.fromJson(book.toJson()), book);
    });

    test('独立 ST 导入的同名同内容条目保持独立，不按 uid 合并', () {
      final entry = {'uid': 1, 'comment': '同名条目', 'content': '相同内容'};
      final book = WorldBook.fromSillyTavernJson(
        jsonEncode({
          'entries': {'1': entry, '8': entry},
        }),
      );

      expect(book.entries.map((entry) => entry.id), ['entry-1', 'entry-8']);
      expect(identical(book.withUniqueEntryIds(), book), isTrue);
      expect(book.toSillyTavernJson()['entries'], hasLength(2));
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

    test('保存和追加条目会修复重复 ID，返回值与落盘一致', () async {
      final book = await WorldBookService.instance.create(name: '重复 ID 测试');
      const entry = WorldBookEntry(
        id: 'entry-0',
        comment: '同名条目',
        content: '内容',
      );
      await WorldBookService.instance.save(
        book.copyWith(entries: [entry, entry]),
      );
      final rawFile = File(
        '${StorageService.instance.dataDir}/world_books/${book.id}.json',
      );
      final saved = jsonDecode(await rawFile.readAsString()) as Map;
      expect((saved['entries'] as List).map((item) => item['id']), [
        'entry-0',
        'entry-1',
      ]);
      final updated = await WorldBookService.instance.addEntry(book.id, entry);
      expect(updated.entries.map((item) => item.id).toSet(), hasLength(3));
      expect(await WorldBookService.instance.loadById(book.id), updated);
    });

    test('加载历史脏文件后只更新或删除选中的条目', () async {
      final book = await WorldBookService.instance.create(name: '历史 ID 测试');
      const entry = WorldBookEntry(
        id: 'entry-0',
        comment: '同名条目',
        content: '第一条',
      );
      final rawFile = File(
        '${StorageService.instance.dataDir}/world_books/${book.id}.json',
      );
      await rawFile.writeAsString(
        jsonEncode(
          book
              .copyWith(
                entries: [
                  entry,
                  entry.copyWith(content: '第二条'),
                ],
              )
              .toJson(),
        ),
      );

      final loaded = (await WorldBookService.instance.loadById(book.id))!;
      expect(loaded.entries.map((item) => item.id), ['entry-0', 'entry-1']);
      final updated = await WorldBookService.instance.updateEntry(
        book.id,
        loaded.entries[1].copyWith(content: '仅修改第二条', isEnabled: false),
      );
      expect(updated.entries.map((item) => item.content), ['第一条', '仅修改第二条']);
      expect(updated.entries.map((item) => item.isEnabled), [true, false]);
      final deleted = await WorldBookService.instance.deleteEntry(
        book.id,
        loaded.entries[0].id,
      );
      expect(deleted.entries.single.content, '仅修改第二条');
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
