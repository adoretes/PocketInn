// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CharacterSummary _$CharacterSummaryFromJson(Map<String, dynamic> json) =>
    _CharacterSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardColorValue: (json['cardColorValue'] as num?)?.toInt(),
      updatedAt: const NullableDateTimeConverter().fromJson(
        json['updatedAt'] as String?,
      ),
    );

Map<String, dynamic> _$CharacterSummaryToJson(_CharacterSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'thumbnailPath': instance.thumbnailPath,
      'description': instance.description,
      'cardColorValue': instance.cardColorValue,
      'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
    };

_CharacterCardRecord _$CharacterCardRecordFromJson(Map<String, dynamic> json) =>
    _CharacterCardRecord(
      id: json['id'] as String? ?? '',
      cardJson: json['cardJson'] as Map<String, dynamic>? ?? {},
      originalImagePath: json['originalImagePath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      worldBookId: json['worldBookId'] as String?,
      characterBookExtensions:
          json['characterBookExtensions'] as Map<String, dynamic>? ?? {},
      cardColorValue: (json['cardColorValue'] as num?)?.toInt(),
      updatedAt: const NullableDateTimeConverter().fromJson(
        json['updatedAt'] as String?,
      ),
    );

Map<String, dynamic> _$CharacterCardRecordToJson(
  _CharacterCardRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'cardJson': instance.cardJson,
  'originalImagePath': instance.originalImagePath,
  'thumbnailPath': instance.thumbnailPath,
  'worldBookId': instance.worldBookId,
  'characterBookExtensions': instance.characterBookExtensions,
  'cardColorValue': instance.cardColorValue,
  'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
};
