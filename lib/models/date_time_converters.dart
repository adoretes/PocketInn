import 'package:json_annotation/json_annotation.dart';

/// Converts nullable DateTime? to/from ISO string, using tryParse (null on failure).
class NullableDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  @override
  String? toJson(DateTime? value) => value?.toIso8601String();
}
