// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openai_models_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenAIModelsResponse _$OpenAIModelsResponseFromJson(
  Map<String, dynamic> json,
) => _OpenAIModelsResponse(
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => OpenAIModelInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$OpenAIModelsResponseToJson(
  _OpenAIModelsResponse instance,
) => <String, dynamic>{'data': instance.data};

_OpenAIModelInfo _$OpenAIModelInfoFromJson(Map<String, dynamic> json) =>
    _OpenAIModelInfo(
      id: json['id'] as String,
      object: json['object'] as String?,
      ownedBy: json['owned_by'] as String?,
    );

Map<String, dynamic> _$OpenAIModelInfoToJson(_OpenAIModelInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'owned_by': instance.ownedBy,
    };
