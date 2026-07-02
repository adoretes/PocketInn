// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorldBookEntry {

@JsonKey(defaultValue: '') String get id; List<String> get key; List<String> get keysecondary;@JsonKey(defaultValue: '') String get content;@JsonKey(defaultValue: '') String get comment;@JsonKey(defaultValue: false) bool get constant;@JsonKey(defaultValue: false) bool get selective;@JsonKey(defaultValue: 0) int get selectiveLogic;@JsonKey(defaultValue: 100) int get order;@JsonKey(defaultValue: 0) int get position;@JsonKey(defaultValue: 4) int get depth;@JsonKey(defaultValue: 0) int get sticky;@JsonKey(defaultValue: 0) int get cooldown;@JsonKey(defaultValue: 0) int get delay;@JsonKey(defaultValue: true) bool get isEnabled;@JsonKey(defaultValue: {}) Map<String, dynamic> get extensions;
/// Create a copy of WorldBookEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldBookEntryCopyWith<WorldBookEntry> get copyWith => _$WorldBookEntryCopyWithImpl<WorldBookEntry>(this as WorldBookEntry, _$identity);

  /// Serializes this WorldBookEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldBookEntry&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.key, key)&&const DeepCollectionEquality().equals(other.keysecondary, keysecondary)&&(identical(other.content, content) || other.content == content)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.constant, constant) || other.constant == constant)&&(identical(other.selective, selective) || other.selective == selective)&&(identical(other.selectiveLogic, selectiveLogic) || other.selectiveLogic == selectiveLogic)&&(identical(other.order, order) || other.order == order)&&(identical(other.position, position) || other.position == position)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.sticky, sticky) || other.sticky == sticky)&&(identical(other.cooldown, cooldown) || other.cooldown == cooldown)&&(identical(other.delay, delay) || other.delay == delay)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other.extensions, extensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(key),const DeepCollectionEquality().hash(keysecondary),content,comment,constant,selective,selectiveLogic,order,position,depth,sticky,cooldown,delay,isEnabled,const DeepCollectionEquality().hash(extensions));

@override
String toString() {
  return 'WorldBookEntry(id: $id, key: $key, keysecondary: $keysecondary, content: $content, comment: $comment, constant: $constant, selective: $selective, selectiveLogic: $selectiveLogic, order: $order, position: $position, depth: $depth, sticky: $sticky, cooldown: $cooldown, delay: $delay, isEnabled: $isEnabled, extensions: $extensions)';
}


}

/// @nodoc
abstract mixin class $WorldBookEntryCopyWith<$Res>  {
  factory $WorldBookEntryCopyWith(WorldBookEntry value, $Res Function(WorldBookEntry) _then) = _$WorldBookEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id, List<String> key, List<String> keysecondary,@JsonKey(defaultValue: '') String content,@JsonKey(defaultValue: '') String comment,@JsonKey(defaultValue: false) bool constant,@JsonKey(defaultValue: false) bool selective,@JsonKey(defaultValue: 0) int selectiveLogic,@JsonKey(defaultValue: 100) int order,@JsonKey(defaultValue: 0) int position,@JsonKey(defaultValue: 4) int depth,@JsonKey(defaultValue: 0) int sticky,@JsonKey(defaultValue: 0) int cooldown,@JsonKey(defaultValue: 0) int delay,@JsonKey(defaultValue: true) bool isEnabled,@JsonKey(defaultValue: {}) Map<String, dynamic> extensions
});




}
/// @nodoc
class _$WorldBookEntryCopyWithImpl<$Res>
    implements $WorldBookEntryCopyWith<$Res> {
  _$WorldBookEntryCopyWithImpl(this._self, this._then);

  final WorldBookEntry _self;
  final $Res Function(WorldBookEntry) _then;

/// Create a copy of WorldBookEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? keysecondary = null,Object? content = null,Object? comment = null,Object? constant = null,Object? selective = null,Object? selectiveLogic = null,Object? order = null,Object? position = null,Object? depth = null,Object? sticky = null,Object? cooldown = null,Object? delay = null,Object? isEnabled = null,Object? extensions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as List<String>,keysecondary: null == keysecondary ? _self.keysecondary : keysecondary // ignore: cast_nullable_to_non_nullable
as List<String>,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,constant: null == constant ? _self.constant : constant // ignore: cast_nullable_to_non_nullable
as bool,selective: null == selective ? _self.selective : selective // ignore: cast_nullable_to_non_nullable
as bool,selectiveLogic: null == selectiveLogic ? _self.selectiveLogic : selectiveLogic // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,sticky: null == sticky ? _self.sticky : sticky // ignore: cast_nullable_to_non_nullable
as int,cooldown: null == cooldown ? _self.cooldown : cooldown // ignore: cast_nullable_to_non_nullable
as int,delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as int,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,extensions: null == extensions ? _self.extensions : extensions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldBookEntry].
extension WorldBookEntryPatterns on WorldBookEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldBookEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldBookEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldBookEntry value)  $default,){
final _that = this;
switch (_that) {
case _WorldBookEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldBookEntry value)?  $default,){
final _that = this;
switch (_that) {
case _WorldBookEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id,  List<String> key,  List<String> keysecondary, @JsonKey(defaultValue: '')  String content, @JsonKey(defaultValue: '')  String comment, @JsonKey(defaultValue: false)  bool constant, @JsonKey(defaultValue: false)  bool selective, @JsonKey(defaultValue: 0)  int selectiveLogic, @JsonKey(defaultValue: 100)  int order, @JsonKey(defaultValue: 0)  int position, @JsonKey(defaultValue: 4)  int depth, @JsonKey(defaultValue: 0)  int sticky, @JsonKey(defaultValue: 0)  int cooldown, @JsonKey(defaultValue: 0)  int delay, @JsonKey(defaultValue: true)  bool isEnabled, @JsonKey(defaultValue: {})  Map<String, dynamic> extensions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldBookEntry() when $default != null:
return $default(_that.id,_that.key,_that.keysecondary,_that.content,_that.comment,_that.constant,_that.selective,_that.selectiveLogic,_that.order,_that.position,_that.depth,_that.sticky,_that.cooldown,_that.delay,_that.isEnabled,_that.extensions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id,  List<String> key,  List<String> keysecondary, @JsonKey(defaultValue: '')  String content, @JsonKey(defaultValue: '')  String comment, @JsonKey(defaultValue: false)  bool constant, @JsonKey(defaultValue: false)  bool selective, @JsonKey(defaultValue: 0)  int selectiveLogic, @JsonKey(defaultValue: 100)  int order, @JsonKey(defaultValue: 0)  int position, @JsonKey(defaultValue: 4)  int depth, @JsonKey(defaultValue: 0)  int sticky, @JsonKey(defaultValue: 0)  int cooldown, @JsonKey(defaultValue: 0)  int delay, @JsonKey(defaultValue: true)  bool isEnabled, @JsonKey(defaultValue: {})  Map<String, dynamic> extensions)  $default,) {final _that = this;
switch (_that) {
case _WorldBookEntry():
return $default(_that.id,_that.key,_that.keysecondary,_that.content,_that.comment,_that.constant,_that.selective,_that.selectiveLogic,_that.order,_that.position,_that.depth,_that.sticky,_that.cooldown,_that.delay,_that.isEnabled,_that.extensions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id,  List<String> key,  List<String> keysecondary, @JsonKey(defaultValue: '')  String content, @JsonKey(defaultValue: '')  String comment, @JsonKey(defaultValue: false)  bool constant, @JsonKey(defaultValue: false)  bool selective, @JsonKey(defaultValue: 0)  int selectiveLogic, @JsonKey(defaultValue: 100)  int order, @JsonKey(defaultValue: 0)  int position, @JsonKey(defaultValue: 4)  int depth, @JsonKey(defaultValue: 0)  int sticky, @JsonKey(defaultValue: 0)  int cooldown, @JsonKey(defaultValue: 0)  int delay, @JsonKey(defaultValue: true)  bool isEnabled, @JsonKey(defaultValue: {})  Map<String, dynamic> extensions)?  $default,) {final _that = this;
switch (_that) {
case _WorldBookEntry() when $default != null:
return $default(_that.id,_that.key,_that.keysecondary,_that.content,_that.comment,_that.constant,_that.selective,_that.selectiveLogic,_that.order,_that.position,_that.depth,_that.sticky,_that.cooldown,_that.delay,_that.isEnabled,_that.extensions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorldBookEntry extends WorldBookEntry {
  const _WorldBookEntry({@JsonKey(defaultValue: '') required this.id, final  List<String> key = const [], final  List<String> keysecondary = const [], @JsonKey(defaultValue: '') required this.content, @JsonKey(defaultValue: '') required this.comment, @JsonKey(defaultValue: false) this.constant = false, @JsonKey(defaultValue: false) this.selective = false, @JsonKey(defaultValue: 0) this.selectiveLogic = 0, @JsonKey(defaultValue: 100) this.order = 100, @JsonKey(defaultValue: 0) this.position = 0, @JsonKey(defaultValue: 4) this.depth = 4, @JsonKey(defaultValue: 0) this.sticky = 0, @JsonKey(defaultValue: 0) this.cooldown = 0, @JsonKey(defaultValue: 0) this.delay = 0, @JsonKey(defaultValue: true) this.isEnabled = true, @JsonKey(defaultValue: {}) final  Map<String, dynamic> extensions = const {}}): _key = key,_keysecondary = keysecondary,_extensions = extensions,super._();
  factory _WorldBookEntry.fromJson(Map<String, dynamic> json) => _$WorldBookEntryFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
 final  List<String> _key;
@override@JsonKey() List<String> get key {
  if (_key is EqualUnmodifiableListView) return _key;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_key);
}

 final  List<String> _keysecondary;
@override@JsonKey() List<String> get keysecondary {
  if (_keysecondary is EqualUnmodifiableListView) return _keysecondary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keysecondary);
}

@override@JsonKey(defaultValue: '') final  String content;
@override@JsonKey(defaultValue: '') final  String comment;
@override@JsonKey(defaultValue: false) final  bool constant;
@override@JsonKey(defaultValue: false) final  bool selective;
@override@JsonKey(defaultValue: 0) final  int selectiveLogic;
@override@JsonKey(defaultValue: 100) final  int order;
@override@JsonKey(defaultValue: 0) final  int position;
@override@JsonKey(defaultValue: 4) final  int depth;
@override@JsonKey(defaultValue: 0) final  int sticky;
@override@JsonKey(defaultValue: 0) final  int cooldown;
@override@JsonKey(defaultValue: 0) final  int delay;
@override@JsonKey(defaultValue: true) final  bool isEnabled;
 final  Map<String, dynamic> _extensions;
@override@JsonKey(defaultValue: {}) Map<String, dynamic> get extensions {
  if (_extensions is EqualUnmodifiableMapView) return _extensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extensions);
}


/// Create a copy of WorldBookEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldBookEntryCopyWith<_WorldBookEntry> get copyWith => __$WorldBookEntryCopyWithImpl<_WorldBookEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldBookEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldBookEntry&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._key, _key)&&const DeepCollectionEquality().equals(other._keysecondary, _keysecondary)&&(identical(other.content, content) || other.content == content)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.constant, constant) || other.constant == constant)&&(identical(other.selective, selective) || other.selective == selective)&&(identical(other.selectiveLogic, selectiveLogic) || other.selectiveLogic == selectiveLogic)&&(identical(other.order, order) || other.order == order)&&(identical(other.position, position) || other.position == position)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.sticky, sticky) || other.sticky == sticky)&&(identical(other.cooldown, cooldown) || other.cooldown == cooldown)&&(identical(other.delay, delay) || other.delay == delay)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other._extensions, _extensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_key),const DeepCollectionEquality().hash(_keysecondary),content,comment,constant,selective,selectiveLogic,order,position,depth,sticky,cooldown,delay,isEnabled,const DeepCollectionEquality().hash(_extensions));

@override
String toString() {
  return 'WorldBookEntry(id: $id, key: $key, keysecondary: $keysecondary, content: $content, comment: $comment, constant: $constant, selective: $selective, selectiveLogic: $selectiveLogic, order: $order, position: $position, depth: $depth, sticky: $sticky, cooldown: $cooldown, delay: $delay, isEnabled: $isEnabled, extensions: $extensions)';
}


}

/// @nodoc
abstract mixin class _$WorldBookEntryCopyWith<$Res> implements $WorldBookEntryCopyWith<$Res> {
  factory _$WorldBookEntryCopyWith(_WorldBookEntry value, $Res Function(_WorldBookEntry) _then) = __$WorldBookEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id, List<String> key, List<String> keysecondary,@JsonKey(defaultValue: '') String content,@JsonKey(defaultValue: '') String comment,@JsonKey(defaultValue: false) bool constant,@JsonKey(defaultValue: false) bool selective,@JsonKey(defaultValue: 0) int selectiveLogic,@JsonKey(defaultValue: 100) int order,@JsonKey(defaultValue: 0) int position,@JsonKey(defaultValue: 4) int depth,@JsonKey(defaultValue: 0) int sticky,@JsonKey(defaultValue: 0) int cooldown,@JsonKey(defaultValue: 0) int delay,@JsonKey(defaultValue: true) bool isEnabled,@JsonKey(defaultValue: {}) Map<String, dynamic> extensions
});




}
/// @nodoc
class __$WorldBookEntryCopyWithImpl<$Res>
    implements _$WorldBookEntryCopyWith<$Res> {
  __$WorldBookEntryCopyWithImpl(this._self, this._then);

  final _WorldBookEntry _self;
  final $Res Function(_WorldBookEntry) _then;

/// Create a copy of WorldBookEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? keysecondary = null,Object? content = null,Object? comment = null,Object? constant = null,Object? selective = null,Object? selectiveLogic = null,Object? order = null,Object? position = null,Object? depth = null,Object? sticky = null,Object? cooldown = null,Object? delay = null,Object? isEnabled = null,Object? extensions = null,}) {
  return _then(_WorldBookEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self._key : key // ignore: cast_nullable_to_non_nullable
as List<String>,keysecondary: null == keysecondary ? _self._keysecondary : keysecondary // ignore: cast_nullable_to_non_nullable
as List<String>,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,constant: null == constant ? _self.constant : constant // ignore: cast_nullable_to_non_nullable
as bool,selective: null == selective ? _self.selective : selective // ignore: cast_nullable_to_non_nullable
as bool,selectiveLogic: null == selectiveLogic ? _self.selectiveLogic : selectiveLogic // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,sticky: null == sticky ? _self.sticky : sticky // ignore: cast_nullable_to_non_nullable
as int,cooldown: null == cooldown ? _self.cooldown : cooldown // ignore: cast_nullable_to_non_nullable
as int,delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as int,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,extensions: null == extensions ? _self._extensions : extensions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$WorldBook {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: '') String get description;@JsonKey(defaultValue: 0xFF4B6CB7) int get colorValue; List<WorldBookEntry> get entries;@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of WorldBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldBookCopyWith<WorldBook> get copyWith => _$WorldBookCopyWithImpl<WorldBook>(this as WorldBook, _$identity);

  /// Serializes this WorldBook to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldBook&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,colorValue,const DeepCollectionEquality().hash(entries),updatedAt);

@override
String toString() {
  return 'WorldBook(id: $id, name: $name, description: $description, colorValue: $colorValue, entries: $entries, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorldBookCopyWith<$Res>  {
  factory $WorldBookCopyWith(WorldBook value, $Res Function(WorldBook) _then) = _$WorldBookCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: 0xFF4B6CB7) int colorValue, List<WorldBookEntry> entries,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$WorldBookCopyWithImpl<$Res>
    implements $WorldBookCopyWith<$Res> {
  _$WorldBookCopyWithImpl(this._self, this._then);

  final WorldBook _self;
  final $Res Function(WorldBook) _then;

/// Create a copy of WorldBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? colorValue = null,Object? entries = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<WorldBookEntry>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldBook].
extension WorldBookPatterns on WorldBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldBook value)  $default,){
final _that = this;
switch (_that) {
case _WorldBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldBook value)?  $default,){
final _that = this;
switch (_that) {
case _WorldBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue,  List<WorldBookEntry> entries, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldBook() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entries,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue,  List<WorldBookEntry> entries, @NullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorldBook():
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entries,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue,  List<WorldBookEntry> entries, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorldBook() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entries,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _WorldBook extends WorldBook {
  const _WorldBook({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: '') required this.description, @JsonKey(defaultValue: 0xFF4B6CB7) required this.colorValue, final  List<WorldBookEntry> entries = const [], @NullableDateTimeConverter() this.updatedAt}): _entries = entries,super._();
  factory _WorldBook.fromJson(Map<String, dynamic> json) => _$WorldBookFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: '') final  String description;
@override@JsonKey(defaultValue: 0xFF4B6CB7) final  int colorValue;
 final  List<WorldBookEntry> _entries;
@override@JsonKey() List<WorldBookEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of WorldBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldBookCopyWith<_WorldBook> get copyWith => __$WorldBookCopyWithImpl<_WorldBook>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldBookToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldBook&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,colorValue,const DeepCollectionEquality().hash(_entries),updatedAt);

@override
String toString() {
  return 'WorldBook(id: $id, name: $name, description: $description, colorValue: $colorValue, entries: $entries, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorldBookCopyWith<$Res> implements $WorldBookCopyWith<$Res> {
  factory _$WorldBookCopyWith(_WorldBook value, $Res Function(_WorldBook) _then) = __$WorldBookCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: 0xFF4B6CB7) int colorValue, List<WorldBookEntry> entries,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$WorldBookCopyWithImpl<$Res>
    implements _$WorldBookCopyWith<$Res> {
  __$WorldBookCopyWithImpl(this._self, this._then);

  final _WorldBook _self;
  final $Res Function(_WorldBook) _then;

/// Create a copy of WorldBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? colorValue = null,Object? entries = null,Object? updatedAt = freezed,}) {
  return _then(_WorldBook(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<WorldBookEntry>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$WorldBookIndexInfo {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: '') String get description;@JsonKey(defaultValue: 0xFF4B6CB7) int get colorValue;@JsonKey(defaultValue: 0) int get entryCount;@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of WorldBookIndexInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldBookIndexInfoCopyWith<WorldBookIndexInfo> get copyWith => _$WorldBookIndexInfoCopyWithImpl<WorldBookIndexInfo>(this as WorldBookIndexInfo, _$identity);

  /// Serializes this WorldBookIndexInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldBookIndexInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,colorValue,entryCount,updatedAt);

@override
String toString() {
  return 'WorldBookIndexInfo(id: $id, name: $name, description: $description, colorValue: $colorValue, entryCount: $entryCount, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorldBookIndexInfoCopyWith<$Res>  {
  factory $WorldBookIndexInfoCopyWith(WorldBookIndexInfo value, $Res Function(WorldBookIndexInfo) _then) = _$WorldBookIndexInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: 0xFF4B6CB7) int colorValue,@JsonKey(defaultValue: 0) int entryCount,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$WorldBookIndexInfoCopyWithImpl<$Res>
    implements $WorldBookIndexInfoCopyWith<$Res> {
  _$WorldBookIndexInfoCopyWithImpl(this._self, this._then);

  final WorldBookIndexInfo _self;
  final $Res Function(WorldBookIndexInfo) _then;

/// Create a copy of WorldBookIndexInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? colorValue = null,Object? entryCount = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldBookIndexInfo].
extension WorldBookIndexInfoPatterns on WorldBookIndexInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldBookIndexInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldBookIndexInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldBookIndexInfo value)  $default,){
final _that = this;
switch (_that) {
case _WorldBookIndexInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldBookIndexInfo value)?  $default,){
final _that = this;
switch (_that) {
case _WorldBookIndexInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue, @JsonKey(defaultValue: 0)  int entryCount, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldBookIndexInfo() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entryCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue, @JsonKey(defaultValue: 0)  int entryCount, @NullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorldBookIndexInfo():
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entryCount,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String description, @JsonKey(defaultValue: 0xFF4B6CB7)  int colorValue, @JsonKey(defaultValue: 0)  int entryCount, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorldBookIndexInfo() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.colorValue,_that.entryCount,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorldBookIndexInfo extends WorldBookIndexInfo {
  const _WorldBookIndexInfo({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: '') required this.description, @JsonKey(defaultValue: 0xFF4B6CB7) required this.colorValue, @JsonKey(defaultValue: 0) this.entryCount = 0, @NullableDateTimeConverter() this.updatedAt}): super._();
  factory _WorldBookIndexInfo.fromJson(Map<String, dynamic> json) => _$WorldBookIndexInfoFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: '') final  String description;
@override@JsonKey(defaultValue: 0xFF4B6CB7) final  int colorValue;
@override@JsonKey(defaultValue: 0) final  int entryCount;
@override@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of WorldBookIndexInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldBookIndexInfoCopyWith<_WorldBookIndexInfo> get copyWith => __$WorldBookIndexInfoCopyWithImpl<_WorldBookIndexInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldBookIndexInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldBookIndexInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,colorValue,entryCount,updatedAt);

@override
String toString() {
  return 'WorldBookIndexInfo(id: $id, name: $name, description: $description, colorValue: $colorValue, entryCount: $entryCount, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorldBookIndexInfoCopyWith<$Res> implements $WorldBookIndexInfoCopyWith<$Res> {
  factory _$WorldBookIndexInfoCopyWith(_WorldBookIndexInfo value, $Res Function(_WorldBookIndexInfo) _then) = __$WorldBookIndexInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String description,@JsonKey(defaultValue: 0xFF4B6CB7) int colorValue,@JsonKey(defaultValue: 0) int entryCount,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$WorldBookIndexInfoCopyWithImpl<$Res>
    implements _$WorldBookIndexInfoCopyWith<$Res> {
  __$WorldBookIndexInfoCopyWithImpl(this._self, this._then);

  final _WorldBookIndexInfo _self;
  final $Res Function(_WorldBookIndexInfo) _then;

/// Create a copy of WorldBookIndexInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? colorValue = null,Object? entryCount = null,Object? updatedAt = freezed,}) {
  return _then(_WorldBookIndexInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
