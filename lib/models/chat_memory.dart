class MemoryNode {
  final String id;
  final String sessionId;
  final String branchLeafId;
  final String content;
  final List<String> sourceMessageIds;
  final bool isUserEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryNode({
    required this.id,
    required this.sessionId,
    required this.branchLeafId,
    required this.content,
    this.sourceMessageIds = const [],
    this.isUserEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });
}

class MemoryExtractionConfig {
  final bool enabled;
  final int interval;
  final int recentRounds;
  final int recallCount;
  final String? extractionModelId;
  final String customExtractionPrompt;
  final String customInjectionPrompt;

  const MemoryExtractionConfig({
    this.enabled = false,
    this.interval = 5,
    this.recentRounds = 10,
    this.recallCount = 3,
    this.extractionModelId,
    this.customExtractionPrompt = '',
    this.customInjectionPrompt = '',
  });

  bool get hasCustomExtractionPrompt =>
      customExtractionPrompt.trim().isNotEmpty;

  bool get hasCustomInjectionPrompt =>
      customInjectionPrompt.trim().isNotEmpty;

  MemoryExtractionConfig copyWith({
    bool? enabled,
    int? interval,
    int? recentRounds,
    int? recallCount,
    Object? extractionModelId,
    bool clearExtractionModel = false,
    Object? customExtractionPrompt,
    bool clearCustomExtractionPrompt = false,
    Object? customInjectionPrompt,
    bool clearCustomInjectionPrompt = false,
  }) {
    return MemoryExtractionConfig(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      recentRounds: recentRounds ?? this.recentRounds,
      recallCount: recallCount ?? this.recallCount,
      extractionModelId: clearExtractionModel
          ? null
          : (extractionModelId == _unset
              ? this.extractionModelId
              : extractionModelId as String?),
      customExtractionPrompt: clearCustomExtractionPrompt
          ? ''
          : (customExtractionPrompt == _unset
              ? this.customExtractionPrompt
              : (customExtractionPrompt as String?) ?? this.customExtractionPrompt),
      customInjectionPrompt: clearCustomInjectionPrompt
          ? ''
          : (customInjectionPrompt == _unset
              ? this.customInjectionPrompt
              : (customInjectionPrompt as String?) ?? this.customInjectionPrompt),
    );
  }
}

const Object _unset = Object();
