// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'openai_models_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OpenAIModelsResponse {

 List<OpenAIModelInfo> get data;
/// Create a copy of OpenAIModelsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIModelsResponseCopyWith<OpenAIModelsResponse> get copyWith => _$OpenAIModelsResponseCopyWithImpl<OpenAIModelsResponse>(this as OpenAIModelsResponse, _$identity);

  /// Serializes this OpenAIModelsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIModelsResponse&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'OpenAIModelsResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class $OpenAIModelsResponseCopyWith<$Res>  {
  factory $OpenAIModelsResponseCopyWith(OpenAIModelsResponse value, $Res Function(OpenAIModelsResponse) _then) = _$OpenAIModelsResponseCopyWithImpl;
@useResult
$Res call({
 List<OpenAIModelInfo> data
});




}
/// @nodoc
class _$OpenAIModelsResponseCopyWithImpl<$Res>
    implements $OpenAIModelsResponseCopyWith<$Res> {
  _$OpenAIModelsResponseCopyWithImpl(this._self, this._then);

  final OpenAIModelsResponse _self;
  final $Res Function(OpenAIModelsResponse) _then;

/// Create a copy of OpenAIModelsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<OpenAIModelInfo>,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIModelsResponse].
extension OpenAIModelsResponsePatterns on OpenAIModelsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIModelsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIModelsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIModelsResponse value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIModelsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIModelsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIModelsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OpenAIModelInfo> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIModelsResponse() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OpenAIModelInfo> data)  $default,) {final _that = this;
switch (_that) {
case _OpenAIModelsResponse():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OpenAIModelInfo> data)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIModelsResponse() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIModelsResponse implements OpenAIModelsResponse {
  const _OpenAIModelsResponse({final  List<OpenAIModelInfo> data = const []}): _data = data;
  factory _OpenAIModelsResponse.fromJson(Map<String, dynamic> json) => _$OpenAIModelsResponseFromJson(json);

 final  List<OpenAIModelInfo> _data;
@override@JsonKey() List<OpenAIModelInfo> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of OpenAIModelsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIModelsResponseCopyWith<_OpenAIModelsResponse> get copyWith => __$OpenAIModelsResponseCopyWithImpl<_OpenAIModelsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIModelsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIModelsResponse&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'OpenAIModelsResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class _$OpenAIModelsResponseCopyWith<$Res> implements $OpenAIModelsResponseCopyWith<$Res> {
  factory _$OpenAIModelsResponseCopyWith(_OpenAIModelsResponse value, $Res Function(_OpenAIModelsResponse) _then) = __$OpenAIModelsResponseCopyWithImpl;
@override @useResult
$Res call({
 List<OpenAIModelInfo> data
});




}
/// @nodoc
class __$OpenAIModelsResponseCopyWithImpl<$Res>
    implements _$OpenAIModelsResponseCopyWith<$Res> {
  __$OpenAIModelsResponseCopyWithImpl(this._self, this._then);

  final _OpenAIModelsResponse _self;
  final $Res Function(_OpenAIModelsResponse) _then;

/// Create a copy of OpenAIModelsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_OpenAIModelsResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<OpenAIModelInfo>,
  ));
}


}


/// @nodoc
mixin _$OpenAIModelInfo {

 String get id; String? get object;@JsonKey(name: 'owned_by') String? get ownedBy;
/// Create a copy of OpenAIModelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIModelInfoCopyWith<OpenAIModelInfo> get copyWith => _$OpenAIModelInfoCopyWithImpl<OpenAIModelInfo>(this as OpenAIModelInfo, _$identity);

  /// Serializes this OpenAIModelInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIModelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.object, object) || other.object == object)&&(identical(other.ownedBy, ownedBy) || other.ownedBy == ownedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,object,ownedBy);

@override
String toString() {
  return 'OpenAIModelInfo(id: $id, object: $object, ownedBy: $ownedBy)';
}


}

/// @nodoc
abstract mixin class $OpenAIModelInfoCopyWith<$Res>  {
  factory $OpenAIModelInfoCopyWith(OpenAIModelInfo value, $Res Function(OpenAIModelInfo) _then) = _$OpenAIModelInfoCopyWithImpl;
@useResult
$Res call({
 String id, String? object,@JsonKey(name: 'owned_by') String? ownedBy
});




}
/// @nodoc
class _$OpenAIModelInfoCopyWithImpl<$Res>
    implements $OpenAIModelInfoCopyWith<$Res> {
  _$OpenAIModelInfoCopyWithImpl(this._self, this._then);

  final OpenAIModelInfo _self;
  final $Res Function(OpenAIModelInfo) _then;

/// Create a copy of OpenAIModelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? object = freezed,Object? ownedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,object: freezed == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as String?,ownedBy: freezed == ownedBy ? _self.ownedBy : ownedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIModelInfo].
extension OpenAIModelInfoPatterns on OpenAIModelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIModelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIModelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIModelInfo value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIModelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIModelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIModelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? object, @JsonKey(name: 'owned_by')  String? ownedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIModelInfo() when $default != null:
return $default(_that.id,_that.object,_that.ownedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? object, @JsonKey(name: 'owned_by')  String? ownedBy)  $default,) {final _that = this;
switch (_that) {
case _OpenAIModelInfo():
return $default(_that.id,_that.object,_that.ownedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? object, @JsonKey(name: 'owned_by')  String? ownedBy)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIModelInfo() when $default != null:
return $default(_that.id,_that.object,_that.ownedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIModelInfo implements OpenAIModelInfo {
  const _OpenAIModelInfo({required this.id, this.object, @JsonKey(name: 'owned_by') this.ownedBy});
  factory _OpenAIModelInfo.fromJson(Map<String, dynamic> json) => _$OpenAIModelInfoFromJson(json);

@override final  String id;
@override final  String? object;
@override@JsonKey(name: 'owned_by') final  String? ownedBy;

/// Create a copy of OpenAIModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIModelInfoCopyWith<_OpenAIModelInfo> get copyWith => __$OpenAIModelInfoCopyWithImpl<_OpenAIModelInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIModelInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIModelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.object, object) || other.object == object)&&(identical(other.ownedBy, ownedBy) || other.ownedBy == ownedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,object,ownedBy);

@override
String toString() {
  return 'OpenAIModelInfo(id: $id, object: $object, ownedBy: $ownedBy)';
}


}

/// @nodoc
abstract mixin class _$OpenAIModelInfoCopyWith<$Res> implements $OpenAIModelInfoCopyWith<$Res> {
  factory _$OpenAIModelInfoCopyWith(_OpenAIModelInfo value, $Res Function(_OpenAIModelInfo) _then) = __$OpenAIModelInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? object,@JsonKey(name: 'owned_by') String? ownedBy
});




}
/// @nodoc
class __$OpenAIModelInfoCopyWithImpl<$Res>
    implements _$OpenAIModelInfoCopyWith<$Res> {
  __$OpenAIModelInfoCopyWithImpl(this._self, this._then);

  final _OpenAIModelInfo _self;
  final $Res Function(_OpenAIModelInfo) _then;

/// Create a copy of OpenAIModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? object = freezed,Object? ownedBy = freezed,}) {
  return _then(_OpenAIModelInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,object: freezed == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as String?,ownedBy: freezed == ownedBy ? _self.ownedBy : ownedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
