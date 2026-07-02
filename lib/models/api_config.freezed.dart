// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiConfig {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '未命名配置') String get name;@JsonKey(defaultValue: '') String get baseUrl;@JsonKey(defaultValue: '') String get apiKey;@JsonKey(defaultValue: '') String get model;@JsonKey(defaultValue: '') String get customBody;@JsonKey(defaultValue: false) bool get enabled;
/// Create a copy of ApiConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiConfigCopyWith<ApiConfig> get copyWith => _$ApiConfigCopyWithImpl<ApiConfig>(this as ApiConfig, _$identity);

  /// Serializes this ApiConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.customBody, customBody) || other.customBody == customBody)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,model,customBody,enabled);

@override
String toString() {
  return 'ApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, model: $model, customBody: $customBody, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $ApiConfigCopyWith<$Res>  {
  factory $ApiConfigCopyWith(ApiConfig value, $Res Function(ApiConfig) _then) = _$ApiConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: '') String model,@JsonKey(defaultValue: '') String customBody,@JsonKey(defaultValue: false) bool enabled
});




}
/// @nodoc
class _$ApiConfigCopyWithImpl<$Res>
    implements $ApiConfigCopyWith<$Res> {
  _$ApiConfigCopyWithImpl(this._self, this._then);

  final ApiConfig _self;
  final $Res Function(ApiConfig) _then;

/// Create a copy of ApiConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? model = null,Object? customBody = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiConfig].
extension ApiConfigPatterns on ApiConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiConfig value)  $default,){
final _that = this;
switch (_that) {
case _ApiConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody, @JsonKey(defaultValue: false)  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody, @JsonKey(defaultValue: false)  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _ApiConfig():
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody, @JsonKey(defaultValue: false)  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiConfig extends ApiConfig {
  const _ApiConfig({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '未命名配置') required this.name, @JsonKey(defaultValue: '') required this.baseUrl, @JsonKey(defaultValue: '') required this.apiKey, @JsonKey(defaultValue: '') required this.model, @JsonKey(defaultValue: '') this.customBody = '', @JsonKey(defaultValue: false) this.enabled = false}): super._();
  factory _ApiConfig.fromJson(Map<String, dynamic> json) => _$ApiConfigFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '未命名配置') final  String name;
@override@JsonKey(defaultValue: '') final  String baseUrl;
@override@JsonKey(defaultValue: '') final  String apiKey;
@override@JsonKey(defaultValue: '') final  String model;
@override@JsonKey(defaultValue: '') final  String customBody;
@override@JsonKey(defaultValue: false) final  bool enabled;

/// Create a copy of ApiConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiConfigCopyWith<_ApiConfig> get copyWith => __$ApiConfigCopyWithImpl<_ApiConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.customBody, customBody) || other.customBody == customBody)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,model,customBody,enabled);

@override
String toString() {
  return 'ApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, model: $model, customBody: $customBody, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ApiConfigCopyWith<$Res> implements $ApiConfigCopyWith<$Res> {
  factory _$ApiConfigCopyWith(_ApiConfig value, $Res Function(_ApiConfig) _then) = __$ApiConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: '') String model,@JsonKey(defaultValue: '') String customBody,@JsonKey(defaultValue: false) bool enabled
});




}
/// @nodoc
class __$ApiConfigCopyWithImpl<$Res>
    implements _$ApiConfigCopyWith<$Res> {
  __$ApiConfigCopyWithImpl(this._self, this._then);

  final _ApiConfig _self;
  final $Res Function(_ApiConfig) _then;

/// Create a copy of ApiConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? model = null,Object? customBody = null,Object? enabled = null,}) {
  return _then(_ApiConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
