// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSession {

 String get id; String get title; String get characterId; String? get selectedUserSettingId; List<String> get selectedWorldBookIds; String? get selectedPresetId; String? get currentLeafMessageId; String get lastMessagePreview; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSessionCopyWith<ChatSession> get copyWith => _$ChatSessionCopyWithImpl<ChatSession>(this as ChatSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSession&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.selectedUserSettingId, selectedUserSettingId) || other.selectedUserSettingId == selectedUserSettingId)&&const DeepCollectionEquality().equals(other.selectedWorldBookIds, selectedWorldBookIds)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId)&&(identical(other.currentLeafMessageId, currentLeafMessageId) || other.currentLeafMessageId == currentLeafMessageId)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,characterId,selectedUserSettingId,const DeepCollectionEquality().hash(selectedWorldBookIds),selectedPresetId,currentLeafMessageId,lastMessagePreview,createdAt,updatedAt);

@override
String toString() {
  return 'ChatSession(id: $id, title: $title, characterId: $characterId, selectedUserSettingId: $selectedUserSettingId, selectedWorldBookIds: $selectedWorldBookIds, selectedPresetId: $selectedPresetId, currentLeafMessageId: $currentLeafMessageId, lastMessagePreview: $lastMessagePreview, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChatSessionCopyWith<$Res>  {
  factory $ChatSessionCopyWith(ChatSession value, $Res Function(ChatSession) _then) = _$ChatSessionCopyWithImpl;
@useResult
$Res call({
 String id, String title, String characterId, String? selectedUserSettingId, List<String> selectedWorldBookIds, String? selectedPresetId, String? currentLeafMessageId, String lastMessagePreview, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ChatSessionCopyWithImpl<$Res>
    implements $ChatSessionCopyWith<$Res> {
  _$ChatSessionCopyWithImpl(this._self, this._then);

  final ChatSession _self;
  final $Res Function(ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? characterId = null,Object? selectedUserSettingId = freezed,Object? selectedWorldBookIds = null,Object? selectedPresetId = freezed,Object? currentLeafMessageId = freezed,Object? lastMessagePreview = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,selectedUserSettingId: freezed == selectedUserSettingId ? _self.selectedUserSettingId : selectedUserSettingId // ignore: cast_nullable_to_non_nullable
as String?,selectedWorldBookIds: null == selectedWorldBookIds ? _self.selectedWorldBookIds : selectedWorldBookIds // ignore: cast_nullable_to_non_nullable
as List<String>,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,currentLeafMessageId: freezed == currentLeafMessageId ? _self.currentLeafMessageId : currentLeafMessageId // ignore: cast_nullable_to_non_nullable
as String?,lastMessagePreview: null == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSession].
extension ChatSessionPatterns on ChatSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSession value)  $default,){
final _that = this;
switch (_that) {
case _ChatSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSession value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String characterId,  String? selectedUserSettingId,  List<String> selectedWorldBookIds,  String? selectedPresetId,  String? currentLeafMessageId,  String lastMessagePreview,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.id,_that.title,_that.characterId,_that.selectedUserSettingId,_that.selectedWorldBookIds,_that.selectedPresetId,_that.currentLeafMessageId,_that.lastMessagePreview,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String characterId,  String? selectedUserSettingId,  List<String> selectedWorldBookIds,  String? selectedPresetId,  String? currentLeafMessageId,  String lastMessagePreview,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatSession():
return $default(_that.id,_that.title,_that.characterId,_that.selectedUserSettingId,_that.selectedWorldBookIds,_that.selectedPresetId,_that.currentLeafMessageId,_that.lastMessagePreview,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String characterId,  String? selectedUserSettingId,  List<String> selectedWorldBookIds,  String? selectedPresetId,  String? currentLeafMessageId,  String lastMessagePreview,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.id,_that.title,_that.characterId,_that.selectedUserSettingId,_that.selectedWorldBookIds,_that.selectedPresetId,_that.currentLeafMessageId,_that.lastMessagePreview,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSession implements ChatSession {
  const _ChatSession({required this.id, required this.title, required this.characterId, this.selectedUserSettingId, required final  List<String> selectedWorldBookIds, this.selectedPresetId, this.currentLeafMessageId, this.lastMessagePreview = '', required this.createdAt, required this.updatedAt}): _selectedWorldBookIds = selectedWorldBookIds;
  

@override final  String id;
@override final  String title;
@override final  String characterId;
@override final  String? selectedUserSettingId;
 final  List<String> _selectedWorldBookIds;
@override List<String> get selectedWorldBookIds {
  if (_selectedWorldBookIds is EqualUnmodifiableListView) return _selectedWorldBookIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedWorldBookIds);
}

@override final  String? selectedPresetId;
@override final  String? currentLeafMessageId;
@override@JsonKey() final  String lastMessagePreview;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSessionCopyWith<_ChatSession> get copyWith => __$ChatSessionCopyWithImpl<_ChatSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSession&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.selectedUserSettingId, selectedUserSettingId) || other.selectedUserSettingId == selectedUserSettingId)&&const DeepCollectionEquality().equals(other._selectedWorldBookIds, _selectedWorldBookIds)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId)&&(identical(other.currentLeafMessageId, currentLeafMessageId) || other.currentLeafMessageId == currentLeafMessageId)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,characterId,selectedUserSettingId,const DeepCollectionEquality().hash(_selectedWorldBookIds),selectedPresetId,currentLeafMessageId,lastMessagePreview,createdAt,updatedAt);

@override
String toString() {
  return 'ChatSession(id: $id, title: $title, characterId: $characterId, selectedUserSettingId: $selectedUserSettingId, selectedWorldBookIds: $selectedWorldBookIds, selectedPresetId: $selectedPresetId, currentLeafMessageId: $currentLeafMessageId, lastMessagePreview: $lastMessagePreview, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatSessionCopyWith<$Res> implements $ChatSessionCopyWith<$Res> {
  factory _$ChatSessionCopyWith(_ChatSession value, $Res Function(_ChatSession) _then) = __$ChatSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String characterId, String? selectedUserSettingId, List<String> selectedWorldBookIds, String? selectedPresetId, String? currentLeafMessageId, String lastMessagePreview, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ChatSessionCopyWithImpl<$Res>
    implements _$ChatSessionCopyWith<$Res> {
  __$ChatSessionCopyWithImpl(this._self, this._then);

  final _ChatSession _self;
  final $Res Function(_ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? characterId = null,Object? selectedUserSettingId = freezed,Object? selectedWorldBookIds = null,Object? selectedPresetId = freezed,Object? currentLeafMessageId = freezed,Object? lastMessagePreview = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ChatSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,selectedUserSettingId: freezed == selectedUserSettingId ? _self.selectedUserSettingId : selectedUserSettingId // ignore: cast_nullable_to_non_nullable
as String?,selectedWorldBookIds: null == selectedWorldBookIds ? _self._selectedWorldBookIds : selectedWorldBookIds // ignore: cast_nullable_to_non_nullable
as List<String>,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,currentLeafMessageId: freezed == currentLeafMessageId ? _self.currentLeafMessageId : currentLeafMessageId // ignore: cast_nullable_to_non_nullable
as String?,lastMessagePreview: null == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ChatNode {

 String get id; String get sessionId; String? get parentId; ChatNodeRole get role; String get text; String? get thinkingChain; DateTime get createdAt; int get siblingOrder;
/// Create a copy of ChatNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNodeCopyWith<ChatNode> get copyWith => _$ChatNodeCopyWithImpl<ChatNode>(this as ChatNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNode&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&(identical(other.thinkingChain, thinkingChain) || other.thinkingChain == thinkingChain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.siblingOrder, siblingOrder) || other.siblingOrder == siblingOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,parentId,role,text,thinkingChain,createdAt,siblingOrder);

@override
String toString() {
  return 'ChatNode(id: $id, sessionId: $sessionId, parentId: $parentId, role: $role, text: $text, thinkingChain: $thinkingChain, createdAt: $createdAt, siblingOrder: $siblingOrder)';
}


}

/// @nodoc
abstract mixin class $ChatNodeCopyWith<$Res>  {
  factory $ChatNodeCopyWith(ChatNode value, $Res Function(ChatNode) _then) = _$ChatNodeCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String? parentId, ChatNodeRole role, String text, String? thinkingChain, DateTime createdAt, int siblingOrder
});




}
/// @nodoc
class _$ChatNodeCopyWithImpl<$Res>
    implements $ChatNodeCopyWith<$Res> {
  _$ChatNodeCopyWithImpl(this._self, this._then);

  final ChatNode _self;
  final $Res Function(ChatNode) _then;

/// Create a copy of ChatNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? parentId = freezed,Object? role = null,Object? text = null,Object? thinkingChain = freezed,Object? createdAt = null,Object? siblingOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatNodeRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,thinkingChain: freezed == thinkingChain ? _self.thinkingChain : thinkingChain // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,siblingOrder: null == siblingOrder ? _self.siblingOrder : siblingOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNode].
extension ChatNodePatterns on ChatNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNode value)  $default,){
final _that = this;
switch (_that) {
case _ChatNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNode value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String? parentId,  ChatNodeRole role,  String text,  String? thinkingChain,  DateTime createdAt,  int siblingOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNode() when $default != null:
return $default(_that.id,_that.sessionId,_that.parentId,_that.role,_that.text,_that.thinkingChain,_that.createdAt,_that.siblingOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String? parentId,  ChatNodeRole role,  String text,  String? thinkingChain,  DateTime createdAt,  int siblingOrder)  $default,) {final _that = this;
switch (_that) {
case _ChatNode():
return $default(_that.id,_that.sessionId,_that.parentId,_that.role,_that.text,_that.thinkingChain,_that.createdAt,_that.siblingOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String? parentId,  ChatNodeRole role,  String text,  String? thinkingChain,  DateTime createdAt,  int siblingOrder)?  $default,) {final _that = this;
switch (_that) {
case _ChatNode() when $default != null:
return $default(_that.id,_that.sessionId,_that.parentId,_that.role,_that.text,_that.thinkingChain,_that.createdAt,_that.siblingOrder);case _:
  return null;

}
}

}

/// @nodoc


class _ChatNode implements ChatNode {
  const _ChatNode({required this.id, required this.sessionId, this.parentId, required this.role, required this.text, this.thinkingChain, required this.createdAt, required this.siblingOrder});
  

@override final  String id;
@override final  String sessionId;
@override final  String? parentId;
@override final  ChatNodeRole role;
@override final  String text;
@override final  String? thinkingChain;
@override final  DateTime createdAt;
@override final  int siblingOrder;

/// Create a copy of ChatNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNodeCopyWith<_ChatNode> get copyWith => __$ChatNodeCopyWithImpl<_ChatNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNode&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&(identical(other.thinkingChain, thinkingChain) || other.thinkingChain == thinkingChain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.siblingOrder, siblingOrder) || other.siblingOrder == siblingOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,sessionId,parentId,role,text,thinkingChain,createdAt,siblingOrder);

@override
String toString() {
  return 'ChatNode(id: $id, sessionId: $sessionId, parentId: $parentId, role: $role, text: $text, thinkingChain: $thinkingChain, createdAt: $createdAt, siblingOrder: $siblingOrder)';
}


}

/// @nodoc
abstract mixin class _$ChatNodeCopyWith<$Res> implements $ChatNodeCopyWith<$Res> {
  factory _$ChatNodeCopyWith(_ChatNode value, $Res Function(_ChatNode) _then) = __$ChatNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String? parentId, ChatNodeRole role, String text, String? thinkingChain, DateTime createdAt, int siblingOrder
});




}
/// @nodoc
class __$ChatNodeCopyWithImpl<$Res>
    implements _$ChatNodeCopyWith<$Res> {
  __$ChatNodeCopyWithImpl(this._self, this._then);

  final _ChatNode _self;
  final $Res Function(_ChatNode) _then;

/// Create a copy of ChatNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? parentId = freezed,Object? role = null,Object? text = null,Object? thinkingChain = freezed,Object? createdAt = null,Object? siblingOrder = null,}) {
  return _then(_ChatNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatNodeRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,thinkingChain: freezed == thinkingChain ? _self.thinkingChain : thinkingChain // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,siblingOrder: null == siblingOrder ? _self.siblingOrder : siblingOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ChatSessionSummary {

 String get id; String get title; String get characterId; String get lastMessagePreview; DateTime get updatedAt;
/// Create a copy of ChatSessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSessionSummaryCopyWith<ChatSessionSummary> get copyWith => _$ChatSessionSummaryCopyWithImpl<ChatSessionSummary>(this as ChatSessionSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSessionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,characterId,lastMessagePreview,updatedAt);

@override
String toString() {
  return 'ChatSessionSummary(id: $id, title: $title, characterId: $characterId, lastMessagePreview: $lastMessagePreview, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChatSessionSummaryCopyWith<$Res>  {
  factory $ChatSessionSummaryCopyWith(ChatSessionSummary value, $Res Function(ChatSessionSummary) _then) = _$ChatSessionSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String characterId, String lastMessagePreview, DateTime updatedAt
});




}
/// @nodoc
class _$ChatSessionSummaryCopyWithImpl<$Res>
    implements $ChatSessionSummaryCopyWith<$Res> {
  _$ChatSessionSummaryCopyWithImpl(this._self, this._then);

  final ChatSessionSummary _self;
  final $Res Function(ChatSessionSummary) _then;

/// Create a copy of ChatSessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? characterId = null,Object? lastMessagePreview = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,lastMessagePreview: null == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSessionSummary].
extension ChatSessionSummaryPatterns on ChatSessionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSessionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _ChatSessionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSessionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String characterId,  String lastMessagePreview,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSessionSummary() when $default != null:
return $default(_that.id,_that.title,_that.characterId,_that.lastMessagePreview,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String characterId,  String lastMessagePreview,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatSessionSummary():
return $default(_that.id,_that.title,_that.characterId,_that.lastMessagePreview,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String characterId,  String lastMessagePreview,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatSessionSummary() when $default != null:
return $default(_that.id,_that.title,_that.characterId,_that.lastMessagePreview,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSessionSummary implements ChatSessionSummary {
  const _ChatSessionSummary({required this.id, required this.title, required this.characterId, required this.lastMessagePreview, required this.updatedAt});
  

@override final  String id;
@override final  String title;
@override final  String characterId;
@override final  String lastMessagePreview;
@override final  DateTime updatedAt;

/// Create a copy of ChatSessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSessionSummaryCopyWith<_ChatSessionSummary> get copyWith => __$ChatSessionSummaryCopyWithImpl<_ChatSessionSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSessionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,characterId,lastMessagePreview,updatedAt);

@override
String toString() {
  return 'ChatSessionSummary(id: $id, title: $title, characterId: $characterId, lastMessagePreview: $lastMessagePreview, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatSessionSummaryCopyWith<$Res> implements $ChatSessionSummaryCopyWith<$Res> {
  factory _$ChatSessionSummaryCopyWith(_ChatSessionSummary value, $Res Function(_ChatSessionSummary) _then) = __$ChatSessionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String characterId, String lastMessagePreview, DateTime updatedAt
});




}
/// @nodoc
class __$ChatSessionSummaryCopyWithImpl<$Res>
    implements _$ChatSessionSummaryCopyWith<$Res> {
  __$ChatSessionSummaryCopyWithImpl(this._self, this._then);

  final _ChatSessionSummary _self;
  final $Res Function(_ChatSessionSummary) _then;

/// Create a copy of ChatSessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? characterId = null,Object? lastMessagePreview = null,Object? updatedAt = null,}) {
  return _then(_ChatSessionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,lastMessagePreview: null == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ChatSessionBundle {

 ChatSession get session; List<ChatMessage> get activeMessages;
/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSessionBundleCopyWith<ChatSessionBundle> get copyWith => _$ChatSessionBundleCopyWithImpl<ChatSessionBundle>(this as ChatSessionBundle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSessionBundle&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other.activeMessages, activeMessages));
}


@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(activeMessages));

@override
String toString() {
  return 'ChatSessionBundle(session: $session, activeMessages: $activeMessages)';
}


}

/// @nodoc
abstract mixin class $ChatSessionBundleCopyWith<$Res>  {
  factory $ChatSessionBundleCopyWith(ChatSessionBundle value, $Res Function(ChatSessionBundle) _then) = _$ChatSessionBundleCopyWithImpl;
@useResult
$Res call({
 ChatSession session, List<ChatMessage> activeMessages
});


$ChatSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$ChatSessionBundleCopyWithImpl<$Res>
    implements $ChatSessionBundleCopyWith<$Res> {
  _$ChatSessionBundleCopyWithImpl(this._self, this._then);

  final ChatSessionBundle _self;
  final $Res Function(ChatSessionBundle) _then;

/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? activeMessages = null,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as ChatSession,activeMessages: null == activeMessages ? _self.activeMessages : activeMessages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,
  ));
}
/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSessionCopyWith<$Res> get session {
  
  return $ChatSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatSessionBundle].
extension ChatSessionBundlePatterns on ChatSessionBundle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSessionBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSessionBundle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSessionBundle value)  $default,){
final _that = this;
switch (_that) {
case _ChatSessionBundle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSessionBundle value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSessionBundle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatSession session,  List<ChatMessage> activeMessages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSessionBundle() when $default != null:
return $default(_that.session,_that.activeMessages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatSession session,  List<ChatMessage> activeMessages)  $default,) {final _that = this;
switch (_that) {
case _ChatSessionBundle():
return $default(_that.session,_that.activeMessages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatSession session,  List<ChatMessage> activeMessages)?  $default,) {final _that = this;
switch (_that) {
case _ChatSessionBundle() when $default != null:
return $default(_that.session,_that.activeMessages);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSessionBundle implements ChatSessionBundle {
  const _ChatSessionBundle({required this.session, required final  List<ChatMessage> activeMessages}): _activeMessages = activeMessages;
  

@override final  ChatSession session;
 final  List<ChatMessage> _activeMessages;
@override List<ChatMessage> get activeMessages {
  if (_activeMessages is EqualUnmodifiableListView) return _activeMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeMessages);
}


/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSessionBundleCopyWith<_ChatSessionBundle> get copyWith => __$ChatSessionBundleCopyWithImpl<_ChatSessionBundle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSessionBundle&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other._activeMessages, _activeMessages));
}


@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(_activeMessages));

@override
String toString() {
  return 'ChatSessionBundle(session: $session, activeMessages: $activeMessages)';
}


}

/// @nodoc
abstract mixin class _$ChatSessionBundleCopyWith<$Res> implements $ChatSessionBundleCopyWith<$Res> {
  factory _$ChatSessionBundleCopyWith(_ChatSessionBundle value, $Res Function(_ChatSessionBundle) _then) = __$ChatSessionBundleCopyWithImpl;
@override @useResult
$Res call({
 ChatSession session, List<ChatMessage> activeMessages
});


@override $ChatSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$ChatSessionBundleCopyWithImpl<$Res>
    implements _$ChatSessionBundleCopyWith<$Res> {
  __$ChatSessionBundleCopyWithImpl(this._self, this._then);

  final _ChatSessionBundle _self;
  final $Res Function(_ChatSessionBundle) _then;

/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? activeMessages = null,}) {
  return _then(_ChatSessionBundle(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as ChatSession,activeMessages: null == activeMessages ? _self._activeMessages : activeMessages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,
  ));
}

/// Create a copy of ChatSessionBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSessionCopyWith<$Res> get session {
  
  return $ChatSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
