import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'date_time_converters.dart';

part 'world_book.freezed.dart';
part 'world_book.g.dart';

/// 世界书条目模型
@freezed
abstract class WorldBookEntry with _$WorldBookEntry {
  const WorldBookEntry._();

  const factory WorldBookEntry({
    @JsonKey(defaultValue: '') required String id,
    @Default([]) List<String> key,
    @Default([]) List<String> keysecondary,
    @JsonKey(defaultValue: '') required String content,
    @JsonKey(defaultValue: '') required String comment,
    @JsonKey(defaultValue: false) @Default(false) bool constant,
    @JsonKey(defaultValue: false) @Default(false) bool selective,
    @JsonKey(defaultValue: 0) @Default(0) int selectiveLogic,
    @JsonKey(defaultValue: 100) @Default(100) int order,
    @JsonKey(defaultValue: 0) @Default(0) int position,
    @JsonKey(defaultValue: 4) @Default(4) int depth,
    @JsonKey(defaultValue: 0) @Default(0) int sticky,
    @JsonKey(defaultValue: 0) @Default(0) int cooldown,
    @JsonKey(defaultValue: 0) @Default(0) int delay,
    @JsonKey(defaultValue: true) @Default(true) bool isEnabled,
    @JsonKey(defaultValue: {}) @Default({}) Map<String, dynamic> extensions,
  }) = _WorldBookEntry;

  factory WorldBookEntry.fromJson(Map<String, dynamic> json) =>
      _$WorldBookEntryFromJson(json);

  /// 从 SillyTavern 格式创建
  factory WorldBookEntry.fromSillyTavern(Map<String, dynamic> json, String id) {
    return WorldBookEntry(
      id: id,
      key: (json['key'] as List<dynamic>?)?.cast<String>() ?? [],
      keysecondary:
          (json['keysecondary'] as List<dynamic>?)?.cast<String>() ?? [],
      content: json['content'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      constant: json['constant'] as bool? ?? false,
      selective: json['selective'] as bool? ?? false,
      selectiveLogic: json['selectiveLogic'] as int? ?? 0,
      order: json['order'] as int? ?? 100,
      position: json['position'] as int? ?? 0,
      depth: json['depth'] as int? ?? 4,
      sticky: json['sticky'] as int? ?? 0,
      cooldown: json['cooldown'] as int? ?? 0,
      delay: json['delay'] as int? ?? 0,
      isEnabled: !(json['disable'] as bool? ?? false),
      extensions: _parseExtensions(json),
    );
  }

  /// 获取条目标题（优先使用备注，其次使用第一个关键词）
  String get title {
    if (comment.trim().isNotEmpty) {
      return comment;
    }
    if (key.isNotEmpty) {
      return key.first;
    }
    return '未命名条目';
  }

  /// 转换为 SillyTavern 格式
  Map<String, dynamic> toSillyTavernJson(int uid) {
    final result = <String, dynamic>{
      'uid': uid,
      'key': key,
      'keysecondary': keysecondary,
      'comment': comment,
      'content': content,
      'constant': constant,
      'selective': selective,
      'order': order,
      'position': position,
      'disable': !isEnabled,
      'displayIndex': uid,
      'addMemo': true,
      'group': '',
      'groupOverride': false,
      'groupWeight': 100,
      'sticky': sticky,
      'cooldown': cooldown,
      'delay': delay,
      'probability': 100,
      'depth': depth,
      'useProbability': true,
      'role': null,
      'vectorized': false,
      'excludeRecursion': false,
      'preventRecursion': false,
      'delayUntilRecursion': false,
      'scanDepth': null,
      'caseSensitive': null,
      'matchWholeWords': null,
      'useGroupScoring': null,
      'automationId': '',
    };

    // 添加扩展字段
    extensions.forEach((key, value) {
      if (!result.containsKey(key)) {
        result[key] = value;
      }
    });

    return result;
  }

  /// 解析 ST 格式中的扩展字段
  static Map<String, dynamic> _parseExtensions(Map<String, dynamic> json) {
    final extensions = <String, dynamic>{};
    final knownKeys = {
      'uid',
      'key',
      'keysecondary',
      'comment',
      'content',
      'constant',
      'selective',
      'selectiveLogic',
      'order',
      'position',
      'disable',
      'depth',
      'sticky',
      'cooldown',
      'delay',
      'displayIndex',
      'addMemo',
      'group',
      'groupOverride',
      'groupWeight',
      'probability',
      'useProbability',
      'role',
      'vectorized',
      'excludeRecursion',
      'preventRecursion',
      'delayUntilRecursion',
      'scanDepth',
      'caseSensitive',
      'matchWholeWords',
      'useGroupScoring',
      'automationId',
    };

    json.forEach((key, value) {
      if (!knownKeys.contains(key)) {
        extensions[key] = value;
      }
    });

    return extensions;
  }
}

/// 世界书模型
// ignore_for_file: invalid_annotation_target
@freezed
abstract class WorldBook with _$WorldBook {
  const WorldBook._();

  @JsonSerializable(explicitToJson: true)
  const factory WorldBook({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: '') required String description,
    @JsonKey(defaultValue: 0xFF4B6CB7) required int colorValue,
    @Default([]) List<WorldBookEntry> entries,
    @NullableDateTimeConverter() DateTime? updatedAt,
  }) = _WorldBook;

  factory WorldBook.fromJson(Map<String, dynamic> json) =>
      _$WorldBookFromJson(json);

  /// 从 SillyTavern 格式创建
  factory WorldBook.fromSillyTavernJson(
    String jsonContent, {
    String? name,
    int? colorValue,
  }) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    final entriesData = data['entries'] as Map<String, dynamic>?;
    if (entriesData == null) {
      throw const FormatException('缺少 entries 字段');
    }

    final entries = <WorldBookEntry>[];
    final sortedKeys = entriesData.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    for (final key in sortedKeys) {
      final entryJson = entriesData[key] as Map<String, dynamic>;
      final entry = WorldBookEntry.fromSillyTavern(entryJson, 'entry-$key');
      entries.add(entry);
    }

    return WorldBook(
      id: 'wb-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? '导入的世界书',
      description: '从 SillyTavern 格式导入',
      colorValue: colorValue ?? 0xFF4B6CB7,
      entries: entries,
      updatedAt: DateTime.now(),
    );
  }

  /// 获取 Color 对象
  Color get color => Color(colorValue);

  /// 转换为 SillyTavern 格式 JSON
  Map<String, dynamic> toSillyTavernJson() {
    final entriesMap = <String, Map<String, dynamic>>{};
    for (var i = 0; i < entries.length; i++) {
      entriesMap[i.toString()] = entries[i].toSillyTavernJson(i);
    }

    return {'entries': entriesMap};
  }

  /// 转换为索引信息
  WorldBookIndexInfo toIndexInfo() {
    return WorldBookIndexInfo(
      id: id,
      name: name,
      description: description,
      colorValue: colorValue,
      entryCount: entries.length,
      updatedAt: updatedAt,
    );
  }

  /// 使用 Color 复制并修改
  WorldBook copyWithColor(Color color) => copyWith(colorValue: color.toARGB32());
}

/// 世界书索引信息（用于列表显示）
@freezed
abstract class WorldBookIndexInfo with _$WorldBookIndexInfo {
  const WorldBookIndexInfo._();

  const factory WorldBookIndexInfo({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: '') required String description,
    @JsonKey(defaultValue: 0xFF4B6CB7) required int colorValue,
    @JsonKey(defaultValue: 0) @Default(0) int entryCount,
    @NullableDateTimeConverter() DateTime? updatedAt,
  }) = _WorldBookIndexInfo;

  factory WorldBookIndexInfo.fromJson(Map<String, dynamic> json) =>
      _$WorldBookIndexInfoFromJson(json);

  /// 获取 Color 对象
  Color get color => Color(colorValue);
}
