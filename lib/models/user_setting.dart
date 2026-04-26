import 'package:flutter/material.dart';

/// 用户设定数据模型
class UserSetting {
  const UserSetting({
    required this.id,
    required this.name,
    required this.prompt,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String prompt;
  final int colorValue;

  /// 获取 Color 对象
  Color get color => Color(colorValue);

  /// 获取头像文字（名字首字）
  String get avatarText => name.isNotEmpty ? name[0] : '';

  /// 从 JSON 创建
  factory UserSetting.fromJson(Map<String, dynamic> json) {
    return UserSetting(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF5C6BC0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'colorValue': colorValue,
    };
  }

  /// 复制并修改
  UserSetting copyWith({
    String? id,
    String? name,
    String? prompt,
    int? colorValue,
    Color? color,
  }) {
    final resolvedColorValue = colorValue ?? (color != null ? color.toARGB32() : this.colorValue);
    return UserSetting(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      colorValue: resolvedColorValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSetting && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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
