import 'dart:convert';

class PresetPrompt {
  PresetPrompt({
    required this.identifier,
    required this.name,
    this.content = '',
    this.role = 'system',
    this.systemPrompt = true,
    this.marker = false,
    this.enabled = true,
    this.injectionPosition = PresetInjectionPosition.relative,
    this.injectionDepth = 4,
    Map<String, dynamic>? extra,
  }) : extra = extra == null ? <String, dynamic>{} : Map<String, dynamic>.from(extra);

  final String identifier;
  String name;
  String content;
  String role;
  bool systemPrompt;
  bool marker;
  bool enabled;
  String injectionPosition;
  int injectionDepth;
  final Map<String, dynamic> extra;

  bool get isDefault => defaultPromptIdentifiers.contains(identifier);

  factory PresetPrompt.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return PresetPrompt(
      identifier: map['identifier'] as String? ?? '',
      name: map['name'] as String? ?? '',
      content: map['content'] as String? ?? '',
      role: map['role'] as String? ?? 'system',
      systemPrompt: map['system_prompt'] as bool? ?? true,
      marker: map['marker'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? true,
      injectionPosition: _decodeInjectionPosition(map['injection_position']),
      injectionDepth: _readInt(map['injection_depth'], fallback: 4),
      extra: _extractExtraPromptFields(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...extra,
      'identifier': identifier,
      'name': name,
      'content': content,
      'role': role,
      'system_prompt': systemPrompt,
      'marker': marker,
      'enabled': enabled,
      'injection_position': _encodeInjectionPosition(injectionPosition),
      'injection_depth': injectionDepth,
    };
  }

  PresetPrompt copy() {
    return PresetPrompt(
      identifier: identifier,
      name: name,
      content: content,
      role: role,
      systemPrompt: systemPrompt,
      marker: marker,
      enabled: enabled,
      injectionPosition: injectionPosition,
      injectionDepth: injectionDepth,
      extra: extra,
    );
  }

  static Map<String, dynamic> _extractExtraPromptFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    extra.remove('identifier');
    extra.remove('name');
    extra.remove('content');
    extra.remove('role');
    extra.remove('system_prompt');
    extra.remove('marker');
    extra.remove('enabled');
    extra.remove('injection_position');
    extra.remove('injection_depth');
    return extra;
  }
}

class Preset {
  Preset({
    required this.id,
    required this.name,
    required this.prompts,
    required this.updatedAt,
    this.isBuiltin = false,
    this.temperature = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.topP = 1.0,
    this.topK = 0,
    this.topA = 0.0,
    this.minP = 0.0,
    this.repetitionPenalty = 1.0,
    this.openaiMaxContext = 4095,
    this.openaiMaxTokens = 300,
    Map<String, dynamic>? extra,
  }) : extra = extra == null ? <String, dynamic>{} : Map<String, dynamic>.from(extra);

  final String id;
  String name;
  bool isBuiltin;
  double temperature;
  double frequencyPenalty;
  double presencePenalty;
  double topP;
  int topK;
  double topA;
  double minP;
  double repetitionPenalty;
  int openaiMaxContext;
  int openaiMaxTokens;
  List<PresetPrompt> prompts;
  DateTime updatedAt;
  final Map<String, dynamic> extra;

  factory Preset.fromStorageJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return Preset(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名预设',
      isBuiltin: map['isBuiltin'] as bool? ?? false,
      temperature: (map['temperature'] as num? ?? 1.0).toDouble(),
      frequencyPenalty: (map['frequencyPenalty'] as num? ?? 0.0).toDouble(),
      presencePenalty: (map['presencePenalty'] as num? ?? 0.0).toDouble(),
      topP: (map['topP'] as num? ?? 1.0).toDouble(),
      topK: _readInt(map['topK']),
      topA: (map['topA'] as num? ?? 0.0).toDouble(),
      minP: (map['minP'] as num? ?? 0.0).toDouble(),
      repetitionPenalty: (map['repetitionPenalty'] as num? ?? 1.0).toDouble(),
      openaiMaxContext: _readInt(map['openaiMaxContext'], fallback: 4095),
      openaiMaxTokens: _readInt(map['openaiMaxTokens'], fallback: 300),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      prompts: (map['prompts'] as List<dynamic>? ?? const [])
          .map(
            (item) => PresetPrompt.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      extra: map['extra'] is Map
          ? Map<String, dynamic>.from(map['extra'] as Map)
          : <String, dynamic>{},
    );
  }

  factory Preset.fromSillyTavernJson(
    Map<String, dynamic> json, {
    required String id,
    String? fallbackName,
    bool isBuiltin = false,
  }) {
    final map = Map<String, dynamic>.from(json);
    final prompts = (map['prompts'] as List<dynamic>? ?? const [])
        .map(
          (item) => PresetPrompt.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final orderedPrompts = _applyPromptOrder(prompts, map['prompt_order']);

    return Preset(
      id: id,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : (fallbackName?.trim().isNotEmpty == true ? fallbackName!.trim() : 'Default'),
      isBuiltin: isBuiltin,
      temperature: (map['temperature'] as num? ?? 1.0).toDouble(),
      frequencyPenalty: (map['frequency_penalty'] as num? ?? 0.0).toDouble(),
      presencePenalty: (map['presence_penalty'] as num? ?? 0.0).toDouble(),
      topP: (map['top_p'] as num? ?? 1.0).toDouble(),
      topK: _readInt(map['top_k']),
      topA: (map['top_a'] as num? ?? 0.0).toDouble(),
      minP: (map['min_p'] as num? ?? 0.0).toDouble(),
      repetitionPenalty: (map['repetition_penalty'] as num? ?? 1.0).toDouble(),
      openaiMaxContext: _readInt(map['openai_max_context'], fallback: 4095),
      openaiMaxTokens: _readInt(map['openai_max_tokens'], fallback: 300),
      prompts: orderedPrompts,
      updatedAt: DateTime.now(),
      extra: _extractExtraPresetFields(map),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'name': name,
      'isBuiltin': isBuiltin,
      'temperature': temperature,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'topP': topP,
      'topK': topK,
      'topA': topA,
      'minP': minP,
      'repetitionPenalty': repetitionPenalty,
      'openaiMaxContext': openaiMaxContext,
      'openaiMaxTokens': openaiMaxTokens,
      'updatedAt': updatedAt.toIso8601String(),
      'prompts': prompts.map((item) => item.toJson()).toList(),
      'extra': extra,
    };
  }

  Map<String, dynamic> toSillyTavernJson() {
    final result = Map<String, dynamic>.from(extra);
    result['name'] = name;
    result['temperature'] = temperature;
    result['frequency_penalty'] = frequencyPenalty;
    result['presence_penalty'] = presencePenalty;
    result['top_p'] = topP;
    result['top_k'] = topK;
    result['top_a'] = topA;
    result['min_p'] = minP;
    result['repetition_penalty'] = repetitionPenalty;
    result['openai_max_context'] = openaiMaxContext;
    result['openai_max_tokens'] = openaiMaxTokens;
    result['prompts'] = prompts.map((item) => item.toJson()).toList();
    result['prompt_order'] = [
      {
        'character_id': 100001,
        'order': prompts
            .map(
              (item) => {
                'identifier': item.identifier,
                'enabled': item.enabled,
              },
            )
            .toList(),
      },
    ];
    return result;
  }

  String exportJsonString() {
    return const JsonEncoder.withIndent('    ').convert(toSillyTavernJson());
  }

  static bool looksLikePresetJson(Map<String, dynamic> json) {
    final prompts = json['prompts'];
    if (prompts is! List || prompts.isEmpty) {
      return false;
    }

    final hasRecognizedTopLevelKey =
        json.containsKey('prompt_order') ||
        json.containsKey('temperature') ||
        json.containsKey('openai_max_context') ||
        json.containsKey('openai_max_tokens') ||
        json.containsKey('top_p') ||
        json.containsKey('top_k');
    if (!hasRecognizedTopLevelKey) {
      return false;
    }

    final validPromptCount = prompts.whereType<Map>().where((item) {
      final map = Map<String, dynamic>.from(item);
      final identifier = map['identifier'];
      final name = map['name'];
      final role = map['role'];
      return identifier is String &&
          identifier.trim().isNotEmpty &&
          name is String &&
          name.trim().isNotEmpty &&
          role is String &&
          role.trim().isNotEmpty;
    }).length;

    return validPromptCount > 0;
  }

  Preset copyWith({
    String? id,
    String? name,
    bool? isBuiltin,
    double? temperature,
    double? frequencyPenalty,
    double? presencePenalty,
    double? topP,
    int? topK,
    double? topA,
    double? minP,
    double? repetitionPenalty,
    int? openaiMaxContext,
    int? openaiMaxTokens,
    List<PresetPrompt>? prompts,
    DateTime? updatedAt,
    Map<String, dynamic>? extra,
  }) {
    return Preset(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      temperature: temperature ?? this.temperature,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      topA: topA ?? this.topA,
      minP: minP ?? this.minP,
      repetitionPenalty: repetitionPenalty ?? this.repetitionPenalty,
      openaiMaxContext: openaiMaxContext ?? this.openaiMaxContext,
      openaiMaxTokens: openaiMaxTokens ?? this.openaiMaxTokens,
      prompts: prompts?.map((item) => item.copy()).toList() ??
          this.prompts.map((item) => item.copy()).toList(),
      updatedAt: updatedAt ?? this.updatedAt,
      extra: extra ?? this.extra,
    );
  }

  static Map<String, dynamic> _extractExtraPresetFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    const managedKeys = {
      'name',
      'temperature',
      'frequency_penalty',
      'presence_penalty',
      'top_p',
      'top_k',
      'top_a',
      'min_p',
      'repetition_penalty',
      'openai_max_context',
      'openai_max_tokens',
      'prompts',
      'prompt_order',
    };
    extra.removeWhere((key, _) => managedKeys.contains(key));
    return extra;
  }

  static List<PresetPrompt> _applyPromptOrder(
    List<PresetPrompt> prompts,
    Object? promptOrderValue,
  ) {
    if (prompts.isEmpty) {
      return [];
    }

    final promptById = {
      for (final prompt in prompts) prompt.identifier: prompt,
    };
    final ordered = <PresetPrompt>[];
    final orderItems = <Map<String, dynamic>>[];
    if (promptOrderValue is List && promptOrderValue.isNotEmpty) {
      final first = promptOrderValue.first;
      if (first is Map && first['order'] is List) {
        for (final item in first['order'] as List) {
          if (item is Map) {
            orderItems.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    for (final item in orderItems) {
      final identifier = item['identifier'] as String?;
      if (identifier == null) {
        continue;
      }
      final prompt = promptById.remove(identifier);
      if (prompt == null) {
        continue;
      }
      prompt.enabled = item['enabled'] as bool? ?? prompt.enabled;
      ordered.add(prompt);
    }

    ordered.addAll(promptById.values);
    return ordered;
  }
}

class PresetSummary {
  const PresetSummary({
    required this.id,
    required this.name,
    required this.isBuiltin,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isBuiltin;
  final DateTime updatedAt;

  factory PresetSummary.fromJson(Map<String, dynamic> json) {
    return PresetSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名预设',
      isBuiltin: json['isBuiltin'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isBuiltin': isBuiltin,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

abstract final class PresetInjectionPosition {
  static const String relative = 'relative';
  static const String inChat = 'inChat';
}

const List<String> defaultPromptIdentifiers = [
  'main',
  'nsfw',
  'dialogueExamples',
  'jailbreak',
  'chatHistory',
  'worldInfoAfter',
  'worldInfoBefore',
  'enhanceDefinitions',
  'charDescription',
  'charPersonality',
  'scenario',
  'personaDescription',
];

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

String _decodeInjectionPosition(Object? value) {
  if (value is String) {
    return value == PresetInjectionPosition.inChat
        ? PresetInjectionPosition.inChat
        : PresetInjectionPosition.relative;
  }
  if (value is int) {
    return value == 1
        ? PresetInjectionPosition.inChat
        : PresetInjectionPosition.relative;
  }
  return PresetInjectionPosition.relative;
}

int _encodeInjectionPosition(String value) {
  return value == PresetInjectionPosition.inChat ? 1 : 0;
}
