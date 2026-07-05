// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiModel _$ApiModelFromJson(Map<String, dynamic> json) => _ApiModel(
  id: json['id'] as String? ?? '',
  modelId: json['modelId'] as String? ?? '',
  customBody: json['customBody'] as String? ?? '',
);

Map<String, dynamic> _$ApiModelToJson(_ApiModel instance) => <String, dynamic>{
  'id': instance.id,
  'modelId': instance.modelId,
  'customBody': instance.customBody,
};

_ApiConfig _$ApiConfigFromJson(Map<String, dynamic> json) => _ApiConfig(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '未命名配置',
  baseUrl: json['baseUrl'] as String? ?? '',
  apiKey: json['apiKey'] as String? ?? '',
  models:
      (json['models'] as List<dynamic>?)
          ?.map((e) => ApiModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$ApiConfigToJson(_ApiConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'baseUrl': instance.baseUrl,
      'apiKey': instance.apiKey,
      'models': instance.models,
    };

_ResolvedApiConfig _$ResolvedApiConfigFromJson(Map<String, dynamic> json) =>
    _ResolvedApiConfig(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名配置',
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      customBody: json['customBody'] as String? ?? '',
    );

Map<String, dynamic> _$ResolvedApiConfigToJson(_ResolvedApiConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'baseUrl': instance.baseUrl,
      'apiKey': instance.apiKey,
      'model': instance.model,
      'customBody': instance.customBody,
    };
