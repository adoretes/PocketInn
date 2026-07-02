import 'package:freezed_annotation/freezed_annotation.dart';

part 'openai_chat_completion_response.freezed.dart';
part 'openai_chat_completion_response.g.dart';

/// 从 OpenAI 兼容接口的非流式响应中读取 `content` 原始值。
///
/// OpenAI 官方与各类兼容网关常在 `message.content` 上返回字符串、
/// 结构化数组或对象，这里仅按字段名提取原始值，文本归一化由
/// [ResponseMessage.contentText] 处理。
Object? _readContentRaw(Map json, String _) {
  for (final key in const ['content', 'text', 'refusal']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

/// 从 `message` 与 `choice` 之外读取推理链原始值。
///
/// 兼容 `reasoning_content` / `reasoning` / `thinking` / `reasoning_text`
/// 等不同网关字段命名。
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

/// 从 `choice` 上读取文本候选字段（部分网关不返回 `message`）。
Object? _readChoiceTextRaw(Map json, String _) {
  for (final key in const ['text', 'content']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

/// 从 `choice` 上读取推理链候选字段。
Object? _readChoiceReasoningRaw(Map json, String _) {
  for (final key in const ['reasoning_content', 'reasoning', 'thinking']) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

String _extractStructuredText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  if (value is List) {
    final buffer = <String>[];
    for (final item in value) {
      final text = _extractStructuredText(item).trim();
      if (text.isNotEmpty) {
        buffer.add(text);
      }
    }
    return buffer.join('\n');
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in const ['text', 'content', 'value', 'output_text']) {
      final text = _extractStructuredText(map[key]).trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  return '';
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
    @JsonKey(readValue: _readChoiceTextRaw) Object? text,
    @JsonKey(readValue: _readChoiceReasoningRaw) Object? reasoning,
  }) = _OpenAIResponseChoice;

  factory OpenAIResponseChoice.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseChoiceFromJson(json);

  /// 该 choice 的最终文本回复（兼容 message.content 与 choice.text）。
  String get resolvedText {
    final fromMessage = message?.contentText ?? '';
    if (fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return _extractStructuredText(text);
  }

  /// 该 choice 的推理链文本。
  String get resolvedReasoning {
    final fromMessage = message?.reasoningText ?? '';
    if (fromMessage.isNotEmpty) {
      return fromMessage;
    }
    return _extractStructuredText(reasoning);
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
  String get contentText => _extractStructuredText(content);

  /// 将 [reasoningContent] 归一化为纯文本。
  String get reasoningText => _extractStructuredText(reasoningContent);
}
