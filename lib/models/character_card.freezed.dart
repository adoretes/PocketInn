// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CharacterSummary {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: '') String get name;@JsonKey(defaultValue: '') String get thumbnailPath;@JsonKey(defaultValue: '') String get description; int? get cardColorValue;@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterSummaryCopyWith<CharacterSummary> get copyWith => _$CharacterSummaryCopyWithImpl<CharacterSummary>(this as CharacterSummary, _$identity);

  /// Serializes this CharacterSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.description, description) || other.description == description)&&(identical(other.cardColorValue, cardColorValue) || other.cardColorValue == cardColorValue)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,thumbnailPath,description,cardColorValue,updatedAt);

@override
String toString() {
  return 'CharacterSummary(id: $id, name: $name, thumbnailPath: $thumbnailPath, description: $description, cardColorValue: $cardColorValue, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CharacterSummaryCopyWith<$Res>  {
  factory $CharacterSummaryCopyWith(CharacterSummary value, $Res Function(CharacterSummary) _then) = _$CharacterSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String thumbnailPath,@JsonKey(defaultValue: '') String description, int? cardColorValue,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CharacterSummaryCopyWithImpl<$Res>
    implements $CharacterSummaryCopyWith<$Res> {
  _$CharacterSummaryCopyWithImpl(this._self, this._then);

  final CharacterSummary _self;
  final $Res Function(CharacterSummary) _then;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? thumbnailPath = null,Object? description = null,Object? cardColorValue = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: null == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cardColorValue: freezed == cardColorValue ? _self.cardColorValue : cardColorValue // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterSummary].
extension CharacterSummaryPatterns on CharacterSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterSummary value)  $default,){
final _that = this;
switch (_that) {
case _CharacterSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String thumbnailPath, @JsonKey(defaultValue: '')  String description,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
return $default(_that.id,_that.name,_that.thumbnailPath,_that.description,_that.cardColorValue,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String thumbnailPath, @JsonKey(defaultValue: '')  String description,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CharacterSummary():
return $default(_that.id,_that.name,_that.thumbnailPath,_that.description,_that.cardColorValue,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: '')  String name, @JsonKey(defaultValue: '')  String thumbnailPath, @JsonKey(defaultValue: '')  String description,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
return $default(_that.id,_that.name,_that.thumbnailPath,_that.description,_that.cardColorValue,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CharacterSummary implements CharacterSummary {
  const _CharacterSummary({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: '') required this.name, @JsonKey(defaultValue: '') required this.thumbnailPath, @JsonKey(defaultValue: '') this.description = '', this.cardColorValue, @NullableDateTimeConverter() this.updatedAt});
  factory _CharacterSummary.fromJson(Map<String, dynamic> json) => _$CharacterSummaryFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(defaultValue: '') final  String thumbnailPath;
@override@JsonKey(defaultValue: '') final  String description;
@override final  int? cardColorValue;
@override@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterSummaryCopyWith<_CharacterSummary> get copyWith => __$CharacterSummaryCopyWithImpl<_CharacterSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.description, description) || other.description == description)&&(identical(other.cardColorValue, cardColorValue) || other.cardColorValue == cardColorValue)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,thumbnailPath,description,cardColorValue,updatedAt);

@override
String toString() {
  return 'CharacterSummary(id: $id, name: $name, thumbnailPath: $thumbnailPath, description: $description, cardColorValue: $cardColorValue, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CharacterSummaryCopyWith<$Res> implements $CharacterSummaryCopyWith<$Res> {
  factory _$CharacterSummaryCopyWith(_CharacterSummary value, $Res Function(_CharacterSummary) _then) = __$CharacterSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: '') String name,@JsonKey(defaultValue: '') String thumbnailPath,@JsonKey(defaultValue: '') String description, int? cardColorValue,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CharacterSummaryCopyWithImpl<$Res>
    implements _$CharacterSummaryCopyWith<$Res> {
  __$CharacterSummaryCopyWithImpl(this._self, this._then);

  final _CharacterSummary _self;
  final $Res Function(_CharacterSummary) _then;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? thumbnailPath = null,Object? description = null,Object? cardColorValue = freezed,Object? updatedAt = freezed,}) {
  return _then(_CharacterSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: null == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cardColorValue: freezed == cardColorValue ? _self.cardColorValue : cardColorValue // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CharacterCardRecord {

@JsonKey(defaultValue: '') String get id;@JsonKey(defaultValue: {}) Map<String, dynamic> get cardJson;@JsonKey(defaultValue: '') String get originalImagePath;@JsonKey(defaultValue: '') String get thumbnailPath; String? get worldBookId;@JsonKey(defaultValue: {}) Map<String, dynamic> get characterBookExtensions; int? get cardColorValue;@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of CharacterCardRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCardRecordCopyWith<CharacterCardRecord> get copyWith => _$CharacterCardRecordCopyWithImpl<CharacterCardRecord>(this as CharacterCardRecord, _$identity);

  /// Serializes this CharacterCardRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCardRecord&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.cardJson, cardJson)&&(identical(other.originalImagePath, originalImagePath) || other.originalImagePath == originalImagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.worldBookId, worldBookId) || other.worldBookId == worldBookId)&&const DeepCollectionEquality().equals(other.characterBookExtensions, characterBookExtensions)&&(identical(other.cardColorValue, cardColorValue) || other.cardColorValue == cardColorValue)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(cardJson),originalImagePath,thumbnailPath,worldBookId,const DeepCollectionEquality().hash(characterBookExtensions),cardColorValue,updatedAt);

@override
String toString() {
  return 'CharacterCardRecord(id: $id, cardJson: $cardJson, originalImagePath: $originalImagePath, thumbnailPath: $thumbnailPath, worldBookId: $worldBookId, characterBookExtensions: $characterBookExtensions, cardColorValue: $cardColorValue, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CharacterCardRecordCopyWith<$Res>  {
  factory $CharacterCardRecordCopyWith(CharacterCardRecord value, $Res Function(CharacterCardRecord) _then) = _$CharacterCardRecordCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: {}) Map<String, dynamic> cardJson,@JsonKey(defaultValue: '') String originalImagePath,@JsonKey(defaultValue: '') String thumbnailPath, String? worldBookId,@JsonKey(defaultValue: {}) Map<String, dynamic> characterBookExtensions, int? cardColorValue,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CharacterCardRecordCopyWithImpl<$Res>
    implements $CharacterCardRecordCopyWith<$Res> {
  _$CharacterCardRecordCopyWithImpl(this._self, this._then);

  final CharacterCardRecord _self;
  final $Res Function(CharacterCardRecord) _then;

/// Create a copy of CharacterCardRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardJson = null,Object? originalImagePath = null,Object? thumbnailPath = null,Object? worldBookId = freezed,Object? characterBookExtensions = null,Object? cardColorValue = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardJson: null == cardJson ? _self.cardJson : cardJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,originalImagePath: null == originalImagePath ? _self.originalImagePath : originalImagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: null == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String,worldBookId: freezed == worldBookId ? _self.worldBookId : worldBookId // ignore: cast_nullable_to_non_nullable
as String?,characterBookExtensions: null == characterBookExtensions ? _self.characterBookExtensions : characterBookExtensions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,cardColorValue: freezed == cardColorValue ? _self.cardColorValue : cardColorValue // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterCardRecord].
extension CharacterCardRecordPatterns on CharacterCardRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterCardRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterCardRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterCardRecord value)  $default,){
final _that = this;
switch (_that) {
case _CharacterCardRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterCardRecord value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterCardRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: {})  Map<String, dynamic> cardJson, @JsonKey(defaultValue: '')  String originalImagePath, @JsonKey(defaultValue: '')  String thumbnailPath,  String? worldBookId, @JsonKey(defaultValue: {})  Map<String, dynamic> characterBookExtensions,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCardRecord() when $default != null:
return $default(_that.id,_that.cardJson,_that.originalImagePath,_that.thumbnailPath,_that.worldBookId,_that.characterBookExtensions,_that.cardColorValue,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: {})  Map<String, dynamic> cardJson, @JsonKey(defaultValue: '')  String originalImagePath, @JsonKey(defaultValue: '')  String thumbnailPath,  String? worldBookId, @JsonKey(defaultValue: {})  Map<String, dynamic> characterBookExtensions,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CharacterCardRecord():
return $default(_that.id,_that.cardJson,_that.originalImagePath,_that.thumbnailPath,_that.worldBookId,_that.characterBookExtensions,_that.cardColorValue,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: '')  String id, @JsonKey(defaultValue: {})  Map<String, dynamic> cardJson, @JsonKey(defaultValue: '')  String originalImagePath, @JsonKey(defaultValue: '')  String thumbnailPath,  String? worldBookId, @JsonKey(defaultValue: {})  Map<String, dynamic> characterBookExtensions,  int? cardColorValue, @NullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCardRecord() when $default != null:
return $default(_that.id,_that.cardJson,_that.originalImagePath,_that.thumbnailPath,_that.worldBookId,_that.characterBookExtensions,_that.cardColorValue,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CharacterCardRecord extends CharacterCardRecord {
  const _CharacterCardRecord({@JsonKey(defaultValue: '') required this.id, @JsonKey(defaultValue: {}) final  Map<String, dynamic> cardJson = const {}, @JsonKey(defaultValue: '') required this.originalImagePath, @JsonKey(defaultValue: '') required this.thumbnailPath, this.worldBookId, @JsonKey(defaultValue: {}) final  Map<String, dynamic> characterBookExtensions = const {}, this.cardColorValue, @NullableDateTimeConverter() this.updatedAt}): _cardJson = cardJson,_characterBookExtensions = characterBookExtensions,super._();
  factory _CharacterCardRecord.fromJson(Map<String, dynamic> json) => _$CharacterCardRecordFromJson(json);

@override@JsonKey(defaultValue: '') final  String id;
 final  Map<String, dynamic> _cardJson;
@override@JsonKey(defaultValue: {}) Map<String, dynamic> get cardJson {
  if (_cardJson is EqualUnmodifiableMapView) return _cardJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cardJson);
}

@override@JsonKey(defaultValue: '') final  String originalImagePath;
@override@JsonKey(defaultValue: '') final  String thumbnailPath;
@override final  String? worldBookId;
 final  Map<String, dynamic> _characterBookExtensions;
@override@JsonKey(defaultValue: {}) Map<String, dynamic> get characterBookExtensions {
  if (_characterBookExtensions is EqualUnmodifiableMapView) return _characterBookExtensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_characterBookExtensions);
}

@override final  int? cardColorValue;
@override@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of CharacterCardRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCardRecordCopyWith<_CharacterCardRecord> get copyWith => __$CharacterCardRecordCopyWithImpl<_CharacterCardRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterCardRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCardRecord&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._cardJson, _cardJson)&&(identical(other.originalImagePath, originalImagePath) || other.originalImagePath == originalImagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.worldBookId, worldBookId) || other.worldBookId == worldBookId)&&const DeepCollectionEquality().equals(other._characterBookExtensions, _characterBookExtensions)&&(identical(other.cardColorValue, cardColorValue) || other.cardColorValue == cardColorValue)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_cardJson),originalImagePath,thumbnailPath,worldBookId,const DeepCollectionEquality().hash(_characterBookExtensions),cardColorValue,updatedAt);

@override
String toString() {
  return 'CharacterCardRecord(id: $id, cardJson: $cardJson, originalImagePath: $originalImagePath, thumbnailPath: $thumbnailPath, worldBookId: $worldBookId, characterBookExtensions: $characterBookExtensions, cardColorValue: $cardColorValue, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CharacterCardRecordCopyWith<$Res> implements $CharacterCardRecordCopyWith<$Res> {
  factory _$CharacterCardRecordCopyWith(_CharacterCardRecord value, $Res Function(_CharacterCardRecord) _then) = __$CharacterCardRecordCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: '') String id,@JsonKey(defaultValue: {}) Map<String, dynamic> cardJson,@JsonKey(defaultValue: '') String originalImagePath,@JsonKey(defaultValue: '') String thumbnailPath, String? worldBookId,@JsonKey(defaultValue: {}) Map<String, dynamic> characterBookExtensions, int? cardColorValue,@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CharacterCardRecordCopyWithImpl<$Res>
    implements _$CharacterCardRecordCopyWith<$Res> {
  __$CharacterCardRecordCopyWithImpl(this._self, this._then);

  final _CharacterCardRecord _self;
  final $Res Function(_CharacterCardRecord) _then;

/// Create a copy of CharacterCardRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardJson = null,Object? originalImagePath = null,Object? thumbnailPath = null,Object? worldBookId = freezed,Object? characterBookExtensions = null,Object? cardColorValue = freezed,Object? updatedAt = freezed,}) {
  return _then(_CharacterCardRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardJson: null == cardJson ? _self._cardJson : cardJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,originalImagePath: null == originalImagePath ? _self.originalImagePath : originalImagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: null == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String,worldBookId: freezed == worldBookId ? _self.worldBookId : worldBookId // ignore: cast_nullable_to_non_nullable
as String?,characterBookExtensions: null == characterBookExtensions ? _self._characterBookExtensions : characterBookExtensions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,cardColorValue: freezed == cardColorValue ? _self.cardColorValue : cardColorValue // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
