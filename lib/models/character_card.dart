import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'date_time_converters.dart';

part 'character_card.freezed.dart';
part 'character_card.g.dart';

@freezed
abstract class CharacterSummary with _$CharacterSummary {
  const factory CharacterSummary({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: '') required String thumbnailPath,
    @JsonKey(defaultValue: '') @Default('') String description,
    int? cardColorValue,
    @NullableDateTimeConverter() DateTime? updatedAt,
  }) = _CharacterSummary;

  factory CharacterSummary.fromJson(Map<String, dynamic> json) =>
      _$CharacterSummaryFromJson(json);
}

// ignore_for_file: invalid_annotation_target
@freezed
abstract class CharacterCardRecord with _$CharacterCardRecord {
  const CharacterCardRecord._();

  @JsonSerializable(explicitToJson: true)
  const factory CharacterCardRecord({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: {}) @Default({}) Map<String, dynamic> cardJson,
    @JsonKey(defaultValue: '') required String originalImagePath,
    @JsonKey(defaultValue: '') required String thumbnailPath,
    String? worldBookId,
    @JsonKey(defaultValue: {}) @Default({}) Map<String, dynamic> characterBookExtensions,
    int? cardColorValue,
    @NullableDateTimeConverter() DateTime? updatedAt,
  }) = _CharacterCardRecord;

  factory CharacterCardRecord.fromJson(Map<String, dynamic> json) =>
      _$CharacterCardRecordFromJson(json);

  String get name => cardData['name'] as String? ?? '';

  String get description => cardData['description'] as String? ?? '';

  Map<String, dynamic> get cardData =>
      _asStringMap(cardJson['data']) ?? <String, dynamic>{};

  CharacterSummary toSummary() {
    return CharacterSummary(
      id: id,
      name: name,
      thumbnailPath: thumbnailPath,
      description: description,
      cardColorValue: cardColorValue,
      updatedAt: updatedAt,
    );
  }

  String exportJsonString({Map<String, dynamic>? characterBook}) {
    final exportMap = normalizeToV2Card(cardJson);
    if (characterBook != null) {
      final data = Map<String, dynamic>.from(exportMap['data'] as Map);
      data['character_book'] = characterBook;
      exportMap['data'] = data;
    }
    return const JsonEncoder.withIndent('    ').convert(exportMap);
  }
}

Map<String, dynamic> normalizeToV2Card(Map<String, dynamic> source) {
  final sourceRoot = Map<String, dynamic>.from(source);
  final rawData =
      _asStringMap(sourceRoot['data']) ?? Map<String, dynamic>.from(sourceRoot);

  final alternateGreetings =
      (rawData['alternate_greetings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList();
  final tags = (rawData['tags'] as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList();

  return {
    'spec': 'chara_card_v2',
    'spec_version': '2.0',
    'data': {
      'name': rawData['name'] as String? ?? '',
      'description': rawData['description'] as String? ?? '',
      'personality': rawData['personality'] as String? ?? '',
      'scenario': rawData['scenario'] as String? ?? '',
      'first_mes': rawData['first_mes'] as String? ?? '',
      'mes_example': rawData['mes_example'] as String? ?? '',
      'creator_notes': rawData['creator_notes'] as String? ?? '',
      'system_prompt': rawData['system_prompt'] as String? ?? '',
      'post_history_instructions':
          rawData['post_history_instructions'] as String? ?? '',
      'alternate_greetings': alternateGreetings,
      'tags': tags,
      'character_book':
          _asStringMap(rawData['character_book']) ??
          <String, dynamic>{'entries': {}, 'extensions': {}},
      'extensions': _asStringMap(rawData['extensions']) ?? <String, dynamic>{},
    },
  };
}

Map<String, dynamic>? decodeCharacterCardJson(String content) {
  final decoded = jsonDecode(content);
  if (decoded is Map<String, dynamic>) {
    return tryNormalizeCharacterCardJson(decoded);
  }
  if (decoded is Map) {
    return tryNormalizeCharacterCardJson(Map<String, dynamic>.from(decoded));
  }
  return null;
}

Map<String, dynamic>? tryNormalizeCharacterCardJson(
  Map<String, dynamic> source,
) {
  if (!looksLikeCharacterCardJson(source)) {
    return null;
  }
  return normalizeToV2Card(source);
}

bool looksLikeCharacterCardJson(Map<String, dynamic> source) {
  final spec = source['spec'];
  if (spec is String && spec.trim().toLowerCase().startsWith('chara_card_')) {
    return source['data'] is Map;
  }

  final prompts = source['prompts'];
  final hasPresetSignature =
      prompts is List &&
      (source.containsKey('prompt_order') ||
          source.containsKey('temperature') ||
          source.containsKey('openai_max_context') ||
          source.containsKey('openai_max_tokens') ||
          source.containsKey('top_p') ||
          source.containsKey('top_k'));
  if (hasPresetSignature) {
    return false;
  }

  final rawData = _asStringMap(source['data']) ?? source;
  const characterFields = {
    'description',
    'personality',
    'scenario',
    'first_mes',
    'mes_example',
    'creator_notes',
    'system_prompt',
    'post_history_instructions',
    'alternate_greetings',
    'character_book',
  };

  return characterFields.any(rawData.containsKey);
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, dynamic entryValue) {
      return MapEntry(key.toString(), entryValue);
    });
  }
  return null;
}
