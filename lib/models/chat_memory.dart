import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_memory.freezed.dart';

@freezed
abstract class MemoryNode with _$MemoryNode {
  const factory MemoryNode({
    required String id,
    required String sessionId,
    required String branchLeafId,
    required String content,
    @Default([]) List<String> sourceMessageIds,
    @Default(false) bool isUserEdited,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoryNode;
}

@freezed
abstract class MemoryExtractionConfig with _$MemoryExtractionConfig {
  const MemoryExtractionConfig._();

  const factory MemoryExtractionConfig({
    @Default(false) bool enabled,
    @Default(5) int interval,
    @Default(10) int recentRounds,
    @Default(3) int recallCount,
    String? extractionModelId,
    @Default('') String customExtractionPrompt,
    @Default('') String customInjectionPrompt,
  }) = _MemoryExtractionConfig;

  bool get hasCustomExtractionPrompt =>
      customExtractionPrompt.trim().isNotEmpty;

  bool get hasCustomInjectionPrompt => customInjectionPrompt.trim().isNotEmpty;
}
