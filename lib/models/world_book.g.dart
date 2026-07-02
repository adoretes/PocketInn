// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorldBookEntry _$WorldBookEntryFromJson(Map<String, dynamic> json) =>
    _WorldBookEntry(
      id: json['id'] as String? ?? '',
      key:
          (json['key'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      keysecondary:
          (json['keysecondary'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      content: json['content'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      constant: json['constant'] as bool? ?? false,
      selective: json['selective'] as bool? ?? false,
      selectiveLogic: (json['selectiveLogic'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 100,
      position: (json['position'] as num?)?.toInt() ?? 0,
      depth: (json['depth'] as num?)?.toInt() ?? 4,
      sticky: (json['sticky'] as num?)?.toInt() ?? 0,
      cooldown: (json['cooldown'] as num?)?.toInt() ?? 0,
      delay: (json['delay'] as num?)?.toInt() ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
      extensions: json['extensions'] as Map<String, dynamic>? ?? {},
    );

Map<String, dynamic> _$WorldBookEntryToJson(_WorldBookEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'keysecondary': instance.keysecondary,
      'content': instance.content,
      'comment': instance.comment,
      'constant': instance.constant,
      'selective': instance.selective,
      'selectiveLogic': instance.selectiveLogic,
      'order': instance.order,
      'position': instance.position,
      'depth': instance.depth,
      'sticky': instance.sticky,
      'cooldown': instance.cooldown,
      'delay': instance.delay,
      'isEnabled': instance.isEnabled,
      'extensions': instance.extensions,
    };

_WorldBook _$WorldBookFromJson(Map<String, dynamic> json) => _WorldBook(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  colorValue: (json['colorValue'] as num?)?.toInt() ?? 4283133111,
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => WorldBookEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  updatedAt: const NullableDateTimeConverter().fromJson(
    json['updatedAt'] as String?,
  ),
);

Map<String, dynamic> _$WorldBookToJson(_WorldBook instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'colorValue': instance.colorValue,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
    };

_WorldBookIndexInfo _$WorldBookIndexInfoFromJson(Map<String, dynamic> json) =>
    _WorldBookIndexInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 4283133111,
      entryCount: (json['entryCount'] as num?)?.toInt() ?? 0,
      updatedAt: const NullableDateTimeConverter().fromJson(
        json['updatedAt'] as String?,
      ),
    );

Map<String, dynamic> _$WorldBookIndexInfoToJson(_WorldBookIndexInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'colorValue': instance.colorValue,
      'entryCount': instance.entryCount,
      'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
    };
