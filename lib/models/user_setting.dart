import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_setting.freezed.dart';
part 'user_setting.g.dart';

/// 用户设定数据模型
@freezed
abstract class UserSetting with _$UserSetting {
  const UserSetting._();

  const factory UserSetting({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String name,
    @JsonKey(defaultValue: '') required String prompt,
    @JsonKey(defaultValue: 0xFF5C6BC0) required int colorValue,
  }) = _UserSetting;

  factory UserSetting.fromJson(Map<String, dynamic> json) =>
      _$UserSettingFromJson(json);

  /// 获取 Color 对象
  Color get color => Color(colorValue);

  /// 获取头像文字（名字首字）
  String get avatarText => name.isNotEmpty ? name[0] : '';

  /// 使用 Color 复制并修改
  UserSetting copyWithColor(Color color) => copyWith(colorValue: color.toARGB32());
}

/// 默认用户设定数据
const List<UserSetting> defaultUserSettings = [
  UserSetting(
    id: 'user-setting-default',
    name: '默认用户',
    prompt: '',
    colorValue: 0xFF5C6BC0,
  ),
];
