import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:pocket_inn/services/world_book_service.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pocket_inn_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
          return tempDir.path;
        });

    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await WorldBookService.instance.initialize();
    await CharacterService.instance.initialize();
    await ChatDatabaseService.instance.initialize();
  });

  tearDownAll(() async {
    await ChatDatabaseService.instance.deleteDatabaseFiles();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await StorageService.instance.clearAllData();
    await WorldBookService.instance.clearAllData();
    await CharacterService.instance.clearAllData();
    await ChatDatabaseService.instance.clearAllData();
  });

  test('deleting a character also removes its chat sessions', () async {
    final deletedCharacter = await CharacterService.instance.createFromCard(
      cardJson: _buildCard('Alice'),
    );
    final keptCharacter = await CharacterService.instance.createFromCard(
      cardJson: _buildCard('Bob'),
    );

    final deletedSessionA = await ChatDatabaseService.instance.createSession(
      characterId: deletedCharacter.id,
      title: 'Alice chat A',
    );
    final deletedSessionB = await ChatDatabaseService.instance.createSession(
      characterId: deletedCharacter.id,
      title: 'Alice chat B',
    );
    final keptSession = await ChatDatabaseService.instance.createSession(
      characterId: keptCharacter.id,
      title: 'Bob chat',
    );

    await CharacterService.instance.delete(deletedCharacter.id);

    expect(
      await CharacterService.instance.loadById(deletedCharacter.id),
      isNull,
    );
    expect(
      await ChatDatabaseService.instance.loadSessionById(deletedSessionA.id),
      isNull,
    );
    expect(
      await ChatDatabaseService.instance.loadSessionById(deletedSessionB.id),
      isNull,
    );
    expect(
      await ChatDatabaseService.instance.loadSessionById(keptSession.id),
      isNotNull,
    );

    final summaries = await ChatDatabaseService.instance.loadSessionSummaries();
    expect(summaries, hasLength(1));
    expect(summaries.single.id, keptSession.id);
    expect(summaries.single.characterId, keptCharacter.id);
  });

  test('updating a character can remove its portrait assets', () async {
    final sourceImage = File('${tempDir.path}/source_portrait.png');
    await sourceImage.writeAsBytes(_tinyPngBytes);

    final character = await CharacterService.instance.createFromCard(
      cardJson: _buildCard('Alice'),
      imageSourcePath: sourceImage.path,
    );

    expect(character.originalImagePath, isNotEmpty);
    expect(character.thumbnailPath, isNotEmpty);
    expect(await File(character.originalImagePath).exists(), isTrue);
    expect(await File(character.thumbnailPath).exists(), isTrue);

    await CharacterService.instance.updateCard(
      id: character.id,
      cardJson: _buildCard('Alice'),
      removeImage: true,
    );

    final updated = await CharacterService.instance.loadById(character.id);
    expect(updated, isNotNull);
    expect(updated!.originalImagePath, isEmpty);
    expect(updated.thumbnailPath, isEmpty);
    expect(updated.cardColorValue, isNull);
    expect(await File(character.originalImagePath).exists(), isFalse);
    expect(await File(character.thumbnailPath).exists(), isFalse);

    final summaries = await CharacterService.instance.loadAllSummaries();
    expect(summaries.single.thumbnailPath, isEmpty);
    expect(summaries.single.cardColorValue, isNull);
  });
}

Map<String, dynamic> _buildCard(String name) {
  final card = CharacterService.instance.buildEmptyCard();
  final data = Map<String, dynamic>.from(card['data'] as Map);
  data['name'] = name;
  return {...card, 'data': data};
}

const _tinyPngBytes = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
