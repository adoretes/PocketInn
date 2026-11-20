import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/world_book.dart';
import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/regex_rule_group_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  final picker = _ExportFilePicker();

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await WorldBookService.instance.initialize();
    await CharacterService.instance.initialize();
    await RegexRuleGroupService.instance.initialize();
    FilePicker.platform = picker;
  });

  tearDownAll(() => tearDownPathProviderMocks(tempDir));

  setUp(() async {
    await StorageService.instance.clearAllData();
    await WorldBookService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await RegexRuleGroupService.instance.resetToDefaults();
    picker.outputPath = '${tempDir.path}/export.json';
  });

  final cases = <String, List<Object?>>{
    '相同数字 ID': [7, 7],
    '数字和字符串 ID 碰撞': [7, '7'],
    '缺失 ID 的回退值与显式 ID 碰撞': [null, 0],
    '两个空 ID': ['', ''],
    '两个空白 ID': [' ', ' '],
    '同名但不同 ID': [1, 8],
  };
  for (final item in cases.entries) {
    test('角色书导入：${item.key}，保留两条独立记录', () async {
      final record = await CharacterService.instance.createFromCard(
        cardJson: _cardWithEntries([
          for (var i = 0; i < item.value.length; i++)
            {
              if (item.value[i] != null) 'id': item.value[i],
              'comment': '同名条目',
              'content': '内容-$i',
              'enabled': i == 0,
            },
        ]),
      );
      final file = File(
        '${StorageService.instance.dataDir}/world_books/${record.worldBookId}.json',
      );
      final stored = jsonDecode(await file.readAsString()) as Map;
      final entries = stored['entries'] as List;
      final ids = entries.map((entry) => entry['id'] as String).toList();

      expect(ids.toSet(), hasLength(2));
      expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
      expect(entries.map((entry) => entry['content']), ['内容-0', '内容-1']);
      expect(entries.map((entry) => entry['comment']), ['同名条目', '同名条目']);
      expect(entries.map((entry) => entry['isEnabled']), [true, false]);
      if (item.key == '同名但不同 ID') {
        expect(ids, ['entry-1', 'entry-8']);
      }
    });
  }

  test('角色书导出为数字 ID 时预留已有值，重复导出及回导入均保持独立', () async {
    final created = await WorldBookService.instance.create(name: '导出身份测试');
    final sourceIds = [
      'entry-foo',
      'entry-bar',
      'foo-1',
      'bar-1',
      'entry-01',
      'entry-0',
      'entry-1',
    ];
    final book = created.copyWith(
      entries: [
        for (var i = 0; i < sourceIds.length; i++)
          WorldBookEntry(
            id: sourceIds[i],
            comment: '同名条目',
            content: '内容-$i',
            isEnabled: i.isEven,
          ),
      ],
    );
    await WorldBookService.instance.save(book);
    final record = await CharacterService.instance.createFromCard(
      cardJson: _cardWithEntries([]),
      selectedWorldBookId: book.id,
    );

    final path = await CharacterService.instance.exportToJsonFile(record);
    final exported =
        jsonDecode(await File(path!).readAsString()) as Map<String, dynamic>;
    final entries = exported['data']['character_book']['entries'] as List;
    final exportedIds = entries.map((entry) => entry['id']).toList();
    expect(exportedIds, [2, 3, 1, 4, 5, 0, 6]);
    expect(exportedIds.toSet(), hasLength(sourceIds.length));
    expect(entries.map((entry) => entry['display_index']), [
      3,
      4,
      2,
      5,
      6,
      1,
      7,
    ]);
    // 导出不更改原书中的内部 ID。
    expect(await WorldBookService.instance.loadById(book.id), book);
    await CharacterService.instance.exportToJsonFile(record);
    expect(jsonDecode(await File(path).readAsString()), exported);

    final reimported = await CharacterService.instance.createFromCard(
      cardJson: exported,
    );
    final reloaded = (await WorldBookService.instance.loadById(
      reimported.worldBookId!,
    ))!;
    expect(reloaded.entries, hasLength(sourceIds.length));
    expect(
      reloaded.entries.map((entry) => entry.id).toSet(),
      hasLength(sourceIds.length),
    );
    expect(reloaded.entries.map((entry) => entry.content), [
      for (var i = 0; i < sourceIds.length; i++) '内容-$i',
    ]);
    expect(reloaded.entries.map((entry) => entry.isEnabled), [
      for (var i = 0; i < sourceIds.length; i++) i.isEven,
    ]);
  });
}

Map<String, dynamic> _cardWithEntries(List<Map<String, dynamic>> entries) {
  final card = CharacterService.instance.buildEmptyCard();
  return {
    ...card,
    'data': {
      ...card['data'] as Map<String, dynamic>,
      'name': '世界书身份测试',
      'character_book': {'entries': entries, 'extensions': <String, dynamic>{}},
    },
  };
}

class _ExportFilePicker extends FilePicker {
  late String outputPath;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async => outputPath;
}
