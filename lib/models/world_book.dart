import 'dart:convert';

import 'package:flutter/material.dart';

/// 世界书条目模型
class WorldBookEntry {
  const WorldBookEntry({
    required this.id,
    required this.key,
    required this.keysecondary,
    required this.content,
    required this.comment,
    required this.constant,
    required this.selective,
    required this.selectiveLogic,
    required this.order,
    required this.position,
    required this.depth,
    required this.sticky,
    required this.cooldown,
    required this.delay,
    required this.isEnabled,
    required this.extensions,
  });

  final String id;
  final List<String> key;
  final List<String> keysecondary;
  final String content;
  final String comment;
  final bool constant;
  final bool selective;
  final int selectiveLogic;
  final int order;
  final int position;
  final int depth;
  final int sticky;
  final int cooldown;
  final int delay;
  final bool isEnabled;
  final Map<String, dynamic> extensions;

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

  /// 从 JSON 创建
  factory WorldBookEntry.fromJson(Map<String, dynamic> json) {
    return WorldBookEntry(
      id: json['id'] as String? ?? '',
      key: (json['key'] as List<dynamic>?)?.cast<String>() ?? [],
      keysecondary: (json['keysecondary'] as List<dynamic>?)?.cast<String>() ?? [],
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
      isEnabled: json['isEnabled'] as bool? ?? true,
      extensions: (json['extensions'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// 从 SillyTavern 格式创建
  factory WorldBookEntry.fromSillyTavern(Map<String, dynamic> json, String id) {
    return WorldBookEntry(
      id: id,
      key: (json['key'] as List<dynamic>?)?.cast<String>() ?? [],
      keysecondary: (json['keysecondary'] as List<dynamic>?)?.cast<String>() ?? [],
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

  /// 解析 ST 格式中的扩展字段
  static Map<String, dynamic> _parseExtensions(Map<String, dynamic> json) {
    final extensions = <String, dynamic>{};
    final knownKeys = {
      'uid', 'key', 'keysecondary', 'comment', 'content', 'constant',
      'selective', 'selectiveLogic', 'order', 'position', 'disable',
      'depth', 'sticky', 'cooldown', 'delay', 'displayIndex', 'addMemo',
      'group', 'groupOverride', 'groupWeight', 'probability', 'useProbability',
      'role', 'vectorized', 'excludeRecursion', 'preventRecursion',
      'delayUntilRecursion', 'scanDepth', 'caseSensitive', 'matchWholeWords',
      'useGroupScoring', 'automationId',
    };
    
    json.forEach((key, value) {
      if (!knownKeys.contains(key)) {
        extensions[key] = value;
      }
    });
    
    return extensions;
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'keysecondary': keysecondary,
      'content': content,
      'comment': comment,
      'constant': constant,
      'selective': selective,
      'selectiveLogic': selectiveLogic,
      'order': order,
      'position': position,
      'depth': depth,
      'sticky': sticky,
      'cooldown': cooldown,
      'delay': delay,
      'isEnabled': isEnabled,
      'extensions': extensions,
    };
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

  /// 复制并修改
  WorldBookEntry copyWith({
    String? id,
    List<String>? key,
    List<String>? keysecondary,
    String? content,
    String? comment,
    bool? constant,
    bool? selective,
    int? selectiveLogic,
    int? order,
    int? position,
    int? depth,
    int? sticky,
    int? cooldown,
    int? delay,
    bool? isEnabled,
    Map<String, dynamic>? extensions,
  }) {
    return WorldBookEntry(
      id: id ?? this.id,
      key: key ?? this.key,
      keysecondary: keysecondary ?? this.keysecondary,
      content: content ?? this.content,
      comment: comment ?? this.comment,
      constant: constant ?? this.constant,
      selective: selective ?? this.selective,
      selectiveLogic: selectiveLogic ?? this.selectiveLogic,
      order: order ?? this.order,
      position: position ?? this.position,
      depth: depth ?? this.depth,
      sticky: sticky ?? this.sticky,
      cooldown: cooldown ?? this.cooldown,
      delay: delay ?? this.delay,
      isEnabled: isEnabled ?? this.isEnabled,
      extensions: extensions ?? this.extensions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorldBookEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 世界书模型
class WorldBook {
  const WorldBook({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.entries,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final List<WorldBookEntry> entries;
  final DateTime? updatedAt;

  /// 获取 Color 对象
  Color get color => Color(colorValue);

  /// 从 JSON 创建
  factory WorldBook.fromJson(Map<String, dynamic> json) {
    return WorldBook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF4B6CB7,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => WorldBookEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 从 SillyTavern 格式创建
  factory WorldBook.fromSillyTavernJson(String jsonContent, {String? name, int? colorValue}) {
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

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'entries': entries.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 转换为 SillyTavern 格式 JSON
  Map<String, dynamic> toSillyTavernJson() {
    final entriesMap = <String, Map<String, dynamic>>{};
    for (var i = 0; i < entries.length; i++) {
      entriesMap[i.toString()] = entries[i].toSillyTavernJson(i);
    }
    
    return {
      'entries': entriesMap,
    };
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

  /// 复制并修改
  WorldBook copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    Color? color,
    List<WorldBookEntry>? entries,
    DateTime? updatedAt,
  }) {
    final resolvedColorValue = colorValue ?? (color != null ? color.toARGB32() : this.colorValue);
    return WorldBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: resolvedColorValue,
      entries: entries ?? this.entries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorldBook && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 世界书索引信息（用于列表显示）
class WorldBookIndexInfo {
  const WorldBookIndexInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.entryCount,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final int entryCount;
  final DateTime? updatedAt;

  /// 获取 Color 对象
  Color get color => Color(colorValue);

  /// 从 JSON 创建
  factory WorldBookIndexInfo.fromJson(Map<String, dynamic> json) {
    return WorldBookIndexInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF4B6CB7,
      entryCount: json['entryCount'] as int? ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'entryCount': entryCount,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
