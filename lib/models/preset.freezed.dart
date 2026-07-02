// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresetPrompt {

 String get identifier; String get name; String get content; String get role; bool get systemPrompt; bool get marker; bool get enabled; String get injectionPosition; int get injectionDepth; int get injectionOrder;@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra;
/// Create a copy of PresetPrompt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetPromptCopyWith<PresetPrompt> get copyWith => _$PresetPromptCopyWithImpl<PresetPrompt>(this as PresetPrompt, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetPrompt&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.role, role) || other.role == role)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.marker, marker) || other.marker == marker)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.injectionPosition, injectionPosition) || other.injectionPosition == injectionPosition)&&(identical(other.injectionDepth, injectionDepth) || other.injectionDepth == injectionDepth)&&(identical(other.injectionOrder, injectionOrder) || other.injectionOrder == injectionOrder)&&const DeepCollectionEquality().equals(other.extra, extra));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,name,content,role,systemPrompt,marker,enabled,injectionPosition,injectionDepth,injectionOrder,const DeepCollectionEquality().hash(extra));

@override
String toString() {
  return 'PresetPrompt(identifier: $identifier, name: $name, content: $content, role: $role, systemPrompt: $systemPrompt, marker: $marker, enabled: $enabled, injectionPosition: $injectionPosition, injectionDepth: $injectionDepth, injectionOrder: $injectionOrder, extra: $extra)';
}


}

/// @nodoc
abstract mixin class $PresetPromptCopyWith<$Res>  {
  factory $PresetPromptCopyWith(PresetPrompt value, $Res Function(PresetPrompt) _then) = _$PresetPromptCopyWithImpl;
@useResult
$Res call({
 String identifier, String name, String content, String role, bool systemPrompt, bool marker, bool enabled, String injectionPosition, int injectionDepth, int injectionOrder,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class _$PresetPromptCopyWithImpl<$Res>
    implements $PresetPromptCopyWith<$Res> {
  _$PresetPromptCopyWithImpl(this._self, this._then);

  final PresetPrompt _self;
  final $Res Function(PresetPrompt) _then;

/// Create a copy of PresetPrompt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identifier = null,Object? name = null,Object? content = null,Object? role = null,Object? systemPrompt = null,Object? marker = null,Object? enabled = null,Object? injectionPosition = null,Object? injectionDepth = null,Object? injectionOrder = null,Object? extra = null,}) {
  return _then(_self.copyWith(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as bool,marker: null == marker ? _self.marker : marker // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,injectionPosition: null == injectionPosition ? _self.injectionPosition : injectionPosition // ignore: cast_nullable_to_non_nullable
as String,injectionDepth: null == injectionDepth ? _self.injectionDepth : injectionDepth // ignore: cast_nullable_to_non_nullable
as int,injectionOrder: null == injectionOrder ? _self.injectionOrder : injectionOrder // ignore: cast_nullable_to_non_nullable
as int,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetPrompt].
extension PresetPromptPatterns on PresetPrompt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetPrompt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetPrompt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetPrompt value)  $default,){
final _that = this;
switch (_that) {
case _PresetPrompt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetPrompt value)?  $default,){
final _that = this;
switch (_that) {
case _PresetPrompt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String identifier,  String name,  String content,  String role,  bool systemPrompt,  bool marker,  bool enabled,  String injectionPosition,  int injectionDepth,  int injectionOrder, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetPrompt() when $default != null:
return $default(_that.identifier,_that.name,_that.content,_that.role,_that.systemPrompt,_that.marker,_that.enabled,_that.injectionPosition,_that.injectionDepth,_that.injectionOrder,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String identifier,  String name,  String content,  String role,  bool systemPrompt,  bool marker,  bool enabled,  String injectionPosition,  int injectionDepth,  int injectionOrder, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _PresetPrompt():
return $default(_that.identifier,_that.name,_that.content,_that.role,_that.systemPrompt,_that.marker,_that.enabled,_that.injectionPosition,_that.injectionDepth,_that.injectionOrder,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String identifier,  String name,  String content,  String role,  bool systemPrompt,  bool marker,  bool enabled,  String injectionPosition,  int injectionDepth,  int injectionOrder, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _PresetPrompt() when $default != null:
return $default(_that.identifier,_that.name,_that.content,_that.role,_that.systemPrompt,_that.marker,_that.enabled,_that.injectionPosition,_that.injectionDepth,_that.injectionOrder,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _PresetPrompt extends PresetPrompt {
  const _PresetPrompt({required this.identifier, required this.name, this.content = '', this.role = 'system', this.systemPrompt = true, this.marker = false, this.enabled = true, this.injectionPosition = PresetInjectionPosition.relative, this.injectionDepth = 4, this.injectionOrder = 100, @JsonKey(includeToJson: false, includeFromJson: false) final  Map<String, dynamic> extra = const {}}): _extra = extra,super._();
  

@override final  String identifier;
@override final  String name;
@override@JsonKey() final  String content;
@override@JsonKey() final  String role;
@override@JsonKey() final  bool systemPrompt;
@override@JsonKey() final  bool marker;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String injectionPosition;
@override@JsonKey() final  int injectionDepth;
@override@JsonKey() final  int injectionOrder;
 final  Map<String, dynamic> _extra;
@override@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of PresetPrompt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetPromptCopyWith<_PresetPrompt> get copyWith => __$PresetPromptCopyWithImpl<_PresetPrompt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetPrompt&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.role, role) || other.role == role)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.marker, marker) || other.marker == marker)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.injectionPosition, injectionPosition) || other.injectionPosition == injectionPosition)&&(identical(other.injectionDepth, injectionDepth) || other.injectionDepth == injectionDepth)&&(identical(other.injectionOrder, injectionOrder) || other.injectionOrder == injectionOrder)&&const DeepCollectionEquality().equals(other._extra, _extra));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,name,content,role,systemPrompt,marker,enabled,injectionPosition,injectionDepth,injectionOrder,const DeepCollectionEquality().hash(_extra));

@override
String toString() {
  return 'PresetPrompt(identifier: $identifier, name: $name, content: $content, role: $role, systemPrompt: $systemPrompt, marker: $marker, enabled: $enabled, injectionPosition: $injectionPosition, injectionDepth: $injectionDepth, injectionOrder: $injectionOrder, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$PresetPromptCopyWith<$Res> implements $PresetPromptCopyWith<$Res> {
  factory _$PresetPromptCopyWith(_PresetPrompt value, $Res Function(_PresetPrompt) _then) = __$PresetPromptCopyWithImpl;
@override @useResult
$Res call({
 String identifier, String name, String content, String role, bool systemPrompt, bool marker, bool enabled, String injectionPosition, int injectionDepth, int injectionOrder,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class __$PresetPromptCopyWithImpl<$Res>
    implements _$PresetPromptCopyWith<$Res> {
  __$PresetPromptCopyWithImpl(this._self, this._then);

  final _PresetPrompt _self;
  final $Res Function(_PresetPrompt) _then;

/// Create a copy of PresetPrompt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identifier = null,Object? name = null,Object? content = null,Object? role = null,Object? systemPrompt = null,Object? marker = null,Object? enabled = null,Object? injectionPosition = null,Object? injectionDepth = null,Object? injectionOrder = null,Object? extra = null,}) {
  return _then(_PresetPrompt(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as bool,marker: null == marker ? _self.marker : marker // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,injectionPosition: null == injectionPosition ? _self.injectionPosition : injectionPosition // ignore: cast_nullable_to_non_nullable
as String,injectionDepth: null == injectionDepth ? _self.injectionDepth : injectionDepth // ignore: cast_nullable_to_non_nullable
as int,injectionOrder: null == injectionOrder ? _self.injectionOrder : injectionOrder // ignore: cast_nullable_to_non_nullable
as int,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$PresetPromptOrderEntry {

 String get identifier; bool get enabled;@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra;
/// Create a copy of PresetPromptOrderEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetPromptOrderEntryCopyWith<PresetPromptOrderEntry> get copyWith => _$PresetPromptOrderEntryCopyWithImpl<PresetPromptOrderEntry>(this as PresetPromptOrderEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetPromptOrderEntry&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.extra, extra));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,enabled,const DeepCollectionEquality().hash(extra));

@override
String toString() {
  return 'PresetPromptOrderEntry(identifier: $identifier, enabled: $enabled, extra: $extra)';
}


}

/// @nodoc
abstract mixin class $PresetPromptOrderEntryCopyWith<$Res>  {
  factory $PresetPromptOrderEntryCopyWith(PresetPromptOrderEntry value, $Res Function(PresetPromptOrderEntry) _then) = _$PresetPromptOrderEntryCopyWithImpl;
@useResult
$Res call({
 String identifier, bool enabled,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class _$PresetPromptOrderEntryCopyWithImpl<$Res>
    implements $PresetPromptOrderEntryCopyWith<$Res> {
  _$PresetPromptOrderEntryCopyWithImpl(this._self, this._then);

  final PresetPromptOrderEntry _self;
  final $Res Function(PresetPromptOrderEntry) _then;

/// Create a copy of PresetPromptOrderEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identifier = null,Object? enabled = null,Object? extra = null,}) {
  return _then(_self.copyWith(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetPromptOrderEntry].
extension PresetPromptOrderEntryPatterns on PresetPromptOrderEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetPromptOrderEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetPromptOrderEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetPromptOrderEntry value)  $default,){
final _that = this;
switch (_that) {
case _PresetPromptOrderEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetPromptOrderEntry value)?  $default,){
final _that = this;
switch (_that) {
case _PresetPromptOrderEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String identifier,  bool enabled, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetPromptOrderEntry() when $default != null:
return $default(_that.identifier,_that.enabled,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String identifier,  bool enabled, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _PresetPromptOrderEntry():
return $default(_that.identifier,_that.enabled,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String identifier,  bool enabled, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _PresetPromptOrderEntry() when $default != null:
return $default(_that.identifier,_that.enabled,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _PresetPromptOrderEntry extends PresetPromptOrderEntry {
  const _PresetPromptOrderEntry({required this.identifier, this.enabled = true, @JsonKey(includeToJson: false, includeFromJson: false) final  Map<String, dynamic> extra = const {}}): _extra = extra,super._();
  

@override final  String identifier;
@override@JsonKey() final  bool enabled;
 final  Map<String, dynamic> _extra;
@override@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of PresetPromptOrderEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetPromptOrderEntryCopyWith<_PresetPromptOrderEntry> get copyWith => __$PresetPromptOrderEntryCopyWithImpl<_PresetPromptOrderEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetPromptOrderEntry&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._extra, _extra));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,enabled,const DeepCollectionEquality().hash(_extra));

@override
String toString() {
  return 'PresetPromptOrderEntry(identifier: $identifier, enabled: $enabled, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$PresetPromptOrderEntryCopyWith<$Res> implements $PresetPromptOrderEntryCopyWith<$Res> {
  factory _$PresetPromptOrderEntryCopyWith(_PresetPromptOrderEntry value, $Res Function(_PresetPromptOrderEntry) _then) = __$PresetPromptOrderEntryCopyWithImpl;
@override @useResult
$Res call({
 String identifier, bool enabled,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class __$PresetPromptOrderEntryCopyWithImpl<$Res>
    implements _$PresetPromptOrderEntryCopyWith<$Res> {
  __$PresetPromptOrderEntryCopyWithImpl(this._self, this._then);

  final _PresetPromptOrderEntry _self;
  final $Res Function(_PresetPromptOrderEntry) _then;

/// Create a copy of PresetPromptOrderEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identifier = null,Object? enabled = null,Object? extra = null,}) {
  return _then(_PresetPromptOrderEntry(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$PresetPromptOrderGroup {

 String get characterId; List<PresetPromptOrderEntry> get order;@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra;
/// Create a copy of PresetPromptOrderGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetPromptOrderGroupCopyWith<PresetPromptOrderGroup> get copyWith => _$PresetPromptOrderGroupCopyWithImpl<PresetPromptOrderGroup>(this as PresetPromptOrderGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetPromptOrderGroup&&(identical(other.characterId, characterId) || other.characterId == characterId)&&const DeepCollectionEquality().equals(other.order, order)&&const DeepCollectionEquality().equals(other.extra, extra));
}


@override
int get hashCode => Object.hash(runtimeType,characterId,const DeepCollectionEquality().hash(order),const DeepCollectionEquality().hash(extra));

@override
String toString() {
  return 'PresetPromptOrderGroup(characterId: $characterId, order: $order, extra: $extra)';
}


}

/// @nodoc
abstract mixin class $PresetPromptOrderGroupCopyWith<$Res>  {
  factory $PresetPromptOrderGroupCopyWith(PresetPromptOrderGroup value, $Res Function(PresetPromptOrderGroup) _then) = _$PresetPromptOrderGroupCopyWithImpl;
@useResult
$Res call({
 String characterId, List<PresetPromptOrderEntry> order,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class _$PresetPromptOrderGroupCopyWithImpl<$Res>
    implements $PresetPromptOrderGroupCopyWith<$Res> {
  _$PresetPromptOrderGroupCopyWithImpl(this._self, this._then);

  final PresetPromptOrderGroup _self;
  final $Res Function(PresetPromptOrderGroup) _then;

/// Create a copy of PresetPromptOrderGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? characterId = null,Object? order = null,Object? extra = null,}) {
  return _then(_self.copyWith(
characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as List<PresetPromptOrderEntry>,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetPromptOrderGroup].
extension PresetPromptOrderGroupPatterns on PresetPromptOrderGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetPromptOrderGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetPromptOrderGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetPromptOrderGroup value)  $default,){
final _that = this;
switch (_that) {
case _PresetPromptOrderGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetPromptOrderGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PresetPromptOrderGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String characterId,  List<PresetPromptOrderEntry> order, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetPromptOrderGroup() when $default != null:
return $default(_that.characterId,_that.order,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String characterId,  List<PresetPromptOrderEntry> order, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _PresetPromptOrderGroup():
return $default(_that.characterId,_that.order,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String characterId,  List<PresetPromptOrderEntry> order, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _PresetPromptOrderGroup() when $default != null:
return $default(_that.characterId,_that.order,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _PresetPromptOrderGroup extends PresetPromptOrderGroup {
  const _PresetPromptOrderGroup({required this.characterId, final  List<PresetPromptOrderEntry> order = const [], @JsonKey(includeToJson: false, includeFromJson: false) final  Map<String, dynamic> extra = const {}}): _order = order,_extra = extra,super._();
  

@override final  String characterId;
 final  List<PresetPromptOrderEntry> _order;
@override@JsonKey() List<PresetPromptOrderEntry> get order {
  if (_order is EqualUnmodifiableListView) return _order;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_order);
}

 final  Map<String, dynamic> _extra;
@override@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of PresetPromptOrderGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetPromptOrderGroupCopyWith<_PresetPromptOrderGroup> get copyWith => __$PresetPromptOrderGroupCopyWithImpl<_PresetPromptOrderGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetPromptOrderGroup&&(identical(other.characterId, characterId) || other.characterId == characterId)&&const DeepCollectionEquality().equals(other._order, _order)&&const DeepCollectionEquality().equals(other._extra, _extra));
}


@override
int get hashCode => Object.hash(runtimeType,characterId,const DeepCollectionEquality().hash(_order),const DeepCollectionEquality().hash(_extra));

@override
String toString() {
  return 'PresetPromptOrderGroup(characterId: $characterId, order: $order, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$PresetPromptOrderGroupCopyWith<$Res> implements $PresetPromptOrderGroupCopyWith<$Res> {
  factory _$PresetPromptOrderGroupCopyWith(_PresetPromptOrderGroup value, $Res Function(_PresetPromptOrderGroup) _then) = __$PresetPromptOrderGroupCopyWithImpl;
@override @useResult
$Res call({
 String characterId, List<PresetPromptOrderEntry> order,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class __$PresetPromptOrderGroupCopyWithImpl<$Res>
    implements _$PresetPromptOrderGroupCopyWith<$Res> {
  __$PresetPromptOrderGroupCopyWithImpl(this._self, this._then);

  final _PresetPromptOrderGroup _self;
  final $Res Function(_PresetPromptOrderGroup) _then;

/// Create a copy of PresetPromptOrderGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? characterId = null,Object? order = null,Object? extra = null,}) {
  return _then(_PresetPromptOrderGroup(
characterId: null == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self._order : order // ignore: cast_nullable_to_non_nullable
as List<PresetPromptOrderEntry>,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$Preset {

 String get id; String get name; bool get isBuiltin; double get temperature; double get frequencyPenalty; double get presencePenalty; double get topP; int get topK; double get topA; double get minP; double get repetitionPenalty; int get openaiMaxContext; int get openaiMaxTokens; List<PresetPrompt> get prompts; List<PresetPromptOrderGroup> get promptOrderGroups; String? get activePromptOrderCharacterId; DateTime get updatedAt;@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra;
/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetCopyWith<Preset> get copyWith => _$PresetCopyWithImpl<Preset>(this as Preset, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Preset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.frequencyPenalty, frequencyPenalty) || other.frequencyPenalty == frequencyPenalty)&&(identical(other.presencePenalty, presencePenalty) || other.presencePenalty == presencePenalty)&&(identical(other.topP, topP) || other.topP == topP)&&(identical(other.topK, topK) || other.topK == topK)&&(identical(other.topA, topA) || other.topA == topA)&&(identical(other.minP, minP) || other.minP == minP)&&(identical(other.repetitionPenalty, repetitionPenalty) || other.repetitionPenalty == repetitionPenalty)&&(identical(other.openaiMaxContext, openaiMaxContext) || other.openaiMaxContext == openaiMaxContext)&&(identical(other.openaiMaxTokens, openaiMaxTokens) || other.openaiMaxTokens == openaiMaxTokens)&&const DeepCollectionEquality().equals(other.prompts, prompts)&&const DeepCollectionEquality().equals(other.promptOrderGroups, promptOrderGroups)&&(identical(other.activePromptOrderCharacterId, activePromptOrderCharacterId) || other.activePromptOrderCharacterId == activePromptOrderCharacterId)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.extra, extra));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isBuiltin,temperature,frequencyPenalty,presencePenalty,topP,topK,topA,minP,repetitionPenalty,openaiMaxContext,openaiMaxTokens,const DeepCollectionEquality().hash(prompts),const DeepCollectionEquality().hash(promptOrderGroups),activePromptOrderCharacterId,updatedAt,const DeepCollectionEquality().hash(extra));

@override
String toString() {
  return 'Preset(id: $id, name: $name, isBuiltin: $isBuiltin, temperature: $temperature, frequencyPenalty: $frequencyPenalty, presencePenalty: $presencePenalty, topP: $topP, topK: $topK, topA: $topA, minP: $minP, repetitionPenalty: $repetitionPenalty, openaiMaxContext: $openaiMaxContext, openaiMaxTokens: $openaiMaxTokens, prompts: $prompts, promptOrderGroups: $promptOrderGroups, activePromptOrderCharacterId: $activePromptOrderCharacterId, updatedAt: $updatedAt, extra: $extra)';
}


}

/// @nodoc
abstract mixin class $PresetCopyWith<$Res>  {
  factory $PresetCopyWith(Preset value, $Res Function(Preset) _then) = _$PresetCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isBuiltin, double temperature, double frequencyPenalty, double presencePenalty, double topP, int topK, double topA, double minP, double repetitionPenalty, int openaiMaxContext, int openaiMaxTokens, List<PresetPrompt> prompts, List<PresetPromptOrderGroup> promptOrderGroups, String? activePromptOrderCharacterId, DateTime updatedAt,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class _$PresetCopyWithImpl<$Res>
    implements $PresetCopyWith<$Res> {
  _$PresetCopyWithImpl(this._self, this._then);

  final Preset _self;
  final $Res Function(Preset) _then;

/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isBuiltin = null,Object? temperature = null,Object? frequencyPenalty = null,Object? presencePenalty = null,Object? topP = null,Object? topK = null,Object? topA = null,Object? minP = null,Object? repetitionPenalty = null,Object? openaiMaxContext = null,Object? openaiMaxTokens = null,Object? prompts = null,Object? promptOrderGroups = null,Object? activePromptOrderCharacterId = freezed,Object? updatedAt = null,Object? extra = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,frequencyPenalty: null == frequencyPenalty ? _self.frequencyPenalty : frequencyPenalty // ignore: cast_nullable_to_non_nullable
as double,presencePenalty: null == presencePenalty ? _self.presencePenalty : presencePenalty // ignore: cast_nullable_to_non_nullable
as double,topP: null == topP ? _self.topP : topP // ignore: cast_nullable_to_non_nullable
as double,topK: null == topK ? _self.topK : topK // ignore: cast_nullable_to_non_nullable
as int,topA: null == topA ? _self.topA : topA // ignore: cast_nullable_to_non_nullable
as double,minP: null == minP ? _self.minP : minP // ignore: cast_nullable_to_non_nullable
as double,repetitionPenalty: null == repetitionPenalty ? _self.repetitionPenalty : repetitionPenalty // ignore: cast_nullable_to_non_nullable
as double,openaiMaxContext: null == openaiMaxContext ? _self.openaiMaxContext : openaiMaxContext // ignore: cast_nullable_to_non_nullable
as int,openaiMaxTokens: null == openaiMaxTokens ? _self.openaiMaxTokens : openaiMaxTokens // ignore: cast_nullable_to_non_nullable
as int,prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as List<PresetPrompt>,promptOrderGroups: null == promptOrderGroups ? _self.promptOrderGroups : promptOrderGroups // ignore: cast_nullable_to_non_nullable
as List<PresetPromptOrderGroup>,activePromptOrderCharacterId: freezed == activePromptOrderCharacterId ? _self.activePromptOrderCharacterId : activePromptOrderCharacterId // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Preset].
extension PresetPatterns on Preset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Preset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Preset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Preset value)  $default,){
final _that = this;
switch (_that) {
case _Preset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Preset value)?  $default,){
final _that = this;
switch (_that) {
case _Preset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuiltin,  double temperature,  double frequencyPenalty,  double presencePenalty,  double topP,  int topK,  double topA,  double minP,  double repetitionPenalty,  int openaiMaxContext,  int openaiMaxTokens,  List<PresetPrompt> prompts,  List<PresetPromptOrderGroup> promptOrderGroups,  String? activePromptOrderCharacterId,  DateTime updatedAt, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Preset() when $default != null:
return $default(_that.id,_that.name,_that.isBuiltin,_that.temperature,_that.frequencyPenalty,_that.presencePenalty,_that.topP,_that.topK,_that.topA,_that.minP,_that.repetitionPenalty,_that.openaiMaxContext,_that.openaiMaxTokens,_that.prompts,_that.promptOrderGroups,_that.activePromptOrderCharacterId,_that.updatedAt,_that.extra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuiltin,  double temperature,  double frequencyPenalty,  double presencePenalty,  double topP,  int topK,  double topA,  double minP,  double repetitionPenalty,  int openaiMaxContext,  int openaiMaxTokens,  List<PresetPrompt> prompts,  List<PresetPromptOrderGroup> promptOrderGroups,  String? activePromptOrderCharacterId,  DateTime updatedAt, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)  $default,) {final _that = this;
switch (_that) {
case _Preset():
return $default(_that.id,_that.name,_that.isBuiltin,_that.temperature,_that.frequencyPenalty,_that.presencePenalty,_that.topP,_that.topK,_that.topA,_that.minP,_that.repetitionPenalty,_that.openaiMaxContext,_that.openaiMaxTokens,_that.prompts,_that.promptOrderGroups,_that.activePromptOrderCharacterId,_that.updatedAt,_that.extra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isBuiltin,  double temperature,  double frequencyPenalty,  double presencePenalty,  double topP,  int topK,  double topA,  double minP,  double repetitionPenalty,  int openaiMaxContext,  int openaiMaxTokens,  List<PresetPrompt> prompts,  List<PresetPromptOrderGroup> promptOrderGroups,  String? activePromptOrderCharacterId,  DateTime updatedAt, @JsonKey(includeToJson: false, includeFromJson: false)  Map<String, dynamic> extra)?  $default,) {final _that = this;
switch (_that) {
case _Preset() when $default != null:
return $default(_that.id,_that.name,_that.isBuiltin,_that.temperature,_that.frequencyPenalty,_that.presencePenalty,_that.topP,_that.topK,_that.topA,_that.minP,_that.repetitionPenalty,_that.openaiMaxContext,_that.openaiMaxTokens,_that.prompts,_that.promptOrderGroups,_that.activePromptOrderCharacterId,_that.updatedAt,_that.extra);case _:
  return null;

}
}

}

/// @nodoc


class _Preset extends Preset {
  const _Preset({required this.id, required this.name, this.isBuiltin = false, this.temperature = 1.0, this.frequencyPenalty = 0.0, this.presencePenalty = 0.0, this.topP = 1.0, this.topK = 0, this.topA = 0.0, this.minP = 0.0, this.repetitionPenalty = 1.0, this.openaiMaxContext = 131072, this.openaiMaxTokens = 32768, final  List<PresetPrompt> prompts = const [], final  List<PresetPromptOrderGroup> promptOrderGroups = const [], this.activePromptOrderCharacterId, required this.updatedAt, @JsonKey(includeToJson: false, includeFromJson: false) final  Map<String, dynamic> extra = const {}}): _prompts = prompts,_promptOrderGroups = promptOrderGroups,_extra = extra,super._();
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool isBuiltin;
@override@JsonKey() final  double temperature;
@override@JsonKey() final  double frequencyPenalty;
@override@JsonKey() final  double presencePenalty;
@override@JsonKey() final  double topP;
@override@JsonKey() final  int topK;
@override@JsonKey() final  double topA;
@override@JsonKey() final  double minP;
@override@JsonKey() final  double repetitionPenalty;
@override@JsonKey() final  int openaiMaxContext;
@override@JsonKey() final  int openaiMaxTokens;
 final  List<PresetPrompt> _prompts;
@override@JsonKey() List<PresetPrompt> get prompts {
  if (_prompts is EqualUnmodifiableListView) return _prompts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prompts);
}

 final  List<PresetPromptOrderGroup> _promptOrderGroups;
@override@JsonKey() List<PresetPromptOrderGroup> get promptOrderGroups {
  if (_promptOrderGroups is EqualUnmodifiableListView) return _promptOrderGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_promptOrderGroups);
}

@override final  String? activePromptOrderCharacterId;
@override final  DateTime updatedAt;
 final  Map<String, dynamic> _extra;
@override@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}


/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetCopyWith<_Preset> get copyWith => __$PresetCopyWithImpl<_Preset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Preset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.frequencyPenalty, frequencyPenalty) || other.frequencyPenalty == frequencyPenalty)&&(identical(other.presencePenalty, presencePenalty) || other.presencePenalty == presencePenalty)&&(identical(other.topP, topP) || other.topP == topP)&&(identical(other.topK, topK) || other.topK == topK)&&(identical(other.topA, topA) || other.topA == topA)&&(identical(other.minP, minP) || other.minP == minP)&&(identical(other.repetitionPenalty, repetitionPenalty) || other.repetitionPenalty == repetitionPenalty)&&(identical(other.openaiMaxContext, openaiMaxContext) || other.openaiMaxContext == openaiMaxContext)&&(identical(other.openaiMaxTokens, openaiMaxTokens) || other.openaiMaxTokens == openaiMaxTokens)&&const DeepCollectionEquality().equals(other._prompts, _prompts)&&const DeepCollectionEquality().equals(other._promptOrderGroups, _promptOrderGroups)&&(identical(other.activePromptOrderCharacterId, activePromptOrderCharacterId) || other.activePromptOrderCharacterId == activePromptOrderCharacterId)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._extra, _extra));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isBuiltin,temperature,frequencyPenalty,presencePenalty,topP,topK,topA,minP,repetitionPenalty,openaiMaxContext,openaiMaxTokens,const DeepCollectionEquality().hash(_prompts),const DeepCollectionEquality().hash(_promptOrderGroups),activePromptOrderCharacterId,updatedAt,const DeepCollectionEquality().hash(_extra));

@override
String toString() {
  return 'Preset(id: $id, name: $name, isBuiltin: $isBuiltin, temperature: $temperature, frequencyPenalty: $frequencyPenalty, presencePenalty: $presencePenalty, topP: $topP, topK: $topK, topA: $topA, minP: $minP, repetitionPenalty: $repetitionPenalty, openaiMaxContext: $openaiMaxContext, openaiMaxTokens: $openaiMaxTokens, prompts: $prompts, promptOrderGroups: $promptOrderGroups, activePromptOrderCharacterId: $activePromptOrderCharacterId, updatedAt: $updatedAt, extra: $extra)';
}


}

/// @nodoc
abstract mixin class _$PresetCopyWith<$Res> implements $PresetCopyWith<$Res> {
  factory _$PresetCopyWith(_Preset value, $Res Function(_Preset) _then) = __$PresetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isBuiltin, double temperature, double frequencyPenalty, double presencePenalty, double topP, int topK, double topA, double minP, double repetitionPenalty, int openaiMaxContext, int openaiMaxTokens, List<PresetPrompt> prompts, List<PresetPromptOrderGroup> promptOrderGroups, String? activePromptOrderCharacterId, DateTime updatedAt,@JsonKey(includeToJson: false, includeFromJson: false) Map<String, dynamic> extra
});




}
/// @nodoc
class __$PresetCopyWithImpl<$Res>
    implements _$PresetCopyWith<$Res> {
  __$PresetCopyWithImpl(this._self, this._then);

  final _Preset _self;
  final $Res Function(_Preset) _then;

/// Create a copy of Preset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isBuiltin = null,Object? temperature = null,Object? frequencyPenalty = null,Object? presencePenalty = null,Object? topP = null,Object? topK = null,Object? topA = null,Object? minP = null,Object? repetitionPenalty = null,Object? openaiMaxContext = null,Object? openaiMaxTokens = null,Object? prompts = null,Object? promptOrderGroups = null,Object? activePromptOrderCharacterId = freezed,Object? updatedAt = null,Object? extra = null,}) {
  return _then(_Preset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,frequencyPenalty: null == frequencyPenalty ? _self.frequencyPenalty : frequencyPenalty // ignore: cast_nullable_to_non_nullable
as double,presencePenalty: null == presencePenalty ? _self.presencePenalty : presencePenalty // ignore: cast_nullable_to_non_nullable
as double,topP: null == topP ? _self.topP : topP // ignore: cast_nullable_to_non_nullable
as double,topK: null == topK ? _self.topK : topK // ignore: cast_nullable_to_non_nullable
as int,topA: null == topA ? _self.topA : topA // ignore: cast_nullable_to_non_nullable
as double,minP: null == minP ? _self.minP : minP // ignore: cast_nullable_to_non_nullable
as double,repetitionPenalty: null == repetitionPenalty ? _self.repetitionPenalty : repetitionPenalty // ignore: cast_nullable_to_non_nullable
as double,openaiMaxContext: null == openaiMaxContext ? _self.openaiMaxContext : openaiMaxContext // ignore: cast_nullable_to_non_nullable
as int,openaiMaxTokens: null == openaiMaxTokens ? _self.openaiMaxTokens : openaiMaxTokens // ignore: cast_nullable_to_non_nullable
as int,prompts: null == prompts ? _self._prompts : prompts // ignore: cast_nullable_to_non_nullable
as List<PresetPrompt>,promptOrderGroups: null == promptOrderGroups ? _self._promptOrderGroups : promptOrderGroups // ignore: cast_nullable_to_non_nullable
as List<PresetPromptOrderGroup>,activePromptOrderCharacterId: freezed == activePromptOrderCharacterId ? _self.activePromptOrderCharacterId : activePromptOrderCharacterId // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$PresetSummary {

 String get id; String get name; bool get isBuiltin; DateTime get updatedAt;
/// Create a copy of PresetSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetSummaryCopyWith<PresetSummary> get copyWith => _$PresetSummaryCopyWithImpl<PresetSummary>(this as PresetSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isBuiltin,updatedAt);

@override
String toString() {
  return 'PresetSummary(id: $id, name: $name, isBuiltin: $isBuiltin, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PresetSummaryCopyWith<$Res>  {
  factory $PresetSummaryCopyWith(PresetSummary value, $Res Function(PresetSummary) _then) = _$PresetSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isBuiltin, DateTime updatedAt
});




}
/// @nodoc
class _$PresetSummaryCopyWithImpl<$Res>
    implements $PresetSummaryCopyWith<$Res> {
  _$PresetSummaryCopyWithImpl(this._self, this._then);

  final PresetSummary _self;
  final $Res Function(PresetSummary) _then;

/// Create a copy of PresetSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isBuiltin = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetSummary].
extension PresetSummaryPatterns on PresetSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetSummary value)  $default,){
final _that = this;
switch (_that) {
case _PresetSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PresetSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuiltin,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetSummary() when $default != null:
return $default(_that.id,_that.name,_that.isBuiltin,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isBuiltin,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PresetSummary():
return $default(_that.id,_that.name,_that.isBuiltin,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isBuiltin,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PresetSummary() when $default != null:
return $default(_that.id,_that.name,_that.isBuiltin,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PresetSummary extends PresetSummary {
  const _PresetSummary({required this.id, required this.name, required this.isBuiltin, required this.updatedAt}): super._();
  

@override final  String id;
@override final  String name;
@override final  bool isBuiltin;
@override final  DateTime updatedAt;

/// Create a copy of PresetSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetSummaryCopyWith<_PresetSummary> get copyWith => __$PresetSummaryCopyWithImpl<_PresetSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isBuiltin,updatedAt);

@override
String toString() {
  return 'PresetSummary(id: $id, name: $name, isBuiltin: $isBuiltin, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PresetSummaryCopyWith<$Res> implements $PresetSummaryCopyWith<$Res> {
  factory _$PresetSummaryCopyWith(_PresetSummary value, $Res Function(_PresetSummary) _then) = __$PresetSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isBuiltin, DateTime updatedAt
});




}
/// @nodoc
class __$PresetSummaryCopyWithImpl<$Res>
    implements _$PresetSummaryCopyWith<$Res> {
  __$PresetSummaryCopyWithImpl(this._self, this._then);

  final _PresetSummary _self;
  final $Res Function(_PresetSummary) _then;

/// Create a copy of PresetSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isBuiltin = null,Object? updatedAt = null,}) {
  return _then(_PresetSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
