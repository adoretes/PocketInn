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
    this.injectionOrder = 100,
    Map<String, dynamic>? extra,
  }) : extra = extra == null
           ? <String, dynamic>{}
           : Map<String, dynamic>.from(extra);

  final String identifier;
  String name;
  String content;
  String role;
  bool systemPrompt;
  bool marker;
  bool enabled;
  String injectionPosition;
  int injectionDepth;
  int injectionOrder;
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
      injectionOrder: _readInt(map['injection_order'], fallback: 100),
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
      'injection_order': injectionOrder,
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
      injectionOrder: injectionOrder,
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
    extra.remove('injection_order');
    return extra;
  }
}

class PresetPromptOrderEntry {
  PresetPromptOrderEntry({
    required this.identifier,
    this.enabled = true,
    Map<String, dynamic>? extra,
  }) : extra = extra == null
           ? <String, dynamic>{}
           : Map<String, dynamic>.from(extra);

  final String identifier;
  bool enabled;
  final Map<String, dynamic> extra;

  factory PresetPromptOrderEntry.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return PresetPromptOrderEntry(
      identifier: map['identifier'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? true,
      extra: _extractExtraPromptOrderEntryFields(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {...extra, 'identifier': identifier, 'enabled': enabled};
  }

  PresetPromptOrderEntry copy() {
    return PresetPromptOrderEntry(
      identifier: identifier,
      enabled: enabled,
      extra: extra,
    );
  }

  static Map<String, dynamic> _extractExtraPromptOrderEntryFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    extra.remove('identifier');
    extra.remove('enabled');
    return extra;
  }
}

class PresetPromptOrderGroup {
  PresetPromptOrderGroup({
    required this.characterId,
    required List<PresetPromptOrderEntry> order,
    Map<String, dynamic>? extra,
  }) : order = order.map((item) => item.copy()).toList(),
       extra = extra == null
           ? <String, dynamic>{}
           : Map<String, dynamic>.from(extra);

  final String characterId;
  List<PresetPromptOrderEntry> order;
  final Map<String, dynamic> extra;

  factory PresetPromptOrderGroup.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return PresetPromptOrderGroup(
      characterId: _stringifyValue(map['character_id']),
      order: (map['order'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => PresetPromptOrderEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      extra: _extractExtraPromptOrderGroupFields(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...extra,
      'character_id': _jsonFriendlyValue(characterId),
      'order': order.map((item) => item.toJson()).toList(),
    };
  }

  PresetPromptOrderGroup copy() {
    return PresetPromptOrderGroup(
      characterId: characterId,
      order: order,
      extra: extra,
    );
  }

  static Map<String, dynamic> _extractExtraPromptOrderGroupFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    extra.remove('character_id');
    extra.remove('order');
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
    List<PresetPromptOrderGroup>? promptOrderGroups,
    this.activePromptOrderCharacterId,
    Map<String, dynamic>? extra,
  }) : promptOrderGroups =
           promptOrderGroups?.map((item) => item.copy()).toList() ??
           <PresetPromptOrderGroup>[],
       extra = extra == null
           ? <String, dynamic>{}
           : Map<String, dynamic>.from(extra);

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
  List<PresetPromptOrderGroup> promptOrderGroups;
  String? activePromptOrderCharacterId;
  DateTime updatedAt;
  final Map<String, dynamic> extra;

  PresetPromptOrderGroup? get activePromptOrderGroup {
    if (promptOrderGroups.isEmpty) {
      return null;
    }
    final activeId = activePromptOrderCharacterId;
    if (activeId != null) {
      for (final group in promptOrderGroups) {
        if (group.characterId == activeId) {
          return group;
        }
      }
    }
    return promptOrderGroups.first;
  }

  factory Preset.fromStorageJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final promptOrderGroups = _parsePromptOrderGroups(map['promptOrderGroups']);
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
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      prompts: (map['prompts'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                PresetPrompt.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      promptOrderGroups: promptOrderGroups,
      activePromptOrderCharacterId: _stringifyNullableValue(
        map['activePromptOrderCharacterId'],
      ),
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
          (item) =>
              PresetPrompt.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final promptOrderGroups = _parsePromptOrderGroups(map['prompt_order']);
    final activePromptOrderGroup = _selectPromptOrderGroup(
      promptOrderGroups,
      prompts,
    );
    final orderedPrompts = _applyPromptOrder(
      prompts,
      activePromptOrderGroup?.order ?? const [],
    );

    return Preset(
      id: id,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : (fallbackName?.trim().isNotEmpty == true
                ? fallbackName!.trim()
                : 'Default'),
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
      promptOrderGroups: promptOrderGroups,
      activePromptOrderCharacterId: activePromptOrderGroup?.characterId,
      updatedAt: DateTime.now(),
      extra: _extractExtraPresetFields(map),
    );
  }

  Map<String, dynamic> toStorageJson() {
    final promptOrderGroupsSnapshot = _buildPromptOrderGroupsSnapshot();
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
      'promptOrderGroups': promptOrderGroupsSnapshot
          .map((item) => item.toJson())
          .toList(),
      'activePromptOrderCharacterId': _resolveActivePromptOrderCharacterId(
        promptOrderGroupsSnapshot,
      ),
      'extra': extra,
    };
  }

  Map<String, dynamic> toSillyTavernJson() {
    final promptOrderGroupsSnapshot = _buildPromptOrderGroupsSnapshot();
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
    result['prompt_order'] = promptOrderGroupsSnapshot
        .map((item) => item.toJson())
        .toList();
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
    List<PresetPromptOrderGroup>? promptOrderGroups,
    String? activePromptOrderCharacterId,
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
      prompts:
          prompts?.map((item) => item.copy()).toList() ??
          this.prompts.map((item) => item.copy()).toList(),
      promptOrderGroups:
          promptOrderGroups?.map((item) => item.copy()).toList() ??
          this.promptOrderGroups.map((item) => item.copy()).toList(),
      activePromptOrderCharacterId:
          activePromptOrderCharacterId ?? this.activePromptOrderCharacterId,
      updatedAt: updatedAt ?? this.updatedAt,
      extra: extra ?? this.extra,
    );
  }

  List<PresetPromptOrderGroup> _buildPromptOrderGroupsSnapshot() {
    final snapshot = promptOrderGroups.isEmpty
        ? [
            PresetPromptOrderGroup(
              characterId:
                  activePromptOrderCharacterId ?? defaultPromptOrderCharacterId,
              order: const [],
            ),
          ]
        : promptOrderGroups.map((item) => item.copy()).toList();
    final activeId = _resolveActivePromptOrderCharacterId(snapshot);
    final activeIndex = snapshot.indexWhere(
      (item) => item.characterId == activeId,
    );
    final targetIndex = activeIndex == -1 ? 0 : activeIndex;
    snapshot[targetIndex].order = prompts
        .map(
          (item) => PresetPromptOrderEntry(
            identifier: item.identifier,
            enabled: item.enabled,
          ),
        )
        .toList();
    return snapshot;
  }

  String _resolveActivePromptOrderCharacterId(
    List<PresetPromptOrderGroup> groups,
  ) {
    if (groups.isEmpty) {
      return activePromptOrderCharacterId ?? defaultPromptOrderCharacterId;
    }
    final activeId = activePromptOrderCharacterId;
    if (activeId != null &&
        groups.any((item) => item.characterId == activeId)) {
      return activeId;
    }
    return groups.first.characterId;
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
    List<PresetPromptOrderEntry> promptOrderEntries,
  ) {
    if (prompts.isEmpty) {
      return [];
    }

    final promptById = {
      for (final prompt in prompts) prompt.identifier: prompt,
    };
    final ordered = <PresetPrompt>[];
    for (final item in promptOrderEntries) {
      if (item.identifier.isEmpty) {
        continue;
      }
      final prompt = promptById.remove(item.identifier);
      if (prompt == null) {
        continue;
      }
      prompt.enabled = item.enabled;
      ordered.add(prompt);
    }

    ordered.addAll(promptById.values);
    return ordered;
  }

  static List<PresetPromptOrderGroup> _parsePromptOrderGroups(
    Object? promptOrderValue,
  ) {
    if (promptOrderValue is! List) {
      return const [];
    }

    return promptOrderValue
        .whereType<Map>()
        .map(
          (item) =>
              PresetPromptOrderGroup.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.characterId.isNotEmpty || item.order.isNotEmpty)
        .toList();
  }

  static PresetPromptOrderGroup? _selectPromptOrderGroup(
    List<PresetPromptOrderGroup> groups,
    List<PresetPrompt> prompts,
  ) {
    if (groups.isEmpty) {
      return null;
    }

    final promptIds = prompts.map((item) => item.identifier).toSet();
    var bestGroup = groups.first;
    var bestScore = _scorePromptOrderGroup(bestGroup, promptIds);
    for (final group in groups.skip(1)) {
      final score = _scorePromptOrderGroup(group, promptIds);
      if (_comparePromptOrderGroupScores(score, bestScore) > 0) {
        bestGroup = group;
        bestScore = score;
      }
    }
    return bestGroup;
  }

  static List<int> _scorePromptOrderGroup(
    PresetPromptOrderGroup group,
    Set<String> promptIds,
  ) {
    var enabledCustomCount = 0;
    var customCount = 0;
    var enabledCount = 0;
    var matchedCount = 0;

    for (final item in group.order) {
      if (!promptIds.contains(item.identifier)) {
        continue;
      }
      matchedCount += 1;
      if (item.enabled) {
        enabledCount += 1;
      }
      if (!defaultPromptIdentifiers.contains(item.identifier)) {
        customCount += 1;
        if (item.enabled) {
          enabledCustomCount += 1;
        }
      }
    }

    return [
      enabledCustomCount,
      customCount,
      enabledCount,
      matchedCount,
      group.order.length,
    ];
  }

  static int _comparePromptOrderGroupScores(List<int> left, List<int> right) {
    final length = left.length < right.length ? left.length : right.length;
    for (var i = 0; i < length; i += 1) {
      final comparison = left[i].compareTo(right[i]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return left.length.compareTo(right.length);
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
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
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
  'longTermMemory',
  'chatHistory',
  'worldInfoAfter',
  'worldInfoBefore',
  'enhanceDefinitions',
  'charDescription',
  'charPersonality',
  'scenario',
  'personaDescription',
];

const String defaultPromptOrderCharacterId = '100000';

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

String _stringifyValue(Object? value) {
  return value?.toString() ?? '';
}

String? _stringifyNullableValue(Object? value) {
  if (value == null) {
    return null;
  }
  final stringValue = value.toString();
  return stringValue.isEmpty ? null : stringValue;
}

Object _jsonFriendlyValue(String value) {
  return int.tryParse(value) ?? value;
}
