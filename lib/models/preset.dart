import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'preset.freezed.dart';

// ignore_for_file: invalid_annotation_target

@freezed
abstract class PresetPrompt with _$PresetPrompt {
  const PresetPrompt._();

  const factory PresetPrompt({
    required String identifier,
    required String name,
    @Default('') String content,
    @Default('system') String role,
    @Default(true) bool systemPrompt,
    @Default(false) bool marker,
    @Default(true) bool enabled,
    @Default(PresetInjectionPosition.relative) String injectionPosition,
    @Default(4) int injectionDepth,
    @Default(100) int injectionOrder,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default({})
    Map<String, dynamic> extra,
  }) = _PresetPrompt;

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

  bool get isDefault => defaultPromptIdentifiers.contains(identifier);

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

@freezed
abstract class PresetPromptOrderEntry with _$PresetPromptOrderEntry {
  const PresetPromptOrderEntry._();

  const factory PresetPromptOrderEntry({
    required String identifier,
    @Default(true) bool enabled,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default({})
    Map<String, dynamic> extra,
  }) = _PresetPromptOrderEntry;

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

  static Map<String, dynamic> _extractExtraPromptOrderEntryFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    extra.remove('identifier');
    extra.remove('enabled');
    return extra;
  }
}

@freezed
abstract class PresetPromptOrderGroup with _$PresetPromptOrderGroup {
  const PresetPromptOrderGroup._();

  const factory PresetPromptOrderGroup({
    required String characterId,
    @Default([]) List<PresetPromptOrderEntry> order,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default({})
    Map<String, dynamic> extra,
  }) = _PresetPromptOrderGroup;

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

  static Map<String, dynamic> _extractExtraPromptOrderGroupFields(
    Map<String, dynamic> map,
  ) {
    final extra = Map<String, dynamic>.from(map);
    extra.remove('character_id');
    extra.remove('order');
    return extra;
  }
}

@freezed
abstract class Preset with _$Preset {
  const Preset._();

  const factory Preset({
    required String id,
    required String name,
    @Default(false) bool isBuiltin,
    double? temperature,
    @Default(0.0) double frequencyPenalty,
    @Default(0.0) double presencePenalty,
    @Default(1.0) double topP,
    @Default(0) int topK,
    @Default(0.0) double topA,
    @Default(0.0) double minP,
    @Default(1.0) double repetitionPenalty,
    @Default(131072) int openaiMaxContext,
    @Default(32768) int openaiMaxTokens,
    @Default([]) List<PresetPrompt> prompts,
    @Default([]) List<PresetPromptOrderGroup> promptOrderGroups,
    String? activePromptOrderCharacterId,
    required DateTime updatedAt,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default({})
    Map<String, dynamic> extra,
  }) = _Preset;

  factory Preset.fromStorageJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final promptOrderGroups = _parsePromptOrderGroups(map['promptOrderGroups']);
    return Preset(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名预设',
      isBuiltin: map['isBuiltin'] as bool? ?? false,
      temperature: (map['temperature'] as num?)?.toDouble(),
      frequencyPenalty: (map['frequencyPenalty'] as num? ?? 0.0).toDouble(),
      presencePenalty: (map['presencePenalty'] as num? ?? 0.0).toDouble(),
      topP: (map['topP'] as num? ?? 1.0).toDouble(),
      topK: _readInt(map['topK']),
      topA: (map['topA'] as num? ?? 0.0).toDouble(),
      minP: (map['minP'] as num? ?? 0.0).toDouble(),
      repetitionPenalty: (map['repetitionPenalty'] as num? ?? 1.0).toDouble(),
      openaiMaxContext: _readInt(map['openaiMaxContext'], fallback: 131072),
      openaiMaxTokens: _readInt(map['openaiMaxTokens'], fallback: 32768),
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
      temperature: (map['temperature'] as num?)?.toDouble(),
      frequencyPenalty: (map['frequency_penalty'] as num? ?? 0.0).toDouble(),
      presencePenalty: (map['presence_penalty'] as num? ?? 0.0).toDouble(),
      topP: (map['top_p'] as num? ?? 1.0).toDouble(),
      topK: _readInt(map['top_k']),
      topA: (map['top_a'] as num? ?? 0.0).toDouble(),
      minP: (map['min_p'] as num? ?? 0.0).toDouble(),
      repetitionPenalty: (map['repetition_penalty'] as num? ?? 1.0).toDouble(),
      openaiMaxContext: _readInt(map['openai_max_context'], fallback: 131072),
      openaiMaxTokens: _readInt(map['openai_max_tokens'], fallback: 32768),
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

  List<PresetPromptOrderGroup> _buildPromptOrderGroupsSnapshot() {
    final snapshot = promptOrderGroups.isEmpty
        ? <PresetPromptOrderGroup>[
            PresetPromptOrderGroup(
              characterId:
                  activePromptOrderCharacterId ?? defaultPromptOrderCharacterId,
              order: const [],
            ),
          ]
        : [...promptOrderGroups];
    final activeId = _resolveActivePromptOrderCharacterId(snapshot);
    final activeIndex = snapshot.indexWhere(
      (item) => item.characterId == activeId,
    );
    final targetIndex = activeIndex == -1 ? 0 : activeIndex;
    final newOrder = prompts
        .map(
          (item) => PresetPromptOrderEntry(
            identifier: item.identifier,
            enabled: item.enabled,
          ),
        )
        .toList();
    snapshot[targetIndex] = snapshot[targetIndex].copyWith(order: newOrder);
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
      ordered.add(prompt.copyWith(enabled: item.enabled));
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

@freezed
abstract class PresetSummary with _$PresetSummary {
  const PresetSummary._();

  const factory PresetSummary({
    required String id,
    required String name,
    required bool isBuiltin,
    required DateTime updatedAt,
  }) = _PresetSummary;

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
