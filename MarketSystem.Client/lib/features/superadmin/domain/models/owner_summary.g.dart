// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnerSummary _$OwnerSummaryFromJson(Map<String, dynamic> json) => OwnerSummary(
  userId: json['userId'] as String,
  fullName: json['fullName'] as String? ?? '',
  username: json['username'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? false,
  createdAt: const UtcIsoDateTimeConverter().fromJson(json['createdAt']),
  phone: json['phone'] as String?,
  marketId: (json['marketId'] as num?)?.toInt(),
  marketName: json['marketName'] as String?,
  isMarketBlocked: json['isMarketBlocked'] as bool? ?? false,
);

Map<String, dynamic> _$OwnerSummaryToJson(OwnerSummary instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'username': instance.username,
      'phone': instance.phone,
      'isActive': instance.isActive,
      'marketId': instance.marketId,
      'marketName': instance.marketName,
      'isMarketBlocked': instance.isMarketBlocked,
      'createdAt': const UtcIsoDateTimeConverter().toJson(instance.createdAt),
    };
