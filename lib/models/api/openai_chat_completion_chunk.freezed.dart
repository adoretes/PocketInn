// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'openai_chat_completion_chunk.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OpenAIChatCompletionChunk {

 String? get id; String? get model; List<OpenAIChunkChoice> get choices;
/// Create a copy of OpenAIChatCompletionChunk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIChatCompletionChunkCopyWith<OpenAIChatCompletionChunk> get copyWith => _$OpenAIChatCompletionChunkCopyWithImpl<OpenAIChatCompletionChunk>(this as OpenAIChatCompletionChunk, _$identity);

  /// Serializes this OpenAIChatCompletionChunk to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIChatCompletionChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other.choices, choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,model,const DeepCollectionEquality().hash(choices));

@override
String toString() {
  return 'OpenAIChatCompletionChunk(id: $id, model: $model, choices: $choices)';
}


}

/// @nodoc
abstract mixin class $OpenAIChatCompletionChunkCopyWith<$Res>  {
  factory $OpenAIChatCompletionChunkCopyWith(OpenAIChatCompletionChunk value, $Res Function(OpenAIChatCompletionChunk) _then) = _$OpenAIChatCompletionChunkCopyWithImpl;
@useResult
$Res call({
 String? id, String? model, List<OpenAIChunkChoice> choices
});




}
/// @nodoc
class _$OpenAIChatCompletionChunkCopyWithImpl<$Res>
    implements $OpenAIChatCompletionChunkCopyWith<$Res> {
  _$OpenAIChatCompletionChunkCopyWithImpl(this._self, this._then);

  final OpenAIChatCompletionChunk _self;
  final $Res Function(OpenAIChatCompletionChunk) _then;

/// Create a copy of OpenAIChatCompletionChunk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? model = freezed,Object? choices = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<OpenAIChunkChoice>,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIChatCompletionChunk].
extension OpenAIChatCompletionChunkPatterns on OpenAIChatCompletionChunk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIChatCompletionChunk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIChatCompletionChunk value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIChatCompletionChunk value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? model,  List<OpenAIChunkChoice> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk() when $default != null:
return $default(_that.id,_that.model,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? model,  List<OpenAIChunkChoice> choices)  $default,) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk():
return $default(_that.id,_that.model,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? model,  List<OpenAIChunkChoice> choices)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionChunk() when $default != null:
return $default(_that.id,_that.model,_that.choices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIChatCompletionChunk implements OpenAIChatCompletionChunk {
  const _OpenAIChatCompletionChunk({this.id, this.model, final  List<OpenAIChunkChoice> choices = const []}): _choices = choices;
  factory _OpenAIChatCompletionChunk.fromJson(Map<String, dynamic> json) => _$OpenAIChatCompletionChunkFromJson(json);

@override final  String? id;
@override final  String? model;
 final  List<OpenAIChunkChoice> _choices;
@override@JsonKey() List<OpenAIChunkChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of OpenAIChatCompletionChunk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIChatCompletionChunkCopyWith<_OpenAIChatCompletionChunk> get copyWith => __$OpenAIChatCompletionChunkCopyWithImpl<_OpenAIChatCompletionChunk>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIChatCompletionChunkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIChatCompletionChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other._choices, _choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,model,const DeepCollectionEquality().hash(_choices));

@override
String toString() {
  return 'OpenAIChatCompletionChunk(id: $id, model: $model, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$OpenAIChatCompletionChunkCopyWith<$Res> implements $OpenAIChatCompletionChunkCopyWith<$Res> {
  factory _$OpenAIChatCompletionChunkCopyWith(_OpenAIChatCompletionChunk value, $Res Function(_OpenAIChatCompletionChunk) _then) = __$OpenAIChatCompletionChunkCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? model, List<OpenAIChunkChoice> choices
});




}
/// @nodoc
class __$OpenAIChatCompletionChunkCopyWithImpl<$Res>
    implements _$OpenAIChatCompletionChunkCopyWith<$Res> {
  __$OpenAIChatCompletionChunkCopyWithImpl(this._self, this._then);

  final _OpenAIChatCompletionChunk _self;
  final $Res Function(_OpenAIChatCompletionChunk) _then;

/// Create a copy of OpenAIChatCompletionChunk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? model = freezed,Object? choices = null,}) {
  return _then(_OpenAIChatCompletionChunk(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OpenAIChunkChoice>,
  ));
}


}


/// @nodoc
mixin _$OpenAIChunkChoice {

 int get index; OpenAIChunkDelta? get delta;@JsonKey(name: 'finish_reason') String? get finishReason;@JsonKey(readValue: _readChoiceTextRaw) Object? get text;@JsonKey(readValue: _readChoiceReasoningRaw) Object? get reasoning;
/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIChunkChoiceCopyWith<OpenAIChunkChoice> get copyWith => _$OpenAIChunkChoiceCopyWithImpl<OpenAIChunkChoice>(this as OpenAIChunkChoice, _$identity);

  /// Serializes this OpenAIChunkChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIChunkChoice&&(identical(other.index, index) || other.index == index)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason)&&const DeepCollectionEquality().equals(other.text, text)&&const DeepCollectionEquality().equals(other.reasoning, reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,delta,finishReason,const DeepCollectionEquality().hash(text),const DeepCollectionEquality().hash(reasoning));

@override
String toString() {
  return 'OpenAIChunkChoice(index: $index, delta: $delta, finishReason: $finishReason, text: $text, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class $OpenAIChunkChoiceCopyWith<$Res>  {
  factory $OpenAIChunkChoiceCopyWith(OpenAIChunkChoice value, $Res Function(OpenAIChunkChoice) _then) = _$OpenAIChunkChoiceCopyWithImpl;
@useResult
$Res call({
 int index, OpenAIChunkDelta? delta,@JsonKey(name: 'finish_reason') String? finishReason,@JsonKey(readValue: _readChoiceTextRaw) Object? text,@JsonKey(readValue: _readChoiceReasoningRaw) Object? reasoning
});


$OpenAIChunkDeltaCopyWith<$Res>? get delta;

}
/// @nodoc
class _$OpenAIChunkChoiceCopyWithImpl<$Res>
    implements $OpenAIChunkChoiceCopyWith<$Res> {
  _$OpenAIChunkChoiceCopyWithImpl(this._self, this._then);

  final OpenAIChunkChoice _self;
  final $Res Function(OpenAIChunkChoice) _then;

/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? delta = freezed,Object? finishReason = freezed,Object? text = freezed,Object? reasoning = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as OpenAIChunkDelta?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text ,reasoning: freezed == reasoning ? _self.reasoning : reasoning ,
  ));
}
/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenAIChunkDeltaCopyWith<$Res>? get delta {
    if (_self.delta == null) {
    return null;
  }

  return $OpenAIChunkDeltaCopyWith<$Res>(_self.delta!, (value) {
    return _then(_self.copyWith(delta: value));
  });
}
}


/// Adds pattern-matching-related methods to [OpenAIChunkChoice].
extension OpenAIChunkChoicePatterns on OpenAIChunkChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIChunkChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIChunkChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIChunkChoice value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIChunkChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIChunkChoice value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIChunkChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  OpenAIChunkDelta? delta, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIChunkChoice() when $default != null:
return $default(_that.index,_that.delta,_that.finishReason,_that.text,_that.reasoning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  OpenAIChunkDelta? delta, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)  $default,) {final _that = this;
switch (_that) {
case _OpenAIChunkChoice():
return $default(_that.index,_that.delta,_that.finishReason,_that.text,_that.reasoning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  OpenAIChunkDelta? delta, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIChunkChoice() when $default != null:
return $default(_that.index,_that.delta,_that.finishReason,_that.text,_that.reasoning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIChunkChoice extends OpenAIChunkChoice {
  const _OpenAIChunkChoice({this.index = 0, this.delta, @JsonKey(name: 'finish_reason') this.finishReason, @JsonKey(readValue: _readChoiceTextRaw) this.text, @JsonKey(readValue: _readChoiceReasoningRaw) this.reasoning}): super._();
  factory _OpenAIChunkChoice.fromJson(Map<String, dynamic> json) => _$OpenAIChunkChoiceFromJson(json);

@override@JsonKey() final  int index;
@override final  OpenAIChunkDelta? delta;
@override@JsonKey(name: 'finish_reason') final  String? finishReason;
@override@JsonKey(readValue: _readChoiceTextRaw) final  Object? text;
@override@JsonKey(readValue: _readChoiceReasoningRaw) final  Object? reasoning;

/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIChunkChoiceCopyWith<_OpenAIChunkChoice> get copyWith => __$OpenAIChunkChoiceCopyWithImpl<_OpenAIChunkChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIChunkChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIChunkChoice&&(identical(other.index, index) || other.index == index)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason)&&const DeepCollectionEquality().equals(other.text, text)&&const DeepCollectionEquality().equals(other.reasoning, reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,delta,finishReason,const DeepCollectionEquality().hash(text),const DeepCollectionEquality().hash(reasoning));

@override
String toString() {
  return 'OpenAIChunkChoice(index: $index, delta: $delta, finishReason: $finishReason, text: $text, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class _$OpenAIChunkChoiceCopyWith<$Res> implements $OpenAIChunkChoiceCopyWith<$Res> {
  factory _$OpenAIChunkChoiceCopyWith(_OpenAIChunkChoice value, $Res Function(_OpenAIChunkChoice) _then) = __$OpenAIChunkChoiceCopyWithImpl;
@override @useResult
$Res call({
 int index, OpenAIChunkDelta? delta,@JsonKey(name: 'finish_reason') String? finishReason,@JsonKey(readValue: _readChoiceTextRaw) Object? text,@JsonKey(readValue: _readChoiceReasoningRaw) Object? reasoning
});


@override $OpenAIChunkDeltaCopyWith<$Res>? get delta;

}
/// @nodoc
class __$OpenAIChunkChoiceCopyWithImpl<$Res>
    implements _$OpenAIChunkChoiceCopyWith<$Res> {
  __$OpenAIChunkChoiceCopyWithImpl(this._self, this._then);

  final _OpenAIChunkChoice _self;
  final $Res Function(_OpenAIChunkChoice) _then;

/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? delta = freezed,Object? finishReason = freezed,Object? text = freezed,Object? reasoning = freezed,}) {
  return _then(_OpenAIChunkChoice(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as OpenAIChunkDelta?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text ,reasoning: freezed == reasoning ? _self.reasoning : reasoning ,
  ));
}

/// Create a copy of OpenAIChunkChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenAIChunkDeltaCopyWith<$Res>? get delta {
    if (_self.delta == null) {
    return null;
  }

  return $OpenAIChunkDeltaCopyWith<$Res>(_self.delta!, (value) {
    return _then(_self.copyWith(delta: value));
  });
}
}


/// @nodoc
mixin _$OpenAIChunkDelta {

 String? get role;@JsonKey(readValue: _readDeltaContentRaw) Object? get content;@JsonKey(readValue: _readDeltaReasoningRaw) Object? get reasoningContent;
/// Create a copy of OpenAIChunkDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIChunkDeltaCopyWith<OpenAIChunkDelta> get copyWith => _$OpenAIChunkDeltaCopyWithImpl<OpenAIChunkDelta>(this as OpenAIChunkDelta, _$identity);

  /// Serializes this OpenAIChunkDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIChunkDelta&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.reasoningContent, reasoningContent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(reasoningContent));

@override
String toString() {
  return 'OpenAIChunkDelta(role: $role, content: $content, reasoningContent: $reasoningContent)';
}


}

/// @nodoc
abstract mixin class $OpenAIChunkDeltaCopyWith<$Res>  {
  factory $OpenAIChunkDeltaCopyWith(OpenAIChunkDelta value, $Res Function(OpenAIChunkDelta) _then) = _$OpenAIChunkDeltaCopyWithImpl;
@useResult
$Res call({
 String? role,@JsonKey(readValue: _readDeltaContentRaw) Object? content,@JsonKey(readValue: _readDeltaReasoningRaw) Object? reasoningContent
});




}
/// @nodoc
class _$OpenAIChunkDeltaCopyWithImpl<$Res>
    implements $OpenAIChunkDeltaCopyWith<$Res> {
  _$OpenAIChunkDeltaCopyWithImpl(this._self, this._then);

  final OpenAIChunkDelta _self;
  final $Res Function(OpenAIChunkDelta) _then;

/// Create a copy of OpenAIChunkDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = freezed,Object? content = freezed,Object? reasoningContent = freezed,}) {
  return _then(_self.copyWith(
role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content ,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent ,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIChunkDelta].
extension OpenAIChunkDeltaPatterns on OpenAIChunkDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIChunkDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIChunkDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIChunkDelta value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIChunkDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIChunkDelta value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIChunkDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? role, @JsonKey(readValue: _readDeltaContentRaw)  Object? content, @JsonKey(readValue: _readDeltaReasoningRaw)  Object? reasoningContent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIChunkDelta() when $default != null:
return $default(_that.role,_that.content,_that.reasoningContent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? role, @JsonKey(readValue: _readDeltaContentRaw)  Object? content, @JsonKey(readValue: _readDeltaReasoningRaw)  Object? reasoningContent)  $default,) {final _that = this;
switch (_that) {
case _OpenAIChunkDelta():
return $default(_that.role,_that.content,_that.reasoningContent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? role, @JsonKey(readValue: _readDeltaContentRaw)  Object? content, @JsonKey(readValue: _readDeltaReasoningRaw)  Object? reasoningContent)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIChunkDelta() when $default != null:
return $default(_that.role,_that.content,_that.reasoningContent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIChunkDelta extends OpenAIChunkDelta {
  const _OpenAIChunkDelta({this.role, @JsonKey(readValue: _readDeltaContentRaw) this.content, @JsonKey(readValue: _readDeltaReasoningRaw) this.reasoningContent}): super._();
  factory _OpenAIChunkDelta.fromJson(Map<String, dynamic> json) => _$OpenAIChunkDeltaFromJson(json);

@override final  String? role;
@override@JsonKey(readValue: _readDeltaContentRaw) final  Object? content;
@override@JsonKey(readValue: _readDeltaReasoningRaw) final  Object? reasoningContent;

/// Create a copy of OpenAIChunkDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIChunkDeltaCopyWith<_OpenAIChunkDelta> get copyWith => __$OpenAIChunkDeltaCopyWithImpl<_OpenAIChunkDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIChunkDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIChunkDelta&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.reasoningContent, reasoningContent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(reasoningContent));

@override
String toString() {
  return 'OpenAIChunkDelta(role: $role, content: $content, reasoningContent: $reasoningContent)';
}


}

/// @nodoc
abstract mixin class _$OpenAIChunkDeltaCopyWith<$Res> implements $OpenAIChunkDeltaCopyWith<$Res> {
  factory _$OpenAIChunkDeltaCopyWith(_OpenAIChunkDelta value, $Res Function(_OpenAIChunkDelta) _then) = __$OpenAIChunkDeltaCopyWithImpl;
@override @useResult
$Res call({
 String? role,@JsonKey(readValue: _readDeltaContentRaw) Object? content,@JsonKey(readValue: _readDeltaReasoningRaw) Object? reasoningContent
});




}
/// @nodoc
class __$OpenAIChunkDeltaCopyWithImpl<$Res>
    implements _$OpenAIChunkDeltaCopyWith<$Res> {
  __$OpenAIChunkDeltaCopyWithImpl(this._self, this._then);

  final _OpenAIChunkDelta _self;
  final $Res Function(_OpenAIChunkDelta) _then;

/// Create a copy of OpenAIChunkDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = freezed,Object? content = freezed,Object? reasoningContent = freezed,}) {
  return _then(_OpenAIChunkDelta(
role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content ,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent ,
  ));
}


}

// dart format on
