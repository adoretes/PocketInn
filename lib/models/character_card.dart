import 'dart:convert';

class CharacterSummary {
  const CharacterSummary({
    required this.id,
    required this.name,
    required this.thumbnailPath,
    this.description = '',
    this.cardColorValue,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String thumbnailPath;
  final String description;
  final int? cardColorValue;
  final DateTime? updatedAt;

  factory CharacterSummary.fromJson(Map<String, dynamic> json) {
    return CharacterSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardColorValue: json['cardColorValue'] as int?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnailPath': thumbnailPath,
      'description': description,
      'cardColorValue': cardColorValue,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CharacterCardRecord {
  const CharacterCardRecord({
    required this.id,
    required this.cardJson,
    required this.originalImagePath,
    required this.thumbnailPath,
    this.worldBookId,
    this.characterBookExtensions = const {},
    this.cardColorValue,
    this.updatedAt,
  });

  final String id;
  final Map<String, dynamic> cardJson;
  final String originalImagePath;
  final String thumbnailPath;
  final String? worldBookId;
  final Map<String, dynamic> characterBookExtensions;
  final int? cardColorValue;
  final DateTime? updatedAt;

  factory CharacterCardRecord.fromJson(Map<String, dynamic> json) {
    return CharacterCardRecord(
      id: json['id'] as String? ?? '',
      cardJson: _asStringMap(json['cardJson']) ?? const {},
      originalImagePath: json['originalImagePath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      worldBookId: json['worldBookId'] as String?,
      characterBookExtensions:
          _asStringMap(json['characterBookExtensions']) ?? const {},
      cardColorValue: json['cardColorValue'] as int?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardJson': cardJson,
      'originalImagePath': originalImagePath,
      'thumbnailPath': thumbnailPath,
      'worldBookId': worldBookId,
      'characterBookExtensions': characterBookExtensions,
      'cardColorValue': cardColorValue,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CharacterCardRecord copyWith({
    String? id,
    Map<String, dynamic>? cardJson,
    String? originalImagePath,
    String? thumbnailPath,
    String? worldBookId,
    bool clearWorldBookId = false,
    Map<String, dynamic>? characterBookExtensions,
    int? cardColorValue,
    bool clearCardColorValue = false,
    DateTime? updatedAt,
  }) {
    return CharacterCardRecord(
      id: id ?? this.id,
      cardJson: cardJson ?? this.cardJson,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      worldBookId: clearWorldBookId ? null : (worldBookId ?? this.worldBookId),
      characterBookExtensions:
          characterBookExtensions ?? this.characterBookExtensions,
      cardColorValue: clearCardColorValue
          ? null
          : (cardColorValue ?? this.cardColorValue),
      updatedAt: updatedAt ?? this.updatedAt,
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
  final rawData = _asStringMap(sourceRoot['data']) ??
      Map<String, dynamic>.from(sourceRoot);

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
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  return normalizeToV2Card(decoded);
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
