// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiConfig _$ApiConfigFromJson(Map<String, dynamic> json) => _ApiConfig(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '未命名配置',
  baseUrl: json['baseUrl'] as String? ?? '',
  apiKey: json['apiKey'] as String? ?? '',
  model: json['model'] as String? ?? '',
  customBody: json['customBody'] as String? ?? '',
  enabled: json['enabled'] as bool? ?? false,
);

Map<String, dynamic> _$ApiConfigToJson(_ApiConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'baseUrl': instance.baseUrl,
      'apiKey': instance.apiKey,
      'model': instance.model,
      'customBody': instance.customBody,
      'enabled': instance.enabled,
    };
