// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSetting {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: '') String get prompt;@JsonKey(defaultValue: 0xFF5C6BC0) int get colorValue;
/// Create a copy of UserSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingCopyWith<UserSetting> get copyWith => _$UserSettingCopyWithImpl<UserSetting>(this as UserSetting, _$identity);

  /// Serializes this UserSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,prompt,colorValue);

@override
String toString() {
  return 'UserSetting(id: $id, name: $name, prompt: $prompt, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $UserSettingCopyWith<$Res>  {
  factory $UserSettingCopyWith(UserSetting value, $Res Function(UserSetting) _then) = _$UserSettingCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String prompt,@JsonKey(defaultValue: 0xFF5C6BC0) int colorValue
});




}
/// @nodoc
class _$UserSettingCopyWithImpl<$Res>
    implements $UserSettingCopyWith<$Res> {
  _$UserSettingCopyWithImpl(this._self, this._then);

  final UserSetting _self;
  final $Res Function(UserSetting) _then;

/// Create a copy of UserSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? prompt = null,Object? colorValue = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSetting].
extension UserSettingPatterns on UserSetting {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSetting() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSetting value)  $default,){
final _that = this;
switch (_that) {
case _UserSetting():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSetting value)?  $default,){
final _that = this;
switch (_that) {
case _UserSetting() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String prompt, @JsonKey(defaultValue: 0xFF5C6BC0)  int colorValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSetting() when $default != null:
return $default(_that.id,_that.name,_that.prompt,_that.colorValue);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String prompt, @JsonKey(defaultValue: 0xFF5C6BC0)  int colorValue)  $default,) {final _that = this;
switch (_that) {
case _UserSetting():
return $default(_that.id,_that.name,_that.prompt,_that.colorValue);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String prompt, @JsonKey(defaultValue: 0xFF5C6BC0)  int colorValue)?  $default,) {final _that = this;
switch (_that) {
case _UserSetting() when $default != null:
return $default(_that.id,_that.name,_that.prompt,_that.colorValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSetting extends UserSetting {
  const _UserSetting({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: '') required this.prompt, @JsonKey(defaultValue: 0xFF5C6BC0) required this.colorValue}): super._();
  factory _UserSetting.fromJson(Map<String, dynamic> json) => _$UserSettingFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: '') final  String prompt;
@override@JsonKey(defaultValue: 0xFF5C6BC0) final  int colorValue;

/// Create a copy of UserSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingCopyWith<_UserSetting> get copyWith => __$UserSettingCopyWithImpl<_UserSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSettingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,prompt,colorValue);

@override
String toString() {
  return 'UserSetting(id: $id, name: $name, prompt: $prompt, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class _$UserSettingCopyWith<$Res> implements $UserSettingCopyWith<$Res> {
  factory _$UserSettingCopyWith(_UserSetting value, $Res Function(_UserSetting) _then) = __$UserSettingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String prompt,@JsonKey(defaultValue: 0xFF5C6BC0) int colorValue
});




}
/// @nodoc
class __$UserSettingCopyWithImpl<$Res>
    implements _$UserSettingCopyWith<$Res> {
  __$UserSettingCopyWithImpl(this._self, this._then);

  final _UserSetting _self;
  final $Res Function(_UserSetting) _then;

/// Create a copy of UserSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? prompt = null,Object? colorValue = null,}) {
  return _then(_UserSetting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
