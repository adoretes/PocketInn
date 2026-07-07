import 'package:freezed_annotation/freezed_annotation.dart';

import 'openai_response_utils.dart';

part 'openai_chat_completion_response.freezed.dart';
part 'openai_chat_completion_response.g.dart';

/// 从 OpenAI 兼容接口的非流式响应中读取 `content` 原始值。
Object? _readContentRaw(Map json, String _) {
  for (final key in const ['content', 'text', 'refusal']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

/// 从 `message` 与 `choice` 之外读取推理链原始值。
Object? _readReasoningRaw(Map json, String _) {
  for (final key in const [
    'reasoning_content',
    'reasoning',
    'thinking',
    'reasoning_text',
  ]) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

@freezed
abstract class OpenAIChatCompletionResponse
    with _$OpenAIChatCompletionResponse {
  const factory OpenAIChatCompletionResponse({
    String? id,
    String? model,
    @Default([]) List<OpenAIResponseChoice> choices,
    Map<String, dynamic>? usage,
  }) = _OpenAIChatCompletionResponse;

  factory OpenAIChatCompletionResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChatCompletionResponseFromJson(json);
}

@freezed
abstract class OpenAIResponseChoice with _$OpenAIResponseChoice {
  const OpenAIResponseChoice._();

  const factory OpenAIResponseChoice({
    @Default(0) int index,
    OpenAIResponseMessage? message,
    @JsonKey(name: 'finish_reason') String? finishReason,
    @JsonKey(readValue: readChoiceTextRaw) Object? text,
    @JsonKey(readValue: readChoiceReasoningRaw) Object? reasoning,
  }) = _OpenAIResponseChoice;

  factory OpenAIResponseChoice.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseChoiceFromJson(json);

  /// 该 choice 的最终文本回复（兼容 message.content 与 choice.text）。
  String get resolvedText {
    final fromMessage = message?.contentText ?? '';
    if (fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return extractStructuredText(text);
  }

  /// 该 choice 的推理链文本。
  String get resolvedReasoning {
    final fromMessage = message?.reasoningText ?? '';
    if (fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return extractStructuredText(reasoning);
  }
}

@freezed
abstract class OpenAIResponseMessage with _$OpenAIResponseMessage {
  const OpenAIResponseMessage._();

  const factory OpenAIResponseMessage({
    @Default('assistant') String role,
    @JsonKey(readValue: _readContentRaw) Object? content,
    @JsonKey(readValue: _readReasoningRaw) Object? reasoningContent,
    @JsonKey(name: 'tool_calls') List<dynamic>? toolCalls,
  }) = _OpenAIResponseMessage;

  factory OpenAIResponseMessage.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseMessageFromJson(json);

  /// 将 [content] 归一化为纯文本。
  String get contentText => extractStructuredText(content);

  /// 将 [reasoningContent] 归一化为纯文本。
  String get reasoningText => extractStructuredText(reasoningContent);
}
