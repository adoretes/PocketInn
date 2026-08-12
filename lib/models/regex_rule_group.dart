import 'dart:convert';

/// 正则替换规则
class RegexRule {
  const RegexRule({
    required this.id,
    required this.name,
    this.enabled = true,
    this.findRegex = '',
    this.replaceString = '',
    this.applyToUser = true,
    this.applyToAssistant = true,
    this.minDepth,
    this.maxDepth,
    this.applyOnWrite = true,
    this.applyOnSend = false,
    this.applyOnDisplay = false,
    this.extra = const {},
  });

  final String id;
  final String name;
  final bool enabled;
  final String findRegex;
  final String replaceString;
  final bool applyToUser;
  final bool applyToAssistant;

  /// 深度范围：从最新消息向前计数，0 为最新一条。null 表示不限。
  final int? minDepth;
  final int? maxDepth;

  /// 写入：替换写入聊天记录的内容，请求随之使用已替换文本。
  final bool applyOnWrite;

  /// 发送：仅替换送往模型的请求副本，不写库（对应 ST 的 promptOnly）。
  final bool applyOnSend;

  /// 显示：仅替换界面渲染文本，不写库、不参与请求（对应 ST 的 markdownOnly）。
  final bool applyOnDisplay;

  /// 导入时保留的未知/未执行字段。
  final Map<String, dynamic> extra;

  bool get appliesToUserOrAssistant => applyToUser || applyToAssistant;

  /// 仅作用于用户消息。
  bool get userOnly => applyToUser && !applyToAssistant;

  /// 仅作用于助手消息。
  bool get assistantOnly => applyToAssistant && !applyToUser;

  RegexRule copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? findRegex,
    String? replaceString,
    bool? applyToUser,
    bool? applyToAssistant,
    int? minDepth,
    int? maxDepth,
    bool? applyOnWrite,
    bool? applyOnSend,
    bool? applyOnDisplay,
    Map<String, dynamic>? extra,
    bool clearMinDepth = false,
    bool clearMaxDepth = false,
  }) {
    return RegexRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      findRegex: findRegex ?? this.findRegex,
      replaceString: replaceString ?? this.replaceString,
      applyToUser: applyToUser ?? this.applyToUser,
      applyToAssistant: applyToAssistant ?? this.applyToAssistant,
      minDepth: clearMinDepth ? null : (minDepth ?? this.minDepth),
      maxDepth: clearMaxDepth ? null : (maxDepth ?? this.maxDepth),
      applyOnWrite: applyOnWrite ?? this.applyOnWrite,
      applyOnSend: applyOnSend ?? this.applyOnSend,
      applyOnDisplay: applyOnDisplay ?? this.applyOnDisplay,
      extra: extra ?? this.extra,
    );
  }

  /// 本地存储与原生规则组导出的 JSON。
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'find_regex': findRegex,
      'replace_string': replaceString,
      'apply_to_user': applyToUser,
      'apply_to_assistant': applyToAssistant,
      'min_depth': minDepth,
      'max_depth': maxDepth,
      'apply_on_write': applyOnWrite,
      'apply_on_send': applyOnSend,
      'apply_on_display': applyOnDisplay,
      if (extra.isNotEmpty) 'extra': extra,
    };
  }

  factory RegexRule.fromStorageJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final extra =
        map['extra'] is Map ? Map<String, dynamic>.from(map['extra'] as Map) : null;
    map.remove('extra');
    return RegexRule(
      id: _readString(map, 'id') ?? _generateId(),
      name: _readString(map, 'name') ?? '未命名规则',
      enabled: _readBool(map, 'enabled', fallback: true),
      findRegex: _readString(map, 'find_regex') ?? '',
      replaceString: _readString(map, 'replace_string') ?? '',
      applyToUser: _readBool(map, 'apply_to_user', fallback: true),
      applyToAssistant: _readBool(map, 'apply_to_assistant', fallback: true),
      minDepth: _readNullableInt(map, 'min_depth'),
      maxDepth: _readNullableInt(map, 'max_depth'),
      applyOnWrite: _readBool(map, 'apply_on_write', fallback: true),
      applyOnSend: _readBool(map, 'apply_on_send', fallback: false),
      applyOnDisplay: _readBool(map, 'apply_on_display', fallback: false),
      extra: extra ?? const {},
    );
  }

  /// 兼容 SillyTavern 正则脚本导入。
  ///
  /// 映射：markdownOnly → 仅显示；promptOnly → 仅发送；其余默认为写入。
  /// 无法执行的字段（trimStrings、runOnEdit、substituteRegex、
  /// 未知 placement 位等）保留在 [extra]，导入后不静默丢弃。
  factory RegexRule.fromSillyTavernJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    final map = Map<String, dynamic>.from(json);
    final placement = map['placement'];

    var applyToUser = true;
    var applyToAssistant = true;
    if (placement is List && placement.isNotEmpty) {
      final values = placement
          .map((v) => v is num ? v.toInt() : int.tryParse('$v'))
          .whereType<int>()
          .toSet();
      // ST placement 位掩码：1=INPUT(用户输入), 2=OUTPUT(助手输出), 4=SLASH, 8=WORLD_INFO, 16=REASONING
      applyToUser = values.contains(1);
      applyToAssistant = values.contains(2);
    }

    final markdownOnly = _readBool(map, 'markdownOnly', fallback: false);
    final promptOnly = _readBool(map, 'promptOnly', fallback: false);

    return RegexRule(
      id: id ?? _readString(map, 'id') ?? _generateId(),
      name: _readString(map, 'scriptName') ?? '未命名规则',
      enabled: _readBool(map, 'enabled', fallback: !_readBool(map, 'disabled', fallback: false)),
      findRegex: _readString(map, 'findRegex') ?? '',
      replaceString: _readString(map, 'replaceString') ?? '',
      applyToUser: applyToUser,
      applyToAssistant: applyToAssistant,
      minDepth: _readNullableInt(map, 'minDepth'),
      maxDepth: _readNullableInt(map, 'maxDepth'),
      applyOnWrite: !markdownOnly && !promptOnly,
      applyOnSend: promptOnly,
      applyOnDisplay: markdownOnly,
      extra: _extractExtra(map),
    );
  }

  /// 校验正则是否可编译，返回 null 表示可用，否则返回错误信息。
  String? validateRegex() {
    if (findRegex.isEmpty) {
      return '查找正则不能为空';
    }
    try {
      RegExp(findRegex);
      return null;
    } catch (e) {
      return '正则无效：$e';
    }
  }

  static Map<String, dynamic> _extractExtra(Map<String, dynamic> map) {
    const known = {
      'id',
      'scriptName',
      'findRegex',
      'replaceString',
      'disabled',
      'enabled',
      'placement',
      'markdownOnly',
      'promptOnly',
      'minDepth',
      'maxDepth',
    };
    final extra = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!known.contains(entry.key)) {
        extra[entry.key] = entry.value;
      }
    }
    return extra;
  }

  static String? _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : null;
  }

  static bool _readBool(
    Map<String, dynamic> map,
    String key, {
    required bool fallback,
  }) {
    final value = map[key];
    return value is bool ? value : fallback;
  }

  static int? _readNullableInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static String _generateId() =>
      'rule-${DateTime.now().millisecondsSinceEpoch}';
}

/// 正则替换规则组。
class RegexRuleGroup {
  const RegexRuleGroup({
    required this.id,
    required this.name,
    this.rules = const [],
    required this.updatedAt,
    this.extra = const {},
  });

  final String id;
  final String name;
  final List<RegexRule> rules;
  final DateTime updatedAt;

  /// 导入时保留的外部元数据（如来源绑定信息）。
  final Map<String, dynamic> extra;

  int get enabledRuleCount => rules.where((r) => r.enabled).length;

  RegexRuleGroup copyWith({
    String? name,
    List<RegexRule>? rules,
    DateTime? updatedAt,
    Map<String, dynamic>? extra,
  }) {
    return RegexRuleGroup(
      id: id,
      name: name ?? this.name,
      rules: rules ?? this.rules,
      updatedAt: updatedAt ?? this.updatedAt,
      extra: extra ?? this.extra,
    );
  }

  /// 本地存储与原生规则组导出的 JSON。
  Map<String, dynamic> toStorageJson() {
    return {
      'version': 1,
      'id': id,
      'name': name,
      'updated_at': updatedAt.toIso8601String(),
      'rules': rules.map((r) => r.toStorageJson()).toList(),
      if (extra.isNotEmpty) 'extra': extra,
    };
  }

  factory RegexRuleGroup.fromStorageJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final extra =
        map['extra'] is Map ? Map<String, dynamic>.from(map['extra'] as Map) : null;
    map.remove('extra');
    final rules = map['rules'] is List
        ? (map['rules'] as List)
            .whereType<Map>()
            .map((r) => RegexRule.fromStorageJson(Map<String, dynamic>.from(r)))
            .toList()
        : const <RegexRule>[];
    final idValue = _readString(map, 'id');
    final nameValue = _readString(map, 'name');
    final updatedAtValue = _readString(map, 'updated_at');
    return RegexRuleGroup(
      id: idValue.isNotEmpty ? idValue : _generateId(),
      name: nameValue.isNotEmpty ? nameValue : '未命名规则组',
      rules: rules,
      updatedAt: DateTime.tryParse(updatedAtValue) ?? DateTime.now(),
      extra: extra ?? const {},
    );
  }

  /// 原生规则组导出的 JSON 字符串。
  String exportJsonString() {
    return const JsonEncoder.withIndent('  ').convert(
      (() {
        final json = toStorageJson();
        json.remove('id');
        json.remove('updated_at');
        return json;
      })(),
    );
  }

  /// 从原生规则组 JSON 解析。
  static RegexRuleGroup? fromExportJson(
    Map<String, dynamic> json, {
    required String id,
    required DateTime now,
  }) {
    if (json['rules'] is! List) return null;
    final map = Map<String, dynamic>.from(json);
    map['id'] = id;
    map['updated_at'] = now.toIso8601String();
    return RegexRuleGroup.fromStorageJson(map);
  }

  /// 是否为合法的原生规则组 JSON（含 rules 列表）。
  static bool looksLikeExportJson(Map<String, dynamic> json) {
    return json['rules'] is List;
  }

  static String _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : '';
  }

  static String _generateId() =>
      'group-${DateTime.now().millisecondsSinceEpoch}';
}
