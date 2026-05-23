import 'package:json_annotation/json_annotation.dart';

// ---------------------------------------------------------------------------
// Reusable json_annotation converters for @JsonSerializable classes.
//
// Why custom converters instead of relying on json_serializable defaults?
//
// 1. FlexibleDoubleConverter — the .NET backend can serialize numeric fields
//    as either JSON numbers (int/double) or strings depending on the route.
//    The generated default casts to double and throws on int values.
//
// 2. IsoDateTimeConverter — guards against null with a DateTime.now() fallback
//    (matching the previous hand-rolled behaviour) and handles the edge case
//    where a DateTime object is passed through in-process unit tests.
//
// Note: SaleStatusConverter lives in sale_entity.dart to avoid a circular
// import (sale_entity would otherwise import this file which imports it back).
// ---------------------------------------------------------------------------

/// Converts a JSON value that may be int, double, String, or null to double.
class FlexibleDoubleConverter implements JsonConverter<double, dynamic> {
  const FlexibleDoubleConverter();

  @override
  double fromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  dynamic toJson(double value) => value;
}

/// Nullable variant: returns null instead of 0.0 for missing values.
class FlexibleNullableDoubleConverter implements JsonConverter<double?, dynamic> {
  const FlexibleNullableDoubleConverter();

  @override
  double? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  dynamic toJson(double? value) => value;
}

/// Converts a JSON value that may be String or null to a non-null DateTime.
/// Falls back to DateTime.now() when the field is absent, matching the
/// previous hand-rolled behaviour across all affected entities.
class IsoDateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const IsoDateTimeConverter();

  @override
  DateTime fromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  @override
  dynamic toJson(DateTime value) => value.toIso8601String();
}

/// Nullable DateTime: returns null for absent/null values.
class NullableIsoDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableIsoDateTimeConverter();

  @override
  DateTime? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  @override
  dynamic toJson(DateTime? value) => value?.toIso8601String();
}

/// Like IsoDateTimeConverter but always returns a UTC DateTime.
/// Used for fields where explicit UTC is semantically important
/// (e.g. audit timestamps displayed in the SuperAdmin console).
class UtcIsoDateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const UtcIsoDateTimeConverter();

  @override
  DateTime fromJson(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }

  @override
  dynamic toJson(DateTime value) => value.toIso8601String();
}

