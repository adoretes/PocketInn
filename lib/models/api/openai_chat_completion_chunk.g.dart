// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openai_chat_completion_chunk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenAIChatCompletionChunk _$OpenAIChatCompletionChunkFromJson(
  Map<String, dynamic> json,
) => _OpenAIChatCompletionChunk(
  id: json['id'] as String?,
  model: json['model'] as String?,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map((e) => OpenAIChunkChoice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$OpenAIChatCompletionChunkToJson(
  _OpenAIChatCompletionChunk instance,
) => <String, dynamic>{
  'id': instance.id,
  'model': instance.model,
  'choices': instance.choices,
};

_OpenAIChunkChoice _$OpenAIChunkChoiceFromJson(Map<String, dynamic> json) =>
    _OpenAIChunkChoice(
      index: (json['index'] as num?)?.toInt() ?? 0,
      delta: json['delta'] == null
          ? null
          : OpenAIChunkDelta.fromJson(json['delta'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
      text: _readChoiceTextRaw(json, 'text'),
      reasoning: _readChoiceReasoningRaw(json, 'reasoning'),
    );

Map<String, dynamic> _$OpenAIChunkChoiceToJson(_OpenAIChunkChoice instance) =>
    <String, dynamic>{
      'index': instance.index,
      'delta': instance.delta,
      'finish_reason': instance.finishReason,
      'text': instance.text,
      'reasoning': instance.reasoning,
    };

_OpenAIChunkDelta _$OpenAIChunkDeltaFromJson(Map<String, dynamic> json) =>
    _OpenAIChunkDelta(
      role: json['role'] as String?,
      content: _readDeltaContentRaw(json, 'content'),
      reasoningContent: _readDeltaReasoningRaw(json, 'reasoningContent'),
    );

Map<String, dynamic> _$OpenAIChunkDeltaToJson(_OpenAIChunkDelta instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'reasoningContent': instance.reasoningContent,
    };
