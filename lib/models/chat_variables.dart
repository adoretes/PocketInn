import 'dart:convert';

/// 变量类型。
///
/// - [number]：数值，支持 `add` 增减与 min/max 钳制；
/// - [text]：自由文本；
/// - [enumType]：枚举（取值建议来自 [ChatVariableMetadata.enumOptions]）。
enum ChatVariableType {
  number('数值'),
  text('文本'),
  enumType('枚举');

  const ChatVariableType(this.label);

  final String label;

  String get value => name;

  static ChatVariableType fromValue(String? value) {
    return ChatVariableType.values.firstWhere(
      (item) => item.value == value || item.name == value,
      orElse: () => ChatVariableType.text,
    );
  }
}

/// 变量元数据（范围、单位、枚举选项）。
///
/// 计划 A 仅在应用操作时用 min/max 钳制；计划 B 的可视化组件
/// 将消费其余字段（单位、枚举选项）做展示。
class ChatVariableMetadata {
  const ChatVariableMetadata({
    this.minValue,
    this.maxValue,
    this.unit,
    this.enumOptions = const <String>[],
  });

  final double? minValue;
  final double? maxValue;
  final String? unit;
  final List<String> enumOptions;

  @override
  bool operator ==(Object other) {
    if (other is! ChatVariableMetadata) {
      return false;
    }
    if (other.minValue != minValue ||
        other.maxValue != maxValue ||
        other.unit != unit) {
      return false;
    }
    if (other.enumOptions.length != enumOptions.length) {
      return false;
    }
    for (var i = 0; i < enumOptions.length; i++) {
      if (other.enumOptions[i] != enumOptions[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(minValue, maxValue, unit, Object.hashAll(enumOptions));

  ChatVariableMetadata copyWith({
    double? minValue,
    double? maxValue,
    String? unit,
    List<String>? enumOptions,
  }) {
    return ChatVariableMetadata(
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      unit: unit ?? this.unit,
      enumOptions: enumOptions ?? this.enumOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (minValue != null) 'min': minValue,
      if (maxValue != null) 'max': maxValue,
      if (unit != null && unit!.isNotEmpty) 'unit': unit,
      if (enumOptions.isNotEmpty) 'enumOptions': enumOptions,
    };
  }

  factory ChatVariableMetadata.fromJson(Map<String, dynamic> json) {
    return ChatVariableMetadata(
      minValue: (json['min'] as num?)?.toDouble(),
      maxValue: (json['max'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      enumOptions: (json['enumOptions'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }
}

/// 单个状态变量（不可变）。
class ChatVariable {
  const ChatVariable({
    required this.name,
    required this.type,
    required this.value,
    this.metadata,
  });

  final String name;
  final ChatVariableType type;
  final String value;
  final ChatVariableMetadata? metadata;

  @override
  bool operator ==(Object other) {
    return other is ChatVariable &&
        other.name == name &&
        other.type == type &&
        other.value == value &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(name, type, value, metadata);

  ChatVariable copyWith({
    ChatVariableType? type,
    String? value,
    ChatVariableMetadata? metadata,
  }) {
    return ChatVariable(
      name: name,
      type: type ?? this.type,
      value: value ?? this.value,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'value': value,
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }

  factory ChatVariable.fromJson(String name, Map<String, dynamic> json) {
    final metadataJson = json['metadata'];
    return ChatVariable(
      name: name,
      type: ChatVariableType.fromValue(json['type'] as String?),
      value: json['value']?.toString() ?? '',
      metadata: metadataJson is Map<String, dynamic>
          ? ChatVariableMetadata.fromJson(metadataJson)
          : null,
    );
  }

  /// 角色卡 `extensions.variables` 内的扁平形态。
  Map<String, dynamic> toCardJson() {
    final metadata = this.metadata;
    return {
      'type': type.value,
      'value': value,
      if (metadata?.minValue != null) 'min': metadata!.minValue,
      if (metadata?.maxValue != null) 'max': metadata!.maxValue,
      if (metadata?.unit != null && metadata!.unit!.isNotEmpty)
        'unit': metadata.unit,
      if (metadata?.enumOptions.isNotEmpty == true)
        'enumOptions': metadata!.enumOptions,
    };
  }

  /// 解析角色卡内声明的变量（字段名宽松：min/max/unit/enumOptions
  /// 可在顶层或 metadata 内）；名称缺失或整体非法返回 null。
  static ChatVariable? fromCardJson(dynamic json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    final dynamic nameRaw = map['name'] ?? map['var'];
    final name = nameRaw?.toString().trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    final metadataJson = map['metadata'];
    final merged = <String, dynamic>{
      if (metadataJson is Map) ...metadataJson,
      ...map,
    };
    return ChatVariable(
      name: name,
      type: ChatVariableType.fromValue(map['type'] as String?),
      value: map['value']?.toString() ?? '',
      metadata: ChatVariableMetadata(
        minValue: (merged['min'] as num?)?.toDouble(),
        maxValue: (merged['max'] as num?)?.toDouble(),
        unit: merged['unit'] as String?,
        enumOptions: (merged['enumOptions'] as List?)
                ?.map((item) => item.toString())
                .toList(growable: false) ??
            const <String>[],
      ),
    );
  }
}

/// 变量操作类型：[set] 直接赋值，[add] 数值增减。
enum VariableOpKind { set, add }

/// AI 状态提取调用的最小产物：一条变量操作。
///
/// 解析对字段名与取值做容错（如 op 写成 modify、变量名字段叫 name），
/// 非法条目在构造时被丢弃（返回 null）。
class VariableOp {
  const VariableOp({
    required this.kind,
    required this.variable,
    required this.value,
    this.reason,
  });

  final VariableOpKind kind;
  final String variable;
  final String value;
  final String? reason;

  Map<String, dynamic> toJson() {
    return {
      'op': kind.name,
      'var': variable,
      'value': value,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }

  static VariableOp? fromJson(dynamic json) {
    if (json is! Map) {
      return null;
    }
    final dynamic opRaw = json['op'] ?? json['action'] ?? json['operation'];
    final VariableOpKind kind;
    switch (opRaw?.toString().toLowerCase()) {
      case 'set':
      case 'modify':
      case 'update':
      case '赋值':
      case '设置':
        kind = VariableOpKind.set;
        break;
      case 'add':
      case 'plus':
      case 'sub':
      case 'delta':
      case '增加':
      case '增减':
        kind = VariableOpKind.add;
        break;
      default:
        return null;
    }

    final dynamic nameRaw =
        json['var'] ?? json['variable'] ?? json['name'] ?? json['key'];
    final variable = nameRaw?.toString().trim() ?? '';
    if (variable.isEmpty) {
      return null;
    }

    final dynamic valueRaw = json['value'] ?? json['val'] ?? json['to'];
    if (valueRaw == null) {
      return null;
    }

    final dynamic reasonRaw =
        json['reason'] ?? json['why'] ?? json['note'] ?? json['说明'];
    return VariableOp(
      kind: kind,
      variable: variable,
      value: valueRaw.toString().trim(),
      reason: reasonRaw?.toString(),
    );
  }
}

/// 某一消息时刻的变量快照（不可变）。
///
/// 状态 = 会话初始变量沿激活路径折叠各消息 diff 的结果；
/// 本类只负责承载与纯函数变换（[applyOps]），路径求值见
/// `VariableStateService`。
class VariableState {
  const VariableState._(this._variables);

  const VariableState.empty() : _variables = const <String, ChatVariable>{};

  final Map<String, ChatVariable> _variables;

  static VariableState fromVariables(Map<String, ChatVariable> variables) {
    return VariableState._(Map<String, ChatVariable>.unmodifiable(variables));
  }

  Iterable<ChatVariable> get variables => _variables.values;

  bool get isEmpty => _variables.isEmpty;

  int get length => _variables.length;

  ChatVariable? operator [](String name) => _variables[name];

  /// 供 `{{getvar}}` 宏使用的字符串表。
  Map<String, String> get macroMap {
    return {
      for (final variable in _variables.values) variable.name: variable.value,
    };
  }

  /// 按序应用一批操作，返回新状态。
  ///
  /// 单条非法操作（add 遇到非数值、变量名为空等）被静默丢弃，
  /// 不中断整批；数值结果受元数据 min/max 钳制。
  VariableState applyOps(List<VariableOp> ops) {
    if (ops.isEmpty) {
      return this;
    }
    final next = Map<String, ChatVariable>.from(_variables);
    var changed = false;
    for (final op in ops) {
      if (_applyOne(next, op)) {
        changed = true;
      }
    }
    return changed ? VariableState.fromVariables(next) : this;
  }

  bool _applyOne(Map<String, ChatVariable> target, VariableOp op) {
    final existing = target[op.variable];
    if (op.kind == VariableOpKind.set) {
      final updated = _normalizeSet(existing, op.variable, op.value);
      if (updated == null) {
        return false;
      }
      target[op.variable] = updated;
      return true;
    }

    // add：数值增减；变量不存在时按「从 0 起加」处理。
    final delta = double.tryParse(op.value);
    if (delta == null) {
      return false;
    }
    final baseRaw = existing?.value;
    final base = baseRaw == null ? 0.0 : double.tryParse(baseRaw);
    if (base == null) {
      return false;
    }
    final summed = _clampNumber(base + delta, existing?.metadata);
    final updated = (existing ?? _inferred(op.variable, summed))
        .copyWith(value: _formatNumber(summed));
    target[op.variable] = updated;
    return true;
  }

  ChatVariable? _normalizeSet(
    ChatVariable? existing,
    String name,
    String rawValue,
  ) {
    if (rawValue.isEmpty) {
      return null;
    }
    if (existing == null) {
      // 新变量：按取值推断类型（可解析为数值则 number，否则 text）。
      final numeric = double.tryParse(rawValue);
      return ChatVariable(
        name: name,
        type: numeric != null ? ChatVariableType.number : ChatVariableType.text,
        value: numeric != null
            ? _formatNumber(_clampNumber(numeric, null))
            : rawValue,
      );
    }
    if (existing.type == ChatVariableType.number) {
      final numeric = double.tryParse(rawValue);
      if (numeric != null) {
        return existing.copyWith(
          value: _formatNumber(_clampNumber(numeric, existing.metadata)),
        );
      }
    }
    return existing.copyWith(value: rawValue);
  }

  ChatVariable _inferred(String name, double value) {
    return ChatVariable(
      name: name,
      type: ChatVariableType.number,
      value: _formatNumber(value),
    );
  }

  static double _clampNumber(
    double value,
    ChatVariableMetadata? metadata,
  ) {
    var result = value;
    final min = metadata?.minValue;
    final max = metadata?.maxValue;
    if (min != null && result < min) {
      result = min;
    }
    if (max != null && result > max) {
      result = max;
    }
    return result;
  }

  static String _formatNumber(double value) {
    if (value.isFinite && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  /// 序列化为 `{名称: {type, value, metadata}}` 结构（保持插入顺序）。
  Map<String, dynamic> toJson() {
    return {
      for (final variable in _variables.values)
        variable.name: variable.toJson(),
    };
  }

  factory VariableState.fromJson(Map<String, dynamic> json) {
    final variables = <String, ChatVariable>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        variables[entry.key] = ChatVariable.fromJson(entry.key, value);
      }
    }
    return VariableState.fromVariables(variables);
  }

  String encodeJson() => jsonEncode(toJson());

  static VariableState decodeJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return VariableState.fromJson(decoded);
      }
    } catch (_) {}
    return VariableState.empty();
  }

  /// 序列化为角色卡 `data.extensions.variables` 使用的扁平结构（保序列表）。
  List<Map<String, dynamic>> toCardJsonList() {
    return [
      for (final variable in _variables.values) variable.toCardJson(),
    ];
  }

  /// 从角色卡声明的变量列表构建初始状态。
  static VariableState fromCardVariables(List<ChatVariable> variables) {
    return VariableState.fromVariables({
      for (final variable in variables) variable.name: variable,
    });
  }
}

// ==================== 角色卡变量编解码 ====================

/// 角色卡中声明初始状态变量的扩展键（位于 `data.extensions` 下）。
const String kCardVariablesExtensionKey = 'variables';

/// 序列化为角色卡 `data.extensions.variables` 的取值。
Map<String, dynamic> encodeCardVariables(List<ChatVariable> variables) {
  return {
    for (final variable in variables) variable.name: variable.toCardJson(),
  };
}

/// 从角色卡 JSON（含 `data.extensions.variables`）解析声明的变量列表。
///
/// 兼容两种形态：`{名称: {…}}` 映射（本应用保存的形态）与
/// `[{name: …}, …]` 列表（手写卡/导入的形态）；非法条目静默跳过。
/// 返回可增长列表（空声明时也为可增长），调用方可安全持有与追加。
List<ChatVariable> decodeCardVariables(Map<String, dynamic> cardJson) {
  final data = cardJson['data'];
  if (data is! Map<String, dynamic>) {
    return <ChatVariable>[];
  }
  final extensions = data['extensions'];
  if (extensions is! Map<String, dynamic>) {
    return <ChatVariable>[];
  }
  final raw = extensions[kCardVariablesExtensionKey];
  if (raw is Map<String, dynamic>) {
    return [
      for (final entry in raw.entries)
        ?ChatVariable.fromCardJson({...entry.value, 'name': entry.key}),
    ];
  }
  if (raw is List) {
    return [for (final item in raw) ?ChatVariable.fromCardJson(item)];
  }
  return <ChatVariable>[];
}
