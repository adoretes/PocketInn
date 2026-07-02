// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openai_chat_completion_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenAIChatCompletionResponse _$OpenAIChatCompletionResponseFromJson(
  Map<String, dynamic> json,
) => _OpenAIChatCompletionResponse(
  id: json['id'] as String?,
  model: json['model'] as String?,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map((e) => OpenAIResponseChoice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  usage: json['usage'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OpenAIChatCompletionResponseToJson(
  _OpenAIChatCompletionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'model': instance.model,
  'choices': instance.choices,
  'usage': instance.usage,
};

_OpenAIResponseChoice _$OpenAIResponseChoiceFromJson(
  Map<String, dynamic> json,
) => _OpenAIResponseChoice(
  index: (json['index'] as num?)?.toInt() ?? 0,
  message: json['message'] == null
      ? null
      : OpenAIResponseMessage.fromJson(json['message'] as Map<String, dynamic>),
  finishReason: json['finish_reason'] as String?,
  text: _readChoiceTextRaw(json, 'text'),
  reasoning: _readChoiceReasoningRaw(json, 'reasoning'),
);

Map<String, dynamic> _$OpenAIResponseChoiceToJson(
  _OpenAIResponseChoice instance,
) => <String, dynamic>{
  'index': instance.index,
  'message': instance.message,
  'finish_reason': instance.finishReason,
  'text': instance.text,
  'reasoning': instance.reasoning,
};

_OpenAIResponseMessage _$OpenAIResponseMessageFromJson(
  Map<String, dynamic> json,
) => _OpenAIResponseMessage(
  role: json['role'] as String? ?? 'assistant',
  content: _readContentRaw(json, 'content'),
  reasoningContent: _readReasoningRaw(json, 'reasoningContent'),
  toolCalls: json['tool_calls'] as List<dynamic>?,
);

Map<String, dynamic> _$OpenAIResponseMessageToJson(
  _OpenAIResponseMessage instance,
) => <String, dynamic>{
  'role': instance.role,
  'content': instance.content,
  'reasoningContent': instance.reasoningContent,
  'tool_calls': instance.toolCalls,
};
