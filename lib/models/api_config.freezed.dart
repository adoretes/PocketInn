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
mixin _$ApiModel {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '') String get modelId;@JsonKey(defaultValue: '') String get customBody;
/// Create a copy of ApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiModelCopyWith<ApiModel> get copyWith => _$ApiModelCopyWithImpl<ApiModel>(this as ApiModel, _$identity);

  /// Serializes this ApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.customBody, customBody) || other.customBody == customBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,modelId,customBody);

@override
String toString() {
  return 'ApiModel(id: $id, modelId: $modelId, customBody: $customBody)';
}


}

/// @nodoc
abstract mixin class $ApiModelCopyWith<$Res>  {
  factory $ApiModelCopyWith(ApiModel value, $Res Function(ApiModel) _then) = _$ApiModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String modelId,@JsonKey(defaultValue: '') String customBody
});




}
/// @nodoc
class _$ApiModelCopyWithImpl<$Res>
    implements $ApiModelCopyWith<$Res> {
  _$ApiModelCopyWithImpl(this._self, this._then);

  final ApiModel _self;
  final $Res Function(ApiModel) _then;

/// Create a copy of ApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? modelId = null,Object? customBody = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiModel].
extension ApiModelPatterns on ApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiModel value)  $default,){
final _that = this;
switch (_that) {
case _ApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String modelId, @JsonKey(defaultValue: '')  String customBody)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiModel() when $default != null:
return $default(_that.id,_that.modelId,_that.customBody);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String modelId, @JsonKey(defaultValue: '')  String customBody)  $default,) {final _that = this;
switch (_that) {
case _ApiModel():
return $default(_that.id,_that.modelId,_that.customBody);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String modelId, @JsonKey(defaultValue: '')  String customBody)?  $default,) {final _that = this;
switch (_that) {
case _ApiModel() when $default != null:
return $default(_that.id,_that.modelId,_that.customBody);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiModel extends ApiModel {
  const _ApiModel({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '') required this.modelId, @JsonKey(defaultValue: '') this.customBody = ''}): super._();
  factory _ApiModel.fromJson(Map<String, dynamic> json) => _$ApiModelFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '') final  String modelId;
@override@JsonKey(defaultValue: '') final  String customBody;

/// Create a copy of ApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiModelCopyWith<_ApiModel> get copyWith => __$ApiModelCopyWithImpl<_ApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.customBody, customBody) || other.customBody == customBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,modelId,customBody);

@override
String toString() {
  return 'ApiModel(id: $id, modelId: $modelId, customBody: $customBody)';
}


}

/// @nodoc
abstract mixin class _$ApiModelCopyWith<$Res> implements $ApiModelCopyWith<$Res> {
  factory _$ApiModelCopyWith(_ApiModel value, $Res Function(_ApiModel) _then) = __$ApiModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String modelId,@JsonKey(defaultValue: '') String customBody
});




}
/// @nodoc
class __$ApiModelCopyWithImpl<$Res>
    implements _$ApiModelCopyWith<$Res> {
  __$ApiModelCopyWithImpl(this._self, this._then);

  final _ApiModel _self;
  final $Res Function(_ApiModel) _then;

/// Create a copy of ApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? modelId = null,Object? customBody = null,}) {
  return _then(_ApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApiConfig {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '未命名配置') String get name;@JsonKey(defaultValue: '') String get baseUrl;@JsonKey(defaultValue: '') String get apiKey;@JsonKey(defaultValue: <ApiModel>[]) List<ApiModel> get models;
/// Create a copy of ApiConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiConfigCopyWith<ApiConfig> get copyWith => _$ApiConfigCopyWithImpl<ApiConfig>(this as ApiConfig, _$identity);

  /// Serializes this ApiConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&const DeepCollectionEquality().equals(other.models, models));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,const DeepCollectionEquality().hash(models));

@override
String toString() {
  return 'ApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, models: $models)';
}


}

/// @nodoc
abstract mixin class $ApiConfigCopyWith<$Res>  {
  factory $ApiConfigCopyWith(ApiConfig value, $Res Function(ApiConfig) _then) = _$ApiConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: <ApiModel>[]) List<ApiModel> models
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? models = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,models: null == models ? _self.models : models // ignore: cast_nullable_to_non_nullable
as List<ApiModel>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: <ApiModel>[])  List<ApiModel> models)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.models);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: <ApiModel>[])  List<ApiModel> models)  $default,) {final _that = this;
switch (_that) {
case _ApiConfig():
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.models);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: <ApiModel>[])  List<ApiModel> models)?  $default,) {final _that = this;
switch (_that) {
case _ApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.models);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiConfig extends ApiConfig {
  const _ApiConfig({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '未命名配置') required this.name, @JsonKey(defaultValue: '') required this.baseUrl, @JsonKey(defaultValue: '') required this.apiKey, @JsonKey(defaultValue: <ApiModel>[]) final  List<ApiModel> models = const <ApiModel>[]}): _models = models,super._();
  factory _ApiConfig.fromJson(Map<String, dynamic> json) => _$ApiConfigFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '未命名配置') final  String name;
@override@JsonKey(defaultValue: '') final  String baseUrl;
@override@JsonKey(defaultValue: '') final  String apiKey;
 final  List<ApiModel> _models;
@override@JsonKey(defaultValue: <ApiModel>[]) List<ApiModel> get models {
  if (_models is EqualUnmodifiableListView) return _models;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_models);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&const DeepCollectionEquality().equals(other._models, _models));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,const DeepCollectionEquality().hash(_models));

@override
String toString() {
  return 'ApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, models: $models)';
}


}

/// @nodoc
abstract mixin class _$ApiConfigCopyWith<$Res> implements $ApiConfigCopyWith<$Res> {
  factory _$ApiConfigCopyWith(_ApiConfig value, $Res Function(_ApiConfig) _then) = __$ApiConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: <ApiModel>[]) List<ApiModel> models
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? models = null,}) {
  return _then(_ApiConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,models: null == models ? _self._models : models // ignore: cast_nullable_to_non_nullable
as List<ApiModel>,
  ));
}


}


/// @nodoc
mixin _$ResolvedApiConfig {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '未命名配置') String get name;@JsonKey(defaultValue: '') String get baseUrl;@JsonKey(defaultValue: '') String get apiKey;@JsonKey(defaultValue: '') String get model;@JsonKey(defaultValue: '') String get customBody;
/// Create a copy of ResolvedApiConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedApiConfigCopyWith<ResolvedApiConfig> get copyWith => _$ResolvedApiConfigCopyWithImpl<ResolvedApiConfig>(this as ResolvedApiConfig, _$identity);

  /// Serializes this ResolvedApiConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.customBody, customBody) || other.customBody == customBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,model,customBody);

@override
String toString() {
  return 'ResolvedApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, model: $model, customBody: $customBody)';
}


}

/// @nodoc
abstract mixin class $ResolvedApiConfigCopyWith<$Res>  {
  factory $ResolvedApiConfigCopyWith(ResolvedApiConfig value, $Res Function(ResolvedApiConfig) _then) = _$ResolvedApiConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: '') String model,@JsonKey(defaultValue: '') String customBody
});




}
/// @nodoc
class _$ResolvedApiConfigCopyWithImpl<$Res>
    implements $ResolvedApiConfigCopyWith<$Res> {
  _$ResolvedApiConfigCopyWithImpl(this._self, this._then);

  final ResolvedApiConfig _self;
  final $Res Function(ResolvedApiConfig) _then;

/// Create a copy of ResolvedApiConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? model = null,Object? customBody = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedApiConfig].
extension ResolvedApiConfigPatterns on ResolvedApiConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedApiConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedApiConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedApiConfig value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedApiConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedApiConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedApiConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody)  $default,) {final _that = this;
switch (_that) {
case _ResolvedApiConfig():
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '未命名配置')  String name, @JsonKey(defaultValue: '')  String baseUrl, @JsonKey(defaultValue: '')  String apiKey, @JsonKey(defaultValue: '')  String model, @JsonKey(defaultValue: '')  String customBody)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedApiConfig() when $default != null:
return $default(_that.id,_that.name,_that.baseUrl,_that.apiKey,_that.model,_that.customBody);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedApiConfig extends ResolvedApiConfig {
  const _ResolvedApiConfig({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '未命名配置') required this.name, @JsonKey(defaultValue: '') required this.baseUrl, @JsonKey(defaultValue: '') required this.apiKey, @JsonKey(defaultValue: '') required this.model, @JsonKey(defaultValue: '') this.customBody = ''}): super._();
  factory _ResolvedApiConfig.fromJson(Map<String, dynamic> json) => _$ResolvedApiConfigFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '未命名配置') final  String name;
@override@JsonKey(defaultValue: '') final  String baseUrl;
@override@JsonKey(defaultValue: '') final  String apiKey;
@override@JsonKey(defaultValue: '') final  String model;
@override@JsonKey(defaultValue: '') final  String customBody;

/// Create a copy of ResolvedApiConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedApiConfigCopyWith<_ResolvedApiConfig> get copyWith => __$ResolvedApiConfigCopyWithImpl<_ResolvedApiConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedApiConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedApiConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.customBody, customBody) || other.customBody == customBody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,baseUrl,apiKey,model,customBody);

@override
String toString() {
  return 'ResolvedApiConfig(id: $id, name: $name, baseUrl: $baseUrl, apiKey: $apiKey, model: $model, customBody: $customBody)';
}


}

/// @nodoc
abstract mixin class _$ResolvedApiConfigCopyWith<$Res> implements $ResolvedApiConfigCopyWith<$Res> {
  factory _$ResolvedApiConfigCopyWith(_ResolvedApiConfig value, $Res Function(_ResolvedApiConfig) _then) = __$ResolvedApiConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '未命名配置') String name,@JsonKey(defaultValue: '') String baseUrl,@JsonKey(defaultValue: '') String apiKey,@JsonKey(defaultValue: '') String model,@JsonKey(defaultValue: '') String customBody
});




}
/// @nodoc
class __$ResolvedApiConfigCopyWithImpl<$Res>
    implements _$ResolvedApiConfigCopyWith<$Res> {
  __$ResolvedApiConfigCopyWithImpl(this._self, this._then);

  final _ResolvedApiConfig _self;
  final $Res Function(_ResolvedApiConfig) _then;

/// Create a copy of ResolvedApiConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? baseUrl = null,Object? apiKey = null,Object? model = null,Object? customBody = null,}) {
  return _then(_ResolvedApiConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,customBody: null == customBody ? _self.customBody : customBody // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
