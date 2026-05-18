import '../models/character_card.dart';
import 'character_service.dart';

class ResolvedChatCharacter {
  const ResolvedChatCharacter({
    required this.id,
    required this.name,
    required this.description,
    required this.cardJson,
    this.imagePath,
    this.thumbnailPath,
    this.isAssetImage = false,
    this.sourceLabel = '真实角色',
  });

  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> cardJson;
  final String? imagePath;
  final String? thumbnailPath;
  final bool isAssetImage;
  final String sourceLabel;
}

class ChatCharacterResolver {
  ChatCharacterResolver._();

  static final ChatCharacterResolver instance = ChatCharacterResolver._();

  Future<ResolvedChatCharacter?> resolveById(String characterId) async {
    final realRecord = await CharacterService.instance.loadById(characterId);
    if (realRecord != null) {
      return _fromRecord(realRecord);
    }
    return null;
  }

  Future<List<ResolvedChatCharacter>> loadAllOptions() async {
    final options = <ResolvedChatCharacter>[];

    final summaries = await CharacterService.instance.loadAllSummaries();
    for (final summary in summaries) {
      final record = await CharacterService.instance.loadById(summary.id);
      if (record == null) {
        continue;
      }
      options.add(_fromRecord(record));
    }

    return options;
  }

  ResolvedChatCharacter _fromRecord(CharacterCardRecord record) {
    return ResolvedChatCharacter(
      id: record.id,
      name: record.name.isNotEmpty ? record.name : '未命名角色',
      description: record.description,
      cardJson: record.cardJson,
      imagePath: record.originalImagePath.isNotEmpty
          ? record.originalImagePath
          : null,
      thumbnailPath: record.thumbnailPath.isNotEmpty
          ? record.thumbnailPath
          : null,
      sourceLabel: '真实角色',
    );
  }
}
