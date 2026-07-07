import 'package:freezed_annotation/freezed_annotation.dart';

import 'openai_response_utils.dart';

part 'openai_chat_completion_chunk.freezed.dart';
part 'openai_chat_completion_chunk.g.dart';

/// 从流式 chunk 的 `delta` 中读取文本候选字段原始值。
Object? _readDeltaContentRaw(Map json, String _) {
  for (final key in const ['content', 'text']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

/// 从流式 chunk 的 `delta` 中读取推理链候选字段原始值。
Object? _readDeltaReasoningRaw(Map json, String _) {
  for (final key in const ['reasoning_content', 'reasoning', 'thinking']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

/// OpenAI 兼容接口流式响应的单个 SSE chunk。
@freezed
abstract class OpenAIChatCompletionChunk with _$OpenAIChatCompletionChunk {
  const factory OpenAIChatCompletionChunk({
    String? id,
    String? model,
    @Default([]) List<OpenAIChunkChoice> choices,
  }) = _OpenAIChatCompletionChunk;

  factory OpenAIChatCompletionChunk.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChatCompletionChunkFromJson(json);
}

@freezed
abstract class OpenAIChunkChoice with _$OpenAIChunkChoice {
  const OpenAIChunkChoice._();

  const factory OpenAIChunkChoice({
    @Default(0) int index,
    OpenAIChunkDelta? delta,
    @JsonKey(name: 'finish_reason') String? finishReason,
    @JsonKey(readValue: readChoiceTextRaw) Object? text,
    @JsonKey(readValue: readChoiceReasoningRaw) Object? reasoning,
  }) = _OpenAIChunkChoice;

  factory OpenAIChunkChoice.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChunkChoiceFromJson(json);

  /// 该 chunk 的文本增量。
  String get textDelta {
    final fromDelta = delta?.contentText ?? '';
    if (fromDelta.isNotEmpty) {
      return fromDelta;
    }
    return extractStructuredText(text);
  }

  /// 该 chunk 的推理链增量。
  String get reasoningDelta {
    final fromDelta = delta?.reasoningText ?? '';
    if (fromDelta.isNotEmpty) {
      return fromDelta;
    }
    return extractStructuredText(reasoning);
  }

  /// 是否携带了流结束标志。
  bool get isDone => finishReason != null;
}

@freezed
abstract class OpenAIChunkDelta with _$OpenAIChunkDelta {
  const OpenAIChunkDelta._();

  const factory OpenAIChunkDelta({
    String? role,
    @JsonKey(readValue: _readDeltaContentRaw) Object? content,
    @JsonKey(readValue: _readDeltaReasoningRaw) Object? reasoningContent,
  }) = _OpenAIChunkDelta;

  factory OpenAIChunkDelta.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChunkDeltaFromJson(json);

  String get contentText => extractStructuredText(content);

  String get reasoningText => extractStructuredText(reasoningContent);
}
