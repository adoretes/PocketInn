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
  ///
  /// 同时兼容 V2 角色书条目（`keys` / `secondary_keys` / `enabled` /
  /// `insertion_order` / 字符串形式的 `position`）。
  factory WorldBookEntry.fromSillyTavern(Map<String, dynamic> json, String id) {
    return WorldBookEntry(
      id: id,
      key: _parseStringList(json['key'] ?? json['keys']),
      keysecondary: _parseStringList(
        json['keysecondary'] ?? json['secondary_keys'],
      ),
      content: json['content'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      constant: json['constant'] as bool? ?? false,
      selective: json['selective'] as bool? ?? false,
      selectiveLogic: _normalizeSelectiveLogic(json['selectiveLogic']),
      order: _parseInt(json['order'] ?? json['insertion_order'], fallback: 100),
      position: _normalizePosition(json['position']),
      depth: _parseInt(json['depth'], fallback: 4),
      sticky: _parseInt(json['sticky']),
      cooldown: _parseInt(json['cooldown']),
      delay: _parseInt(json['delay']),
      isEnabled: _parseEnabled(json),
      extensions: _parseExtensions(json),
    );
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static int _parseInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  /// 应用只支持「角色定义之前 / 之后」两种注入位置，其它 ST 位置
  /// （作者注释前后、@D）统一归一化为「之后」。
  static int _normalizePosition(Object? value) {
    if (value is String) {
      return value == 'after_char' ? 1 : 0;
    }
    return _parseInt(value) == 0 ? 0 : 1;
  }

  static int _normalizeSelectiveLogic(Object? value) {
    final logic = _parseInt(value);
    return logic >= 0 && logic <= 3 ? logic : 0;
  }

  static bool _parseEnabled(Map<String, dynamic> json) {
    final enabled = json['enabled'];
    if (enabled is bool) {
      return enabled;
    }
    return !(json['disable'] as bool? ?? false);
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
  ///
  /// 只写入应用实际维护的字段；其余字段原样回写 [extensions]，
  /// 保证「导入 → 再导出」不会丢失概率、分组、递归等设置。
  Map<String, dynamic> toSillyTavernJson(int uid) {
    final result = <String, dynamic>{
      'uid': uid,
      'key': key,
      'keysecondary': keysecondary,
      'comment': comment,
      'content': content,
      'constant': constant,
      'selective': selective,
      'selectiveLogic':
          selectiveLogic >= 0 && selectiveLogic <= 3 ? selectiveLogic : 0,
      'order': order,
      'position': position,
      'disable': !isEnabled,
      'depth': depth,
      'sticky': sticky,
      'cooldown': cooldown,
      'delay': delay,
      'displayIndex': uid,
      'addMemo': true,
    };

    // 添加扩展字段（未建模的 ST 字段）
    extensions.forEach((key, value) {
      if (!result.containsKey(key)) {
        result[key] = value;
      }
    });

    return result;
  }

  /// 解析 ST 格式中的扩展字段
  ///
  /// 仅剔除以 [WorldBookEntry] 字段形式保存的键，其余（`probability`、
  /// `group`、递归开关等）都保留在 [extensions] 中。
  static Map<String, dynamic> _parseExtensions(Map<String, dynamic> json) {
    const modeledKeys = {
      'uid',
      'key',
      'keys',
      'keysecondary',
      'secondary_keys',
      'comment',
      'content',
      'constant',
      'selective',
      'selectiveLogic',
      'order',
      'insertion_order',
      'position',
      'disable',
      'enabled',
      'depth',
      'sticky',
      'cooldown',
      'delay',
    };

    final extensions = <String, dynamic>{};
    json.forEach((key, value) {
      if (!modeledKeys.contains(key)) {
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
      ..sort((a, b) {
        final aValue = int.tryParse(a);
        final bValue = int.tryParse(b);
        if (aValue != null && bValue != null) {
          return aValue.compareTo(bValue);
        }
        return a.compareTo(b);
      });

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
