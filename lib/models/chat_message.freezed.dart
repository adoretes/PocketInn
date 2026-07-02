// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String? get id; String? get sessionId; String? get parentId; String get text; bool get isMe;/// 当前消息索引（从1开始）
 int get index;/// 该角色的总消息数
 int get total;/// 同级消息 ID 列表，顺序与 index/total 对应
 List<String> get siblingIds;/// 思考链内容（可选）
 String? get thinkingChain;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.text, text) || other.text == text)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.index, index) || other.index == index)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.siblingIds, siblingIds)&&(identical(other.thinkingChain, thinkingChain) || other.thinkingChain == thinkingChain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,parentId,text,isMe,index,total,const DeepCollectionEquality().hash(siblingIds),thinkingChain);

@override
String toString() {
  return 'ChatMessage(id: $id, sessionId: $sessionId, parentId: $parentId, text: $text, isMe: $isMe, index: $index, total: $total, siblingIds: $siblingIds, thinkingChain: $thinkingChain)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String? id, String? sessionId, String? parentId, String text, bool isMe, int index, int total, List<String> siblingIds, String? thinkingChain
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? sessionId = freezed,Object? parentId = freezed,Object? text = null,Object? isMe = null,Object? index = null,Object? total = null,Object? siblingIds = null,Object? thinkingChain = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,siblingIds: null == siblingIds ? _self.siblingIds : siblingIds // ignore: cast_nullable_to_non_nullable
as List<String>,thinkingChain: freezed == thinkingChain ? _self.thinkingChain : thinkingChain // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? sessionId,  String? parentId,  String text,  bool isMe,  int index,  int total,  List<String> siblingIds,  String? thinkingChain)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.sessionId,_that.parentId,_that.text,_that.isMe,_that.index,_that.total,_that.siblingIds,_that.thinkingChain);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? sessionId,  String? parentId,  String text,  bool isMe,  int index,  int total,  List<String> siblingIds,  String? thinkingChain)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.sessionId,_that.parentId,_that.text,_that.isMe,_that.index,_that.total,_that.siblingIds,_that.thinkingChain);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? sessionId,  String? parentId,  String text,  bool isMe,  int index,  int total,  List<String> siblingIds,  String? thinkingChain)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.sessionId,_that.parentId,_that.text,_that.isMe,_that.index,_that.total,_that.siblingIds,_that.thinkingChain);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage extends ChatMessage {
  const _ChatMessage({this.id, this.sessionId, this.parentId, required this.text, required this.isMe, this.index = 1, this.total = 1, final  List<String> siblingIds = const [], this.thinkingChain}): _siblingIds = siblingIds,super._();
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String? id;
@override final  String? sessionId;
@override final  String? parentId;
@override final  String text;
@override final  bool isMe;
/// 当前消息索引（从1开始）
@override@JsonKey() final  int index;
/// 该角色的总消息数
@override@JsonKey() final  int total;
/// 同级消息 ID 列表，顺序与 index/total 对应
 final  List<String> _siblingIds;
/// 同级消息 ID 列表，顺序与 index/total 对应
@override@JsonKey() List<String> get siblingIds {
  if (_siblingIds is EqualUnmodifiableListView) return _siblingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_siblingIds);
}

/// 思考链内容（可选）
@override final  String? thinkingChain;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.text, text) || other.text == text)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.index, index) || other.index == index)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._siblingIds, _siblingIds)&&(identical(other.thinkingChain, thinkingChain) || other.thinkingChain == thinkingChain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,parentId,text,isMe,index,total,const DeepCollectionEquality().hash(_siblingIds),thinkingChain);

@override
String toString() {
  return 'ChatMessage(id: $id, sessionId: $sessionId, parentId: $parentId, text: $text, isMe: $isMe, index: $index, total: $total, siblingIds: $siblingIds, thinkingChain: $thinkingChain)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? sessionId, String? parentId, String text, bool isMe, int index, int total, List<String> siblingIds, String? thinkingChain
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? sessionId = freezed,Object? parentId = freezed,Object? text = null,Object? isMe = null,Object? index = null,Object? total = null,Object? siblingIds = null,Object? thinkingChain = freezed,}) {
  return _then(_ChatMessage(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,siblingIds: null == siblingIds ? _self._siblingIds : siblingIds // ignore: cast_nullable_to_non_nullable
as List<String>,thinkingChain: freezed == thinkingChain ? _self.thinkingChain : thinkingChain // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
