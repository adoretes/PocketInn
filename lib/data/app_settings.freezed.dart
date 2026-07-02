// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatTextStyleConfig {

 int get paletteIndex; int? get darkPaletteIndex; ChatTextFontStyleMode get fontStyleMode; double get opacity;
/// Create a copy of ChatTextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<ChatTextStyleConfig> get copyWith => _$ChatTextStyleConfigCopyWithImpl<ChatTextStyleConfig>(this as ChatTextStyleConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTextStyleConfig&&(identical(other.paletteIndex, paletteIndex) || other.paletteIndex == paletteIndex)&&(identical(other.darkPaletteIndex, darkPaletteIndex) || other.darkPaletteIndex == darkPaletteIndex)&&(identical(other.fontStyleMode, fontStyleMode) || other.fontStyleMode == fontStyleMode)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}


@override
int get hashCode => Object.hash(runtimeType,paletteIndex,darkPaletteIndex,fontStyleMode,opacity);

@override
String toString() {
  return 'ChatTextStyleConfig(paletteIndex: $paletteIndex, darkPaletteIndex: $darkPaletteIndex, fontStyleMode: $fontStyleMode, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $ChatTextStyleConfigCopyWith<$Res>  {
  factory $ChatTextStyleConfigCopyWith(ChatTextStyleConfig value, $Res Function(ChatTextStyleConfig) _then) = _$ChatTextStyleConfigCopyWithImpl;
@useResult
$Res call({
 int paletteIndex, int? darkPaletteIndex, ChatTextFontStyleMode fontStyleMode, double opacity
});




}
/// @nodoc
class _$ChatTextStyleConfigCopyWithImpl<$Res>
    implements $ChatTextStyleConfigCopyWith<$Res> {
  _$ChatTextStyleConfigCopyWithImpl(this._self, this._then);

  final ChatTextStyleConfig _self;
  final $Res Function(ChatTextStyleConfig) _then;

/// Create a copy of ChatTextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paletteIndex = null,Object? darkPaletteIndex = freezed,Object? fontStyleMode = null,Object? opacity = null,}) {
  return _then(_self.copyWith(
paletteIndex: null == paletteIndex ? _self.paletteIndex : paletteIndex // ignore: cast_nullable_to_non_nullable
as int,darkPaletteIndex: freezed == darkPaletteIndex ? _self.darkPaletteIndex : darkPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,fontStyleMode: null == fontStyleMode ? _self.fontStyleMode : fontStyleMode // ignore: cast_nullable_to_non_nullable
as ChatTextFontStyleMode,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatTextStyleConfig].
extension ChatTextStyleConfigPatterns on ChatTextStyleConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTextStyleConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTextStyleConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTextStyleConfig value)  $default,){
final _that = this;
switch (_that) {
case _ChatTextStyleConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTextStyleConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTextStyleConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int paletteIndex,  int? darkPaletteIndex,  ChatTextFontStyleMode fontStyleMode,  double opacity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTextStyleConfig() when $default != null:
return $default(_that.paletteIndex,_that.darkPaletteIndex,_that.fontStyleMode,_that.opacity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int paletteIndex,  int? darkPaletteIndex,  ChatTextFontStyleMode fontStyleMode,  double opacity)  $default,) {final _that = this;
switch (_that) {
case _ChatTextStyleConfig():
return $default(_that.paletteIndex,_that.darkPaletteIndex,_that.fontStyleMode,_that.opacity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int paletteIndex,  int? darkPaletteIndex,  ChatTextFontStyleMode fontStyleMode,  double opacity)?  $default,) {final _that = this;
switch (_that) {
case _ChatTextStyleConfig() when $default != null:
return $default(_that.paletteIndex,_that.darkPaletteIndex,_that.fontStyleMode,_that.opacity);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTextStyleConfig extends ChatTextStyleConfig {
  const _ChatTextStyleConfig({this.paletteIndex = 0, this.darkPaletteIndex, this.fontStyleMode = ChatTextFontStyleMode.platform, this.opacity = 1.0}): super._();
  

@override@JsonKey() final  int paletteIndex;
@override final  int? darkPaletteIndex;
@override@JsonKey() final  ChatTextFontStyleMode fontStyleMode;
@override@JsonKey() final  double opacity;

/// Create a copy of ChatTextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTextStyleConfigCopyWith<_ChatTextStyleConfig> get copyWith => __$ChatTextStyleConfigCopyWithImpl<_ChatTextStyleConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTextStyleConfig&&(identical(other.paletteIndex, paletteIndex) || other.paletteIndex == paletteIndex)&&(identical(other.darkPaletteIndex, darkPaletteIndex) || other.darkPaletteIndex == darkPaletteIndex)&&(identical(other.fontStyleMode, fontStyleMode) || other.fontStyleMode == fontStyleMode)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}


@override
int get hashCode => Object.hash(runtimeType,paletteIndex,darkPaletteIndex,fontStyleMode,opacity);

@override
String toString() {
  return 'ChatTextStyleConfig(paletteIndex: $paletteIndex, darkPaletteIndex: $darkPaletteIndex, fontStyleMode: $fontStyleMode, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class _$ChatTextStyleConfigCopyWith<$Res> implements $ChatTextStyleConfigCopyWith<$Res> {
  factory _$ChatTextStyleConfigCopyWith(_ChatTextStyleConfig value, $Res Function(_ChatTextStyleConfig) _then) = __$ChatTextStyleConfigCopyWithImpl;
@override @useResult
$Res call({
 int paletteIndex, int? darkPaletteIndex, ChatTextFontStyleMode fontStyleMode, double opacity
});




}
/// @nodoc
class __$ChatTextStyleConfigCopyWithImpl<$Res>
    implements _$ChatTextStyleConfigCopyWith<$Res> {
  __$ChatTextStyleConfigCopyWithImpl(this._self, this._then);

  final _ChatTextStyleConfig _self;
  final $Res Function(_ChatTextStyleConfig) _then;

/// Create a copy of ChatTextStyleConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paletteIndex = null,Object? darkPaletteIndex = freezed,Object? fontStyleMode = null,Object? opacity = null,}) {
  return _then(_ChatTextStyleConfig(
paletteIndex: null == paletteIndex ? _self.paletteIndex : paletteIndex // ignore: cast_nullable_to_non_nullable
as int,darkPaletteIndex: freezed == darkPaletteIndex ? _self.darkPaletteIndex : darkPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,fontStyleMode: null == fontStyleMode ? _self.fontStyleMode : fontStyleMode // ignore: cast_nullable_to_non_nullable
as ChatTextFontStyleMode,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ChatTextThemeSettings {

 AppQuoteStyle get quoteStyle; bool get enableMessageTextShadow; int? get bodyTextColorPaletteIndex; int? get bodyTextColorDarkPaletteIndex; ChatTextStyleConfig get quotedTextStyle; ChatTextStyleConfig get bracketTextStyle; ChatTextStyleConfig get italicTextStyle; ChatTextStyleConfig get boldTextStyle;
/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTextThemeSettingsCopyWith<ChatTextThemeSettings> get copyWith => _$ChatTextThemeSettingsCopyWithImpl<ChatTextThemeSettings>(this as ChatTextThemeSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTextThemeSettings&&(identical(other.quoteStyle, quoteStyle) || other.quoteStyle == quoteStyle)&&(identical(other.enableMessageTextShadow, enableMessageTextShadow) || other.enableMessageTextShadow == enableMessageTextShadow)&&(identical(other.bodyTextColorPaletteIndex, bodyTextColorPaletteIndex) || other.bodyTextColorPaletteIndex == bodyTextColorPaletteIndex)&&(identical(other.bodyTextColorDarkPaletteIndex, bodyTextColorDarkPaletteIndex) || other.bodyTextColorDarkPaletteIndex == bodyTextColorDarkPaletteIndex)&&(identical(other.quotedTextStyle, quotedTextStyle) || other.quotedTextStyle == quotedTextStyle)&&(identical(other.bracketTextStyle, bracketTextStyle) || other.bracketTextStyle == bracketTextStyle)&&(identical(other.italicTextStyle, italicTextStyle) || other.italicTextStyle == italicTextStyle)&&(identical(other.boldTextStyle, boldTextStyle) || other.boldTextStyle == boldTextStyle));
}


@override
int get hashCode => Object.hash(runtimeType,quoteStyle,enableMessageTextShadow,bodyTextColorPaletteIndex,bodyTextColorDarkPaletteIndex,quotedTextStyle,bracketTextStyle,italicTextStyle,boldTextStyle);

@override
String toString() {
  return 'ChatTextThemeSettings(quoteStyle: $quoteStyle, enableMessageTextShadow: $enableMessageTextShadow, bodyTextColorPaletteIndex: $bodyTextColorPaletteIndex, bodyTextColorDarkPaletteIndex: $bodyTextColorDarkPaletteIndex, quotedTextStyle: $quotedTextStyle, bracketTextStyle: $bracketTextStyle, italicTextStyle: $italicTextStyle, boldTextStyle: $boldTextStyle)';
}


}

/// @nodoc
abstract mixin class $ChatTextThemeSettingsCopyWith<$Res>  {
  factory $ChatTextThemeSettingsCopyWith(ChatTextThemeSettings value, $Res Function(ChatTextThemeSettings) _then) = _$ChatTextThemeSettingsCopyWithImpl;
@useResult
$Res call({
 AppQuoteStyle quoteStyle, bool enableMessageTextShadow, int? bodyTextColorPaletteIndex, int? bodyTextColorDarkPaletteIndex, ChatTextStyleConfig quotedTextStyle, ChatTextStyleConfig bracketTextStyle, ChatTextStyleConfig italicTextStyle, ChatTextStyleConfig boldTextStyle
});


$ChatTextStyleConfigCopyWith<$Res> get quotedTextStyle;$ChatTextStyleConfigCopyWith<$Res> get bracketTextStyle;$ChatTextStyleConfigCopyWith<$Res> get italicTextStyle;$ChatTextStyleConfigCopyWith<$Res> get boldTextStyle;

}
/// @nodoc
class _$ChatTextThemeSettingsCopyWithImpl<$Res>
    implements $ChatTextThemeSettingsCopyWith<$Res> {
  _$ChatTextThemeSettingsCopyWithImpl(this._self, this._then);

  final ChatTextThemeSettings _self;
  final $Res Function(ChatTextThemeSettings) _then;

/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quoteStyle = null,Object? enableMessageTextShadow = null,Object? bodyTextColorPaletteIndex = freezed,Object? bodyTextColorDarkPaletteIndex = freezed,Object? quotedTextStyle = null,Object? bracketTextStyle = null,Object? italicTextStyle = null,Object? boldTextStyle = null,}) {
  return _then(_self.copyWith(
quoteStyle: null == quoteStyle ? _self.quoteStyle : quoteStyle // ignore: cast_nullable_to_non_nullable
as AppQuoteStyle,enableMessageTextShadow: null == enableMessageTextShadow ? _self.enableMessageTextShadow : enableMessageTextShadow // ignore: cast_nullable_to_non_nullable
as bool,bodyTextColorPaletteIndex: freezed == bodyTextColorPaletteIndex ? _self.bodyTextColorPaletteIndex : bodyTextColorPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,bodyTextColorDarkPaletteIndex: freezed == bodyTextColorDarkPaletteIndex ? _self.bodyTextColorDarkPaletteIndex : bodyTextColorDarkPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,quotedTextStyle: null == quotedTextStyle ? _self.quotedTextStyle : quotedTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,bracketTextStyle: null == bracketTextStyle ? _self.bracketTextStyle : bracketTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,italicTextStyle: null == italicTextStyle ? _self.italicTextStyle : italicTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,boldTextStyle: null == boldTextStyle ? _self.boldTextStyle : boldTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,
  ));
}
/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get quotedTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.quotedTextStyle, (value) {
    return _then(_self.copyWith(quotedTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get bracketTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.bracketTextStyle, (value) {
    return _then(_self.copyWith(bracketTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get italicTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.italicTextStyle, (value) {
    return _then(_self.copyWith(italicTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get boldTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.boldTextStyle, (value) {
    return _then(_self.copyWith(boldTextStyle: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatTextThemeSettings].
extension ChatTextThemeSettingsPatterns on ChatTextThemeSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTextThemeSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTextThemeSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTextThemeSettings value)  $default,){
final _that = this;
switch (_that) {
case _ChatTextThemeSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTextThemeSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTextThemeSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppQuoteStyle quoteStyle,  bool enableMessageTextShadow,  int? bodyTextColorPaletteIndex,  int? bodyTextColorDarkPaletteIndex,  ChatTextStyleConfig quotedTextStyle,  ChatTextStyleConfig bracketTextStyle,  ChatTextStyleConfig italicTextStyle,  ChatTextStyleConfig boldTextStyle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTextThemeSettings() when $default != null:
return $default(_that.quoteStyle,_that.enableMessageTextShadow,_that.bodyTextColorPaletteIndex,_that.bodyTextColorDarkPaletteIndex,_that.quotedTextStyle,_that.bracketTextStyle,_that.italicTextStyle,_that.boldTextStyle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppQuoteStyle quoteStyle,  bool enableMessageTextShadow,  int? bodyTextColorPaletteIndex,  int? bodyTextColorDarkPaletteIndex,  ChatTextStyleConfig quotedTextStyle,  ChatTextStyleConfig bracketTextStyle,  ChatTextStyleConfig italicTextStyle,  ChatTextStyleConfig boldTextStyle)  $default,) {final _that = this;
switch (_that) {
case _ChatTextThemeSettings():
return $default(_that.quoteStyle,_that.enableMessageTextShadow,_that.bodyTextColorPaletteIndex,_that.bodyTextColorDarkPaletteIndex,_that.quotedTextStyle,_that.bracketTextStyle,_that.italicTextStyle,_that.boldTextStyle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppQuoteStyle quoteStyle,  bool enableMessageTextShadow,  int? bodyTextColorPaletteIndex,  int? bodyTextColorDarkPaletteIndex,  ChatTextStyleConfig quotedTextStyle,  ChatTextStyleConfig bracketTextStyle,  ChatTextStyleConfig italicTextStyle,  ChatTextStyleConfig boldTextStyle)?  $default,) {final _that = this;
switch (_that) {
case _ChatTextThemeSettings() when $default != null:
return $default(_that.quoteStyle,_that.enableMessageTextShadow,_that.bodyTextColorPaletteIndex,_that.bodyTextColorDarkPaletteIndex,_that.quotedTextStyle,_that.bracketTextStyle,_that.italicTextStyle,_that.boldTextStyle);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTextThemeSettings extends ChatTextThemeSettings {
  const _ChatTextThemeSettings({this.quoteStyle = AppQuoteStyle.curlyDouble, this.enableMessageTextShadow = false, this.bodyTextColorPaletteIndex, this.bodyTextColorDarkPaletteIndex, this.quotedTextStyle = const ChatTextStyleConfig(paletteIndex: 0, fontStyleMode: ChatTextFontStyleMode.bold, opacity: 1.0), this.bracketTextStyle = const ChatTextStyleConfig(paletteIndex: 6, fontStyleMode: ChatTextFontStyleMode.platform, opacity: 0.9), this.italicTextStyle = const ChatTextStyleConfig(paletteIndex: 1, fontStyleMode: ChatTextFontStyleMode.italic, opacity: 0.65), this.boldTextStyle = const ChatTextStyleConfig(paletteIndex: 4, fontStyleMode: ChatTextFontStyleMode.bold, opacity: 1.0)}): super._();
  

@override@JsonKey() final  AppQuoteStyle quoteStyle;
@override@JsonKey() final  bool enableMessageTextShadow;
@override final  int? bodyTextColorPaletteIndex;
@override final  int? bodyTextColorDarkPaletteIndex;
@override@JsonKey() final  ChatTextStyleConfig quotedTextStyle;
@override@JsonKey() final  ChatTextStyleConfig bracketTextStyle;
@override@JsonKey() final  ChatTextStyleConfig italicTextStyle;
@override@JsonKey() final  ChatTextStyleConfig boldTextStyle;

/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTextThemeSettingsCopyWith<_ChatTextThemeSettings> get copyWith => __$ChatTextThemeSettingsCopyWithImpl<_ChatTextThemeSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTextThemeSettings&&(identical(other.quoteStyle, quoteStyle) || other.quoteStyle == quoteStyle)&&(identical(other.enableMessageTextShadow, enableMessageTextShadow) || other.enableMessageTextShadow == enableMessageTextShadow)&&(identical(other.bodyTextColorPaletteIndex, bodyTextColorPaletteIndex) || other.bodyTextColorPaletteIndex == bodyTextColorPaletteIndex)&&(identical(other.bodyTextColorDarkPaletteIndex, bodyTextColorDarkPaletteIndex) || other.bodyTextColorDarkPaletteIndex == bodyTextColorDarkPaletteIndex)&&(identical(other.quotedTextStyle, quotedTextStyle) || other.quotedTextStyle == quotedTextStyle)&&(identical(other.bracketTextStyle, bracketTextStyle) || other.bracketTextStyle == bracketTextStyle)&&(identical(other.italicTextStyle, italicTextStyle) || other.italicTextStyle == italicTextStyle)&&(identical(other.boldTextStyle, boldTextStyle) || other.boldTextStyle == boldTextStyle));
}


@override
int get hashCode => Object.hash(runtimeType,quoteStyle,enableMessageTextShadow,bodyTextColorPaletteIndex,bodyTextColorDarkPaletteIndex,quotedTextStyle,bracketTextStyle,italicTextStyle,boldTextStyle);

@override
String toString() {
  return 'ChatTextThemeSettings(quoteStyle: $quoteStyle, enableMessageTextShadow: $enableMessageTextShadow, bodyTextColorPaletteIndex: $bodyTextColorPaletteIndex, bodyTextColorDarkPaletteIndex: $bodyTextColorDarkPaletteIndex, quotedTextStyle: $quotedTextStyle, bracketTextStyle: $bracketTextStyle, italicTextStyle: $italicTextStyle, boldTextStyle: $boldTextStyle)';
}


}

/// @nodoc
abstract mixin class _$ChatTextThemeSettingsCopyWith<$Res> implements $ChatTextThemeSettingsCopyWith<$Res> {
  factory _$ChatTextThemeSettingsCopyWith(_ChatTextThemeSettings value, $Res Function(_ChatTextThemeSettings) _then) = __$ChatTextThemeSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppQuoteStyle quoteStyle, bool enableMessageTextShadow, int? bodyTextColorPaletteIndex, int? bodyTextColorDarkPaletteIndex, ChatTextStyleConfig quotedTextStyle, ChatTextStyleConfig bracketTextStyle, ChatTextStyleConfig italicTextStyle, ChatTextStyleConfig boldTextStyle
});


@override $ChatTextStyleConfigCopyWith<$Res> get quotedTextStyle;@override $ChatTextStyleConfigCopyWith<$Res> get bracketTextStyle;@override $ChatTextStyleConfigCopyWith<$Res> get italicTextStyle;@override $ChatTextStyleConfigCopyWith<$Res> get boldTextStyle;

}
/// @nodoc
class __$ChatTextThemeSettingsCopyWithImpl<$Res>
    implements _$ChatTextThemeSettingsCopyWith<$Res> {
  __$ChatTextThemeSettingsCopyWithImpl(this._self, this._then);

  final _ChatTextThemeSettings _self;
  final $Res Function(_ChatTextThemeSettings) _then;

/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quoteStyle = null,Object? enableMessageTextShadow = null,Object? bodyTextColorPaletteIndex = freezed,Object? bodyTextColorDarkPaletteIndex = freezed,Object? quotedTextStyle = null,Object? bracketTextStyle = null,Object? italicTextStyle = null,Object? boldTextStyle = null,}) {
  return _then(_ChatTextThemeSettings(
quoteStyle: null == quoteStyle ? _self.quoteStyle : quoteStyle // ignore: cast_nullable_to_non_nullable
as AppQuoteStyle,enableMessageTextShadow: null == enableMessageTextShadow ? _self.enableMessageTextShadow : enableMessageTextShadow // ignore: cast_nullable_to_non_nullable
as bool,bodyTextColorPaletteIndex: freezed == bodyTextColorPaletteIndex ? _self.bodyTextColorPaletteIndex : bodyTextColorPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,bodyTextColorDarkPaletteIndex: freezed == bodyTextColorDarkPaletteIndex ? _self.bodyTextColorDarkPaletteIndex : bodyTextColorDarkPaletteIndex // ignore: cast_nullable_to_non_nullable
as int?,quotedTextStyle: null == quotedTextStyle ? _self.quotedTextStyle : quotedTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,bracketTextStyle: null == bracketTextStyle ? _self.bracketTextStyle : bracketTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,italicTextStyle: null == italicTextStyle ? _self.italicTextStyle : italicTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,boldTextStyle: null == boldTextStyle ? _self.boldTextStyle : boldTextStyle // ignore: cast_nullable_to_non_nullable
as ChatTextStyleConfig,
  ));
}

/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get quotedTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.quotedTextStyle, (value) {
    return _then(_self.copyWith(quotedTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get bracketTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.bracketTextStyle, (value) {
    return _then(_self.copyWith(bracketTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get italicTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.italicTextStyle, (value) {
    return _then(_self.copyWith(italicTextStyle: value));
  });
}/// Create a copy of ChatTextThemeSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextStyleConfigCopyWith<$Res> get boldTextStyle {
  
  return $ChatTextStyleConfigCopyWith<$Res>(_self.boldTextStyle, (value) {
    return _then(_self.copyWith(boldTextStyle: value));
  });
}
}

/// @nodoc
mixin _$AppThemeConfig {

 int get themeColorIndex;/// 用户自定义字体族名称，null 表示使用系统默认字体
 String? get customFontFamily; ChatTextThemeSettings get chatTextTheme;
/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppThemeConfigCopyWith<AppThemeConfig> get copyWith => _$AppThemeConfigCopyWithImpl<AppThemeConfig>(this as AppThemeConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppThemeConfig&&(identical(other.themeColorIndex, themeColorIndex) || other.themeColorIndex == themeColorIndex)&&(identical(other.customFontFamily, customFontFamily) || other.customFontFamily == customFontFamily)&&(identical(other.chatTextTheme, chatTextTheme) || other.chatTextTheme == chatTextTheme));
}


@override
int get hashCode => Object.hash(runtimeType,themeColorIndex,customFontFamily,chatTextTheme);

@override
String toString() {
  return 'AppThemeConfig(themeColorIndex: $themeColorIndex, customFontFamily: $customFontFamily, chatTextTheme: $chatTextTheme)';
}


}

/// @nodoc
abstract mixin class $AppThemeConfigCopyWith<$Res>  {
  factory $AppThemeConfigCopyWith(AppThemeConfig value, $Res Function(AppThemeConfig) _then) = _$AppThemeConfigCopyWithImpl;
@useResult
$Res call({
 int themeColorIndex, String? customFontFamily, ChatTextThemeSettings chatTextTheme
});


$ChatTextThemeSettingsCopyWith<$Res> get chatTextTheme;

}
/// @nodoc
class _$AppThemeConfigCopyWithImpl<$Res>
    implements $AppThemeConfigCopyWith<$Res> {
  _$AppThemeConfigCopyWithImpl(this._self, this._then);

  final AppThemeConfig _self;
  final $Res Function(AppThemeConfig) _then;

/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeColorIndex = null,Object? customFontFamily = freezed,Object? chatTextTheme = null,}) {
  return _then(_self.copyWith(
themeColorIndex: null == themeColorIndex ? _self.themeColorIndex : themeColorIndex // ignore: cast_nullable_to_non_nullable
as int,customFontFamily: freezed == customFontFamily ? _self.customFontFamily : customFontFamily // ignore: cast_nullable_to_non_nullable
as String?,chatTextTheme: null == chatTextTheme ? _self.chatTextTheme : chatTextTheme // ignore: cast_nullable_to_non_nullable
as ChatTextThemeSettings,
  ));
}
/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextThemeSettingsCopyWith<$Res> get chatTextTheme {
  
  return $ChatTextThemeSettingsCopyWith<$Res>(_self.chatTextTheme, (value) {
    return _then(_self.copyWith(chatTextTheme: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppThemeConfig].
extension AppThemeConfigPatterns on AppThemeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppThemeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppThemeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppThemeConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppThemeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppThemeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppThemeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int themeColorIndex,  String? customFontFamily,  ChatTextThemeSettings chatTextTheme)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppThemeConfig() when $default != null:
return $default(_that.themeColorIndex,_that.customFontFamily,_that.chatTextTheme);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int themeColorIndex,  String? customFontFamily,  ChatTextThemeSettings chatTextTheme)  $default,) {final _that = this;
switch (_that) {
case _AppThemeConfig():
return $default(_that.themeColorIndex,_that.customFontFamily,_that.chatTextTheme);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int themeColorIndex,  String? customFontFamily,  ChatTextThemeSettings chatTextTheme)?  $default,) {final _that = this;
switch (_that) {
case _AppThemeConfig() when $default != null:
return $default(_that.themeColorIndex,_that.customFontFamily,_that.chatTextTheme);case _:
  return null;

}
}

}

/// @nodoc


class _AppThemeConfig extends AppThemeConfig {
  const _AppThemeConfig({required this.themeColorIndex, this.customFontFamily, this.chatTextTheme = const ChatTextThemeSettings()}): super._();
  

@override final  int themeColorIndex;
/// 用户自定义字体族名称，null 表示使用系统默认字体
@override final  String? customFontFamily;
@override@JsonKey() final  ChatTextThemeSettings chatTextTheme;

/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppThemeConfigCopyWith<_AppThemeConfig> get copyWith => __$AppThemeConfigCopyWithImpl<_AppThemeConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppThemeConfig&&(identical(other.themeColorIndex, themeColorIndex) || other.themeColorIndex == themeColorIndex)&&(identical(other.customFontFamily, customFontFamily) || other.customFontFamily == customFontFamily)&&(identical(other.chatTextTheme, chatTextTheme) || other.chatTextTheme == chatTextTheme));
}


@override
int get hashCode => Object.hash(runtimeType,themeColorIndex,customFontFamily,chatTextTheme);

@override
String toString() {
  return 'AppThemeConfig(themeColorIndex: $themeColorIndex, customFontFamily: $customFontFamily, chatTextTheme: $chatTextTheme)';
}


}

/// @nodoc
abstract mixin class _$AppThemeConfigCopyWith<$Res> implements $AppThemeConfigCopyWith<$Res> {
  factory _$AppThemeConfigCopyWith(_AppThemeConfig value, $Res Function(_AppThemeConfig) _then) = __$AppThemeConfigCopyWithImpl;
@override @useResult
$Res call({
 int themeColorIndex, String? customFontFamily, ChatTextThemeSettings chatTextTheme
});


@override $ChatTextThemeSettingsCopyWith<$Res> get chatTextTheme;

}
/// @nodoc
class __$AppThemeConfigCopyWithImpl<$Res>
    implements _$AppThemeConfigCopyWith<$Res> {
  __$AppThemeConfigCopyWithImpl(this._self, this._then);

  final _AppThemeConfig _self;
  final $Res Function(_AppThemeConfig) _then;

/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeColorIndex = null,Object? customFontFamily = freezed,Object? chatTextTheme = null,}) {
  return _then(_AppThemeConfig(
themeColorIndex: null == themeColorIndex ? _self.themeColorIndex : themeColorIndex // ignore: cast_nullable_to_non_nullable
as int,customFontFamily: freezed == customFontFamily ? _self.customFontFamily : customFontFamily // ignore: cast_nullable_to_non_nullable
as String?,chatTextTheme: null == chatTextTheme ? _self.chatTextTheme : chatTextTheme // ignore: cast_nullable_to_non_nullable
as ChatTextThemeSettings,
  ));
}

/// Create a copy of AppThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextThemeSettingsCopyWith<$Res> get chatTextTheme {
  
  return $ChatTextThemeSettingsCopyWith<$Res>(_self.chatTextTheme, (value) {
    return _then(_self.copyWith(chatTextTheme: value));
  });
}
}

/// @nodoc
mixin _$AppSettings {

 AppColorMode get colorMode; AppThemePreset get themePreset; Map<AppThemePreset, AppThemeConfig> get themeConfigs;/// 是否显示聊天头像
 bool get showAvatar;/// 聊天背景透明度 (0.0 - 1.0)
 double get backgroundOpacity;/// 输入框是否使用毛玻璃效果
 bool get inputGlassEffect;/// 是否在 API 状态弹窗中显示请求日志入口
 bool get showApiRequestLogEntry;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.colorMode, colorMode) || other.colorMode == colorMode)&&(identical(other.themePreset, themePreset) || other.themePreset == themePreset)&&const DeepCollectionEquality().equals(other.themeConfigs, themeConfigs)&&(identical(other.showAvatar, showAvatar) || other.showAvatar == showAvatar)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.inputGlassEffect, inputGlassEffect) || other.inputGlassEffect == inputGlassEffect)&&(identical(other.showApiRequestLogEntry, showApiRequestLogEntry) || other.showApiRequestLogEntry == showApiRequestLogEntry));
}


@override
int get hashCode => Object.hash(runtimeType,colorMode,themePreset,const DeepCollectionEquality().hash(themeConfigs),showAvatar,backgroundOpacity,inputGlassEffect,showApiRequestLogEntry);

@override
String toString() {
  return 'AppSettings(colorMode: $colorMode, themePreset: $themePreset, themeConfigs: $themeConfigs, showAvatar: $showAvatar, backgroundOpacity: $backgroundOpacity, inputGlassEffect: $inputGlassEffect, showApiRequestLogEntry: $showApiRequestLogEntry)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppColorMode colorMode, AppThemePreset themePreset, Map<AppThemePreset, AppThemeConfig> themeConfigs, bool showAvatar, double backgroundOpacity, bool inputGlassEffect, bool showApiRequestLogEntry
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? colorMode = null,Object? themePreset = null,Object? themeConfigs = null,Object? showAvatar = null,Object? backgroundOpacity = null,Object? inputGlassEffect = null,Object? showApiRequestLogEntry = null,}) {
  return _then(_self.copyWith(
colorMode: null == colorMode ? _self.colorMode : colorMode // ignore: cast_nullable_to_non_nullable
as AppColorMode,themePreset: null == themePreset ? _self.themePreset : themePreset // ignore: cast_nullable_to_non_nullable
as AppThemePreset,themeConfigs: null == themeConfigs ? _self.themeConfigs : themeConfigs // ignore: cast_nullable_to_non_nullable
as Map<AppThemePreset, AppThemeConfig>,showAvatar: null == showAvatar ? _self.showAvatar : showAvatar // ignore: cast_nullable_to_non_nullable
as bool,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,inputGlassEffect: null == inputGlassEffect ? _self.inputGlassEffect : inputGlassEffect // ignore: cast_nullable_to_non_nullable
as bool,showApiRequestLogEntry: null == showApiRequestLogEntry ? _self.showApiRequestLogEntry : showApiRequestLogEntry // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppColorMode colorMode,  AppThemePreset themePreset,  Map<AppThemePreset, AppThemeConfig> themeConfigs,  bool showAvatar,  double backgroundOpacity,  bool inputGlassEffect,  bool showApiRequestLogEntry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.colorMode,_that.themePreset,_that.themeConfigs,_that.showAvatar,_that.backgroundOpacity,_that.inputGlassEffect,_that.showApiRequestLogEntry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppColorMode colorMode,  AppThemePreset themePreset,  Map<AppThemePreset, AppThemeConfig> themeConfigs,  bool showAvatar,  double backgroundOpacity,  bool inputGlassEffect,  bool showApiRequestLogEntry)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.colorMode,_that.themePreset,_that.themeConfigs,_that.showAvatar,_that.backgroundOpacity,_that.inputGlassEffect,_that.showApiRequestLogEntry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppColorMode colorMode,  AppThemePreset themePreset,  Map<AppThemePreset, AppThemeConfig> themeConfigs,  bool showAvatar,  double backgroundOpacity,  bool inputGlassEffect,  bool showApiRequestLogEntry)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.colorMode,_that.themePreset,_that.themeConfigs,_that.showAvatar,_that.backgroundOpacity,_that.inputGlassEffect,_that.showApiRequestLogEntry);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings extends AppSettings {
  const _AppSettings({this.colorMode = AppColorMode.system, this.themePreset = AppThemePreset.sunset, final  Map<AppThemePreset, AppThemeConfig> themeConfigs = defaultAppThemeConfigs, this.showAvatar = true, this.backgroundOpacity = 0.85, this.inputGlassEffect = true, this.showApiRequestLogEntry = true}): _themeConfigs = themeConfigs,super._();
  

@override@JsonKey() final  AppColorMode colorMode;
@override@JsonKey() final  AppThemePreset themePreset;
 final  Map<AppThemePreset, AppThemeConfig> _themeConfigs;
@override@JsonKey() Map<AppThemePreset, AppThemeConfig> get themeConfigs {
  if (_themeConfigs is EqualUnmodifiableMapView) return _themeConfigs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_themeConfigs);
}

/// 是否显示聊天头像
@override@JsonKey() final  bool showAvatar;
/// 聊天背景透明度 (0.0 - 1.0)
@override@JsonKey() final  double backgroundOpacity;
/// 输入框是否使用毛玻璃效果
@override@JsonKey() final  bool inputGlassEffect;
/// 是否在 API 状态弹窗中显示请求日志入口
@override@JsonKey() final  bool showApiRequestLogEntry;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.colorMode, colorMode) || other.colorMode == colorMode)&&(identical(other.themePreset, themePreset) || other.themePreset == themePreset)&&const DeepCollectionEquality().equals(other._themeConfigs, _themeConfigs)&&(identical(other.showAvatar, showAvatar) || other.showAvatar == showAvatar)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.inputGlassEffect, inputGlassEffect) || other.inputGlassEffect == inputGlassEffect)&&(identical(other.showApiRequestLogEntry, showApiRequestLogEntry) || other.showApiRequestLogEntry == showApiRequestLogEntry));
}


@override
int get hashCode => Object.hash(runtimeType,colorMode,themePreset,const DeepCollectionEquality().hash(_themeConfigs),showAvatar,backgroundOpacity,inputGlassEffect,showApiRequestLogEntry);

@override
String toString() {
  return 'AppSettings(colorMode: $colorMode, themePreset: $themePreset, themeConfigs: $themeConfigs, showAvatar: $showAvatar, backgroundOpacity: $backgroundOpacity, inputGlassEffect: $inputGlassEffect, showApiRequestLogEntry: $showApiRequestLogEntry)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppColorMode colorMode, AppThemePreset themePreset, Map<AppThemePreset, AppThemeConfig> themeConfigs, bool showAvatar, double backgroundOpacity, bool inputGlassEffect, bool showApiRequestLogEntry
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? colorMode = null,Object? themePreset = null,Object? themeConfigs = null,Object? showAvatar = null,Object? backgroundOpacity = null,Object? inputGlassEffect = null,Object? showApiRequestLogEntry = null,}) {
  return _then(_AppSettings(
colorMode: null == colorMode ? _self.colorMode : colorMode // ignore: cast_nullable_to_non_nullable
as AppColorMode,themePreset: null == themePreset ? _self.themePreset : themePreset // ignore: cast_nullable_to_non_nullable
as AppThemePreset,themeConfigs: null == themeConfigs ? _self._themeConfigs : themeConfigs // ignore: cast_nullable_to_non_nullable
as Map<AppThemePreset, AppThemeConfig>,showAvatar: null == showAvatar ? _self.showAvatar : showAvatar // ignore: cast_nullable_to_non_nullable
as bool,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,inputGlassEffect: null == inputGlassEffect ? _self.inputGlassEffect : inputGlassEffect // ignore: cast_nullable_to_non_nullable
as bool,showApiRequestLogEntry: null == showApiRequestLogEntry ? _self.showApiRequestLogEntry : showApiRequestLogEntry // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
