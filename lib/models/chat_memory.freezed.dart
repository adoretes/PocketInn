// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemoryNode {

 String get id; String get sessionId; String get branchLeafId; String get content; List<String> get sourceMessageIds; bool get isUserEdited; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of MemoryNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryNodeCopyWith<MemoryNode> get copyWith => _$MemoryNodeCopyWithImpl<MemoryNode>(this as MemoryNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryNode&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.branchLeafId, branchLeafId) || other.branchLeafId == branchLeafId)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.sourceMessageIds, sourceMessageIds)&&(identical(other.isUserEdited, isUserEdited) || other.isUserEdited == isUserEdited)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,branchLeafId,content,const DeepCollectionEquality().hash(sourceMessageIds),isUserEdited,createdAt,updatedAt);

@override
String toString() {
  return 'MemoryNode(id: $id, sessionId: $sessionId, branchLeafId: $branchLeafId, content: $content, sourceMessageIds: $sourceMessageIds, isUserEdited: $isUserEdited, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MemoryNodeCopyWith<$Res>  {
  factory $MemoryNodeCopyWith(MemoryNode value, $Res Function(MemoryNode) _then) = _$MemoryNodeCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String branchLeafId, String content, List<String> sourceMessageIds, bool isUserEdited, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$MemoryNodeCopyWithImpl<$Res>
    implements $MemoryNodeCopyWith<$Res> {
  _$MemoryNodeCopyWithImpl(this._self, this._then);

  final MemoryNode _self;
  final $Res Function(MemoryNode) _then;

/// Create a copy of MemoryNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? branchLeafId = null,Object? content = null,Object? sourceMessageIds = null,Object? isUserEdited = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,branchLeafId: null == branchLeafId ? _self.branchLeafId : branchLeafId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,sourceMessageIds: null == sourceMessageIds ? _self.sourceMessageIds : sourceMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,isUserEdited: null == isUserEdited ? _self.isUserEdited : isUserEdited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryNode].
extension MemoryNodePatterns on MemoryNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryNode value)  $default,){
final _that = this;
switch (_that) {
case _MemoryNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryNode value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String branchLeafId,  String content,  List<String> sourceMessageIds,  bool isUserEdited,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryNode() when $default != null:
return $default(_that.id,_that.sessionId,_that.branchLeafId,_that.content,_that.sourceMessageIds,_that.isUserEdited,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String branchLeafId,  String content,  List<String> sourceMessageIds,  bool isUserEdited,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MemoryNode():
return $default(_that.id,_that.sessionId,_that.branchLeafId,_that.content,_that.sourceMessageIds,_that.isUserEdited,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String branchLeafId,  String content,  List<String> sourceMessageIds,  bool isUserEdited,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MemoryNode() when $default != null:
return $default(_that.id,_that.sessionId,_that.branchLeafId,_that.content,_that.sourceMessageIds,_that.isUserEdited,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MemoryNode implements MemoryNode {
  const _MemoryNode({required this.id, required this.sessionId, required this.branchLeafId, required this.content, final  List<String> sourceMessageIds = const [], this.isUserEdited = false, required this.createdAt, required this.updatedAt}): _sourceMessageIds = sourceMessageIds;
  

@override final  String id;
@override final  String sessionId;
@override final  String branchLeafId;
@override final  String content;
 final  List<String> _sourceMessageIds;
@override@JsonKey() List<String> get sourceMessageIds {
  if (_sourceMessageIds is EqualUnmodifiableListView) return _sourceMessageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceMessageIds);
}

@override@JsonKey() final  bool isUserEdited;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of MemoryNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryNodeCopyWith<_MemoryNode> get copyWith => __$MemoryNodeCopyWithImpl<_MemoryNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryNode&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.branchLeafId, branchLeafId) || other.branchLeafId == branchLeafId)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._sourceMessageIds, _sourceMessageIds)&&(identical(other.isUserEdited, isUserEdited) || other.isUserEdited == isUserEdited)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,branchLeafId,content,const DeepCollectionEquality().hash(_sourceMessageIds),isUserEdited,createdAt,updatedAt);

@override
String toString() {
  return 'MemoryNode(id: $id, sessionId: $sessionId, branchLeafId: $branchLeafId, content: $content, sourceMessageIds: $sourceMessageIds, isUserEdited: $isUserEdited, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MemoryNodeCopyWith<$Res> implements $MemoryNodeCopyWith<$Res> {
  factory _$MemoryNodeCopyWith(_MemoryNode value, $Res Function(_MemoryNode) _then) = __$MemoryNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String branchLeafId, String content, List<String> sourceMessageIds, bool isUserEdited, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$MemoryNodeCopyWithImpl<$Res>
    implements _$MemoryNodeCopyWith<$Res> {
  __$MemoryNodeCopyWithImpl(this._self, this._then);

  final _MemoryNode _self;
  final $Res Function(_MemoryNode) _then;

/// Create a copy of MemoryNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? branchLeafId = null,Object? content = null,Object? sourceMessageIds = null,Object? isUserEdited = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MemoryNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,branchLeafId: null == branchLeafId ? _self.branchLeafId : branchLeafId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,sourceMessageIds: null == sourceMessageIds ? _self._sourceMessageIds : sourceMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,isUserEdited: null == isUserEdited ? _self.isUserEdited : isUserEdited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$MemoryExtractionConfig {

 bool get enabled; int get interval; int get recentRounds; int get recallCount; String? get extractionModelId; String get customExtractionPrompt; String get customInjectionPrompt;
/// Create a copy of MemoryExtractionConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryExtractionConfigCopyWith<MemoryExtractionConfig> get copyWith => _$MemoryExtractionConfigCopyWithImpl<MemoryExtractionConfig>(this as MemoryExtractionConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryExtractionConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.recentRounds, recentRounds) || other.recentRounds == recentRounds)&&(identical(other.recallCount, recallCount) || other.recallCount == recallCount)&&(identical(other.extractionModelId, extractionModelId) || other.extractionModelId == extractionModelId)&&(identical(other.customExtractionPrompt, customExtractionPrompt) || other.customExtractionPrompt == customExtractionPrompt)&&(identical(other.customInjectionPrompt, customInjectionPrompt) || other.customInjectionPrompt == customInjectionPrompt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,interval,recentRounds,recallCount,extractionModelId,customExtractionPrompt,customInjectionPrompt);

@override
String toString() {
  return 'MemoryExtractionConfig(enabled: $enabled, interval: $interval, recentRounds: $recentRounds, recallCount: $recallCount, extractionModelId: $extractionModelId, customExtractionPrompt: $customExtractionPrompt, customInjectionPrompt: $customInjectionPrompt)';
}


}

/// @nodoc
abstract mixin class $MemoryExtractionConfigCopyWith<$Res>  {
  factory $MemoryExtractionConfigCopyWith(MemoryExtractionConfig value, $Res Function(MemoryExtractionConfig) _then) = _$MemoryExtractionConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, int interval, int recentRounds, int recallCount, String? extractionModelId, String customExtractionPrompt, String customInjectionPrompt
});




}
/// @nodoc
class _$MemoryExtractionConfigCopyWithImpl<$Res>
    implements $MemoryExtractionConfigCopyWith<$Res> {
  _$MemoryExtractionConfigCopyWithImpl(this._self, this._then);

  final MemoryExtractionConfig _self;
  final $Res Function(MemoryExtractionConfig) _then;

/// Create a copy of MemoryExtractionConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? interval = null,Object? recentRounds = null,Object? recallCount = null,Object? extractionModelId = freezed,Object? customExtractionPrompt = null,Object? customInjectionPrompt = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,recentRounds: null == recentRounds ? _self.recentRounds : recentRounds // ignore: cast_nullable_to_non_nullable
as int,recallCount: null == recallCount ? _self.recallCount : recallCount // ignore: cast_nullable_to_non_nullable
as int,extractionModelId: freezed == extractionModelId ? _self.extractionModelId : extractionModelId // ignore: cast_nullable_to_non_nullable
as String?,customExtractionPrompt: null == customExtractionPrompt ? _self.customExtractionPrompt : customExtractionPrompt // ignore: cast_nullable_to_non_nullable
as String,customInjectionPrompt: null == customInjectionPrompt ? _self.customInjectionPrompt : customInjectionPrompt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryExtractionConfig].
extension MemoryExtractionConfigPatterns on MemoryExtractionConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryExtractionConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryExtractionConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryExtractionConfig value)  $default,){
final _that = this;
switch (_that) {
case _MemoryExtractionConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryExtractionConfig value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryExtractionConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int interval,  int recentRounds,  int recallCount,  String? extractionModelId,  String customExtractionPrompt,  String customInjectionPrompt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryExtractionConfig() when $default != null:
return $default(_that.enabled,_that.interval,_that.recentRounds,_that.recallCount,_that.extractionModelId,_that.customExtractionPrompt,_that.customInjectionPrompt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int interval,  int recentRounds,  int recallCount,  String? extractionModelId,  String customExtractionPrompt,  String customInjectionPrompt)  $default,) {final _that = this;
switch (_that) {
case _MemoryExtractionConfig():
return $default(_that.enabled,_that.interval,_that.recentRounds,_that.recallCount,_that.extractionModelId,_that.customExtractionPrompt,_that.customInjectionPrompt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int interval,  int recentRounds,  int recallCount,  String? extractionModelId,  String customExtractionPrompt,  String customInjectionPrompt)?  $default,) {final _that = this;
switch (_that) {
case _MemoryExtractionConfig() when $default != null:
return $default(_that.enabled,_that.interval,_that.recentRounds,_that.recallCount,_that.extractionModelId,_that.customExtractionPrompt,_that.customInjectionPrompt);case _:
  return null;

}
}

}

/// @nodoc


class _MemoryExtractionConfig extends MemoryExtractionConfig {
  const _MemoryExtractionConfig({this.enabled = false, this.interval = 5, this.recentRounds = 10, this.recallCount = 3, this.extractionModelId, this.customExtractionPrompt = '', this.customInjectionPrompt = ''}): super._();
  

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int interval;
@override@JsonKey() final  int recentRounds;
@override@JsonKey() final  int recallCount;
@override final  String? extractionModelId;
@override@JsonKey() final  String customExtractionPrompt;
@override@JsonKey() final  String customInjectionPrompt;

/// Create a copy of MemoryExtractionConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryExtractionConfigCopyWith<_MemoryExtractionConfig> get copyWith => __$MemoryExtractionConfigCopyWithImpl<_MemoryExtractionConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryExtractionConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.recentRounds, recentRounds) || other.recentRounds == recentRounds)&&(identical(other.recallCount, recallCount) || other.recallCount == recallCount)&&(identical(other.extractionModelId, extractionModelId) || other.extractionModelId == extractionModelId)&&(identical(other.customExtractionPrompt, customExtractionPrompt) || other.customExtractionPrompt == customExtractionPrompt)&&(identical(other.customInjectionPrompt, customInjectionPrompt) || other.customInjectionPrompt == customInjectionPrompt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,interval,recentRounds,recallCount,extractionModelId,customExtractionPrompt,customInjectionPrompt);

@override
String toString() {
  return 'MemoryExtractionConfig(enabled: $enabled, interval: $interval, recentRounds: $recentRounds, recallCount: $recallCount, extractionModelId: $extractionModelId, customExtractionPrompt: $customExtractionPrompt, customInjectionPrompt: $customInjectionPrompt)';
}


}

/// @nodoc
abstract mixin class _$MemoryExtractionConfigCopyWith<$Res> implements $MemoryExtractionConfigCopyWith<$Res> {
  factory _$MemoryExtractionConfigCopyWith(_MemoryExtractionConfig value, $Res Function(_MemoryExtractionConfig) _then) = __$MemoryExtractionConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int interval, int recentRounds, int recallCount, String? extractionModelId, String customExtractionPrompt, String customInjectionPrompt
});




}
/// @nodoc
class __$MemoryExtractionConfigCopyWithImpl<$Res>
    implements _$MemoryExtractionConfigCopyWith<$Res> {
  __$MemoryExtractionConfigCopyWithImpl(this._self, this._then);

  final _MemoryExtractionConfig _self;
  final $Res Function(_MemoryExtractionConfig) _then;

/// Create a copy of MemoryExtractionConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? interval = null,Object? recentRounds = null,Object? recallCount = null,Object? extractionModelId = freezed,Object? customExtractionPrompt = null,Object? customInjectionPrompt = null,}) {
  return _then(_MemoryExtractionConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,recentRounds: null == recentRounds ? _self.recentRounds : recentRounds // ignore: cast_nullable_to_non_nullable
as int,recallCount: null == recallCount ? _self.recallCount : recallCount // ignore: cast_nullable_to_non_nullable
as int,extractionModelId: freezed == extractionModelId ? _self.extractionModelId : extractionModelId // ignore: cast_nullable_to_non_nullable
as String?,customExtractionPrompt: null == customExtractionPrompt ? _self.customExtractionPrompt : customExtractionPrompt // ignore: cast_nullable_to_non_nullable
as String,customInjectionPrompt: null == customInjectionPrompt ? _self.customInjectionPrompt : customInjectionPrompt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
