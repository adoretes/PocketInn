// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSetting _$UserSettingFromJson(Map<String, dynamic> json) => _UserSetting(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  prompt: json['prompt'] as String? ?? '',
  colorValue: (json['colorValue'] as num?)?.toInt() ?? 4284246976,
);

Map<String, dynamic> _$UserSettingToJson(_UserSetting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prompt': instance.prompt,
      'colorValue': instance.colorValue,
    };
