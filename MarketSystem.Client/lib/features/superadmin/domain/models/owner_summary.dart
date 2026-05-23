import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'owner_summary.g.dart';

/// Mirror of the backend's `OwnerSummaryDto`.
@JsonSerializable()
class OwnerSummary {
  final String userId;
  @JsonKey(defaultValue: '')
  final String fullName;
  @JsonKey(defaultValue: '')
  final String username;
  final String? phone;
  @JsonKey(defaultValue: false)
  final bool isActive;
  final int? marketId;
  final String? marketName;
  /// True when the SuperAdmin has administratively blocked this owner's
  /// market (e.g. non-payment). Defaulted false so older API responses
  /// without the field decode safely.
  @JsonKey(defaultValue: false)
  final bool isMarketBlocked;
  @UtcIsoDateTimeConverter()
  final DateTime createdAt;

  OwnerSummary({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.isActive,
    required this.createdAt,
    this.phone,
    this.marketId,
    this.marketName,
    this.isMarketBlocked = false,
  });

  factory OwnerSummary.fromJson(Map<String, dynamic> json) =>
      _$OwnerSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OwnerSummaryToJson(this);
}
