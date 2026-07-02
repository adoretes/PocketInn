// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'openai_chat_completion_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OpenAIChatCompletionResponse {

 String? get id; String? get model; List<OpenAIResponseChoice> get choices; Map<String, dynamic>? get usage;
/// Create a copy of OpenAIChatCompletionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIChatCompletionResponseCopyWith<OpenAIChatCompletionResponse> get copyWith => _$OpenAIChatCompletionResponseCopyWithImpl<OpenAIChatCompletionResponse>(this as OpenAIChatCompletionResponse, _$identity);

  /// Serializes this OpenAIChatCompletionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIChatCompletionResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other.choices, choices)&&const DeepCollectionEquality().equals(other.usage, usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,model,const DeepCollectionEquality().hash(choices),const DeepCollectionEquality().hash(usage));

@override
String toString() {
  return 'OpenAIChatCompletionResponse(id: $id, model: $model, choices: $choices, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $OpenAIChatCompletionResponseCopyWith<$Res>  {
  factory $OpenAIChatCompletionResponseCopyWith(OpenAIChatCompletionResponse value, $Res Function(OpenAIChatCompletionResponse) _then) = _$OpenAIChatCompletionResponseCopyWithImpl;
@useResult
$Res call({
 String? id, String? model, List<OpenAIResponseChoice> choices, Map<String, dynamic>? usage
});




}
/// @nodoc
class _$OpenAIChatCompletionResponseCopyWithImpl<$Res>
    implements $OpenAIChatCompletionResponseCopyWith<$Res> {
  _$OpenAIChatCompletionResponseCopyWithImpl(this._self, this._then);

  final OpenAIChatCompletionResponse _self;
  final $Res Function(OpenAIChatCompletionResponse) _then;

/// Create a copy of OpenAIChatCompletionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? model = freezed,Object? choices = null,Object? usage = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<OpenAIResponseChoice>,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIChatCompletionResponse].
extension OpenAIChatCompletionResponsePatterns on OpenAIChatCompletionResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIChatCompletionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIChatCompletionResponse value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIChatCompletionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? model,  List<OpenAIResponseChoice> choices,  Map<String, dynamic>? usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse() when $default != null:
return $default(_that.id,_that.model,_that.choices,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? model,  List<OpenAIResponseChoice> choices,  Map<String, dynamic>? usage)  $default,) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse():
return $default(_that.id,_that.model,_that.choices,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? model,  List<OpenAIResponseChoice> choices,  Map<String, dynamic>? usage)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIChatCompletionResponse() when $default != null:
return $default(_that.id,_that.model,_that.choices,_that.usage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIChatCompletionResponse implements OpenAIChatCompletionResponse {
  const _OpenAIChatCompletionResponse({this.id, this.model, final  List<OpenAIResponseChoice> choices = const [], final  Map<String, dynamic>? usage}): _choices = choices,_usage = usage;
  factory _OpenAIChatCompletionResponse.fromJson(Map<String, dynamic> json) => _$OpenAIChatCompletionResponseFromJson(json);

@override final  String? id;
@override final  String? model;
 final  List<OpenAIResponseChoice> _choices;
@override@JsonKey() List<OpenAIResponseChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}

 final  Map<String, dynamic>? _usage;
@override Map<String, dynamic>? get usage {
  final value = _usage;
  if (value == null) return null;
  if (_usage is EqualUnmodifiableMapView) return _usage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of OpenAIChatCompletionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIChatCompletionResponseCopyWith<_OpenAIChatCompletionResponse> get copyWith => __$OpenAIChatCompletionResponseCopyWithImpl<_OpenAIChatCompletionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIChatCompletionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIChatCompletionResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other._choices, _choices)&&const DeepCollectionEquality().equals(other._usage, _usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,model,const DeepCollectionEquality().hash(_choices),const DeepCollectionEquality().hash(_usage));

@override
String toString() {
  return 'OpenAIChatCompletionResponse(id: $id, model: $model, choices: $choices, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$OpenAIChatCompletionResponseCopyWith<$Res> implements $OpenAIChatCompletionResponseCopyWith<$Res> {
  factory _$OpenAIChatCompletionResponseCopyWith(_OpenAIChatCompletionResponse value, $Res Function(_OpenAIChatCompletionResponse) _then) = __$OpenAIChatCompletionResponseCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? model, List<OpenAIResponseChoice> choices, Map<String, dynamic>? usage
});




}
/// @nodoc
class __$OpenAIChatCompletionResponseCopyWithImpl<$Res>
    implements _$OpenAIChatCompletionResponseCopyWith<$Res> {
  __$OpenAIChatCompletionResponseCopyWithImpl(this._self, this._then);

  final _OpenAIChatCompletionResponse _self;
  final $Res Function(_OpenAIChatCompletionResponse) _then;

/// Create a copy of OpenAIChatCompletionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? model = freezed,Object? choices = null,Object? usage = freezed,}) {
  return _then(_OpenAIChatCompletionResponse(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OpenAIResponseChoice>,usage: freezed == usage ? _self._usage : usage // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$OpenAIResponseChoice {

 int get index; OpenAIResponseMessage? get message;@JsonKey(name: 'finish_reason') String? get finishReason;@JsonKey(readValue: _readChoiceTextRaw) Object? get text;@JsonKey(readValue: _readChoiceReasoningRaw) Object? get reasoning;
/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIResponseChoiceCopyWith<OpenAIResponseChoice> get copyWith => _$OpenAIResponseChoiceCopyWithImpl<OpenAIResponseChoice>(this as OpenAIResponseChoice, _$identity);

  /// Serializes this OpenAIResponseChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIResponseChoice&&(identical(other.index, index) || other.index == index)&&(identical(other.message, message) || other.message == message)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason)&&const DeepCollectionEquality().equals(other.text, text)&&const DeepCollectionEquality().equals(other.reasoning, reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,message,finishReason,const DeepCollectionEquality().hash(text),const DeepCollectionEquality().hash(reasoning));

@override
String toString() {
  return 'OpenAIResponseChoice(index: $index, message: $message, finishReason: $finishReason, text: $text, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class $OpenAIResponseChoiceCopyWith<$Res>  {
  factory $OpenAIResponseChoiceCopyWith(OpenAIResponseChoice value, $Res Function(OpenAIResponseChoice) _then) = _$OpenAIResponseChoiceCopyWithImpl;
@useResult
$Res call({
 int index, OpenAIResponseMessage? message,@JsonKey(name: 'finish_reason') String? finishReason,@JsonKey(readValue: _readChoiceTextRaw) Object? text,@JsonKey(readValue: _readChoiceReasoningRaw) Object? reasoning
});


$OpenAIResponseMessageCopyWith<$Res>? get message;

}
/// @nodoc
class _$OpenAIResponseChoiceCopyWithImpl<$Res>
    implements $OpenAIResponseChoiceCopyWith<$Res> {
  _$OpenAIResponseChoiceCopyWithImpl(this._self, this._then);

  final OpenAIResponseChoice _self;
  final $Res Function(OpenAIResponseChoice) _then;

/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? message = freezed,Object? finishReason = freezed,Object? text = freezed,Object? reasoning = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as OpenAIResponseMessage?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text ,reasoning: freezed == reasoning ? _self.reasoning : reasoning ,
  ));
}
/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenAIResponseMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $OpenAIResponseMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [OpenAIResponseChoice].
extension OpenAIResponseChoicePatterns on OpenAIResponseChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIResponseChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIResponseChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIResponseChoice value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIResponseChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIResponseChoice value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIResponseChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  OpenAIResponseMessage? message, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIResponseChoice() when $default != null:
return $default(_that.index,_that.message,_that.finishReason,_that.text,_that.reasoning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  OpenAIResponseMessage? message, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)  $default,) {final _that = this;
switch (_that) {
case _OpenAIResponseChoice():
return $default(_that.index,_that.message,_that.finishReason,_that.text,_that.reasoning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  OpenAIResponseMessage? message, @JsonKey(name: 'finish_reason')  String? finishReason, @JsonKey(readValue: _readChoiceTextRaw)  Object? text, @JsonKey(readValue: _readChoiceReasoningRaw)  Object? reasoning)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIResponseChoice() when $default != null:
return $default(_that.index,_that.message,_that.finishReason,_that.text,_that.reasoning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIResponseChoice extends OpenAIResponseChoice {
  const _OpenAIResponseChoice({this.index = 0, this.message, @JsonKey(name: 'finish_reason') this.finishReason, @JsonKey(readValue: _readChoiceTextRaw) this.text, @JsonKey(readValue: _readChoiceReasoningRaw) this.reasoning}): super._();
  factory _OpenAIResponseChoice.fromJson(Map<String, dynamic> json) => _$OpenAIResponseChoiceFromJson(json);

@override@JsonKey() final  int index;
@override final  OpenAIResponseMessage? message;
@override@JsonKey(name: 'finish_reason') final  String? finishReason;
@override@JsonKey(readValue: _readChoiceTextRaw) final  Object? text;
@override@JsonKey(readValue: _readChoiceReasoningRaw) final  Object? reasoning;

/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIResponseChoiceCopyWith<_OpenAIResponseChoice> get copyWith => __$OpenAIResponseChoiceCopyWithImpl<_OpenAIResponseChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIResponseChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIResponseChoice&&(identical(other.index, index) || other.index == index)&&(identical(other.message, message) || other.message == message)&&(identical(other.finishReason, finishReason) || other.finishReason == finishReason)&&const DeepCollectionEquality().equals(other.text, text)&&const DeepCollectionEquality().equals(other.reasoning, reasoning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,message,finishReason,const DeepCollectionEquality().hash(text),const DeepCollectionEquality().hash(reasoning));

@override
String toString() {
  return 'OpenAIResponseChoice(index: $index, message: $message, finishReason: $finishReason, text: $text, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class _$OpenAIResponseChoiceCopyWith<$Res> implements $OpenAIResponseChoiceCopyWith<$Res> {
  factory _$OpenAIResponseChoiceCopyWith(_OpenAIResponseChoice value, $Res Function(_OpenAIResponseChoice) _then) = __$OpenAIResponseChoiceCopyWithImpl;
@override @useResult
$Res call({
 int index, OpenAIResponseMessage? message,@JsonKey(name: 'finish_reason') String? finishReason,@JsonKey(readValue: _readChoiceTextRaw) Object? text,@JsonKey(readValue: _readChoiceReasoningRaw) Object? reasoning
});


@override $OpenAIResponseMessageCopyWith<$Res>? get message;

}
/// @nodoc
class __$OpenAIResponseChoiceCopyWithImpl<$Res>
    implements _$OpenAIResponseChoiceCopyWith<$Res> {
  __$OpenAIResponseChoiceCopyWithImpl(this._self, this._then);

  final _OpenAIResponseChoice _self;
  final $Res Function(_OpenAIResponseChoice) _then;

/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? message = freezed,Object? finishReason = freezed,Object? text = freezed,Object? reasoning = freezed,}) {
  return _then(_OpenAIResponseChoice(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as OpenAIResponseMessage?,finishReason: freezed == finishReason ? _self.finishReason : finishReason // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text ,reasoning: freezed == reasoning ? _self.reasoning : reasoning ,
  ));
}

/// Create a copy of OpenAIResponseChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenAIResponseMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $OpenAIResponseMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// @nodoc
mixin _$OpenAIResponseMessage {

 String get role;@JsonKey(readValue: _readContentRaw) Object? get content;@JsonKey(readValue: _readReasoningRaw) Object? get reasoningContent;@JsonKey(name: 'tool_calls') List<dynamic>? get toolCalls;
/// Create a copy of OpenAIResponseMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAIResponseMessageCopyWith<OpenAIResponseMessage> get copyWith => _$OpenAIResponseMessageCopyWithImpl<OpenAIResponseMessage>(this as OpenAIResponseMessage, _$identity);

  /// Serializes this OpenAIResponseMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAIResponseMessage&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.reasoningContent, reasoningContent)&&const DeepCollectionEquality().equals(other.toolCalls, toolCalls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(reasoningContent),const DeepCollectionEquality().hash(toolCalls));

@override
String toString() {
  return 'OpenAIResponseMessage(role: $role, content: $content, reasoningContent: $reasoningContent, toolCalls: $toolCalls)';
}


}

/// @nodoc
abstract mixin class $OpenAIResponseMessageCopyWith<$Res>  {
  factory $OpenAIResponseMessageCopyWith(OpenAIResponseMessage value, $Res Function(OpenAIResponseMessage) _then) = _$OpenAIResponseMessageCopyWithImpl;
@useResult
$Res call({
 String role,@JsonKey(readValue: _readContentRaw) Object? content,@JsonKey(readValue: _readReasoningRaw) Object? reasoningContent,@JsonKey(name: 'tool_calls') List<dynamic>? toolCalls
});




}
/// @nodoc
class _$OpenAIResponseMessageCopyWithImpl<$Res>
    implements $OpenAIResponseMessageCopyWith<$Res> {
  _$OpenAIResponseMessageCopyWithImpl(this._self, this._then);

  final OpenAIResponseMessage _self;
  final $Res Function(OpenAIResponseMessage) _then;

/// Create a copy of OpenAIResponseMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? content = freezed,Object? reasoningContent = freezed,Object? toolCalls = freezed,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content ,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent ,toolCalls: freezed == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAIResponseMessage].
extension OpenAIResponseMessagePatterns on OpenAIResponseMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAIResponseMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAIResponseMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAIResponseMessage value)  $default,){
final _that = this;
switch (_that) {
case _OpenAIResponseMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAIResponseMessage value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAIResponseMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role, @JsonKey(readValue: _readContentRaw)  Object? content, @JsonKey(readValue: _readReasoningRaw)  Object? reasoningContent, @JsonKey(name: 'tool_calls')  List<dynamic>? toolCalls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAIResponseMessage() when $default != null:
return $default(_that.role,_that.content,_that.reasoningContent,_that.toolCalls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role, @JsonKey(readValue: _readContentRaw)  Object? content, @JsonKey(readValue: _readReasoningRaw)  Object? reasoningContent, @JsonKey(name: 'tool_calls')  List<dynamic>? toolCalls)  $default,) {final _that = this;
switch (_that) {
case _OpenAIResponseMessage():
return $default(_that.role,_that.content,_that.reasoningContent,_that.toolCalls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role, @JsonKey(readValue: _readContentRaw)  Object? content, @JsonKey(readValue: _readReasoningRaw)  Object? reasoningContent, @JsonKey(name: 'tool_calls')  List<dynamic>? toolCalls)?  $default,) {final _that = this;
switch (_that) {
case _OpenAIResponseMessage() when $default != null:
return $default(_that.role,_that.content,_that.reasoningContent,_that.toolCalls);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenAIResponseMessage extends OpenAIResponseMessage {
  const _OpenAIResponseMessage({this.role = 'assistant', @JsonKey(readValue: _readContentRaw) this.content, @JsonKey(readValue: _readReasoningRaw) this.reasoningContent, @JsonKey(name: 'tool_calls') final  List<dynamic>? toolCalls}): _toolCalls = toolCalls,super._();
  factory _OpenAIResponseMessage.fromJson(Map<String, dynamic> json) => _$OpenAIResponseMessageFromJson(json);

@override@JsonKey() final  String role;
@override@JsonKey(readValue: _readContentRaw) final  Object? content;
@override@JsonKey(readValue: _readReasoningRaw) final  Object? reasoningContent;
 final  List<dynamic>? _toolCalls;
@override@JsonKey(name: 'tool_calls') List<dynamic>? get toolCalls {
  final value = _toolCalls;
  if (value == null) return null;
  if (_toolCalls is EqualUnmodifiableListView) return _toolCalls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of OpenAIResponseMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAIResponseMessageCopyWith<_OpenAIResponseMessage> get copyWith => __$OpenAIResponseMessageCopyWithImpl<_OpenAIResponseMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenAIResponseMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAIResponseMessage&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.reasoningContent, reasoningContent)&&const DeepCollectionEquality().equals(other._toolCalls, _toolCalls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(reasoningContent),const DeepCollectionEquality().hash(_toolCalls));

@override
String toString() {
  return 'OpenAIResponseMessage(role: $role, content: $content, reasoningContent: $reasoningContent, toolCalls: $toolCalls)';
}


}

/// @nodoc
abstract mixin class _$OpenAIResponseMessageCopyWith<$Res> implements $OpenAIResponseMessageCopyWith<$Res> {
  factory _$OpenAIResponseMessageCopyWith(_OpenAIResponseMessage value, $Res Function(_OpenAIResponseMessage) _then) = __$OpenAIResponseMessageCopyWithImpl;
@override @useResult
$Res call({
 String role,@JsonKey(readValue: _readContentRaw) Object? content,@JsonKey(readValue: _readReasoningRaw) Object? reasoningContent,@JsonKey(name: 'tool_calls') List<dynamic>? toolCalls
});




}
/// @nodoc
class __$OpenAIResponseMessageCopyWithImpl<$Res>
    implements _$OpenAIResponseMessageCopyWith<$Res> {
  __$OpenAIResponseMessageCopyWithImpl(this._self, this._then);

  final _OpenAIResponseMessage _self;
  final $Res Function(_OpenAIResponseMessage) _then;

/// Create a copy of OpenAIResponseMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? content = freezed,Object? reasoningContent = freezed,Object? toolCalls = freezed,}) {
  return _then(_OpenAIResponseMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content ,reasoningContent: freezed == reasoningContent ? _self.reasoningContent : reasoningContent ,toolCalls: freezed == toolCalls ? _self._toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,
  ));
}


}

// dart format on
