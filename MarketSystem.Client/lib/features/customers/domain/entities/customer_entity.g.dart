// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerEntity _$CustomerEntityFromJson(Map<String, dynamic> json) =>
    CustomerEntity(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String?,
      comment: json['comment'] as String?,
      totalDebt: json['totalDebt'] == null
          ? 0
          : const FlexibleDoubleConverter().fromJson(json['totalDebt']),
      createdAt: const IsoDateTimeConverter().fromJson(json['createdAt']),
      updatedAt:
          const NullableIsoDateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$CustomerEntityToJson(CustomerEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'fullName': instance.fullName,
      'comment': instance.comment,
      'totalDebt': const FlexibleDoubleConverter().toJson(instance.totalDebt),
      'createdAt': const IsoDateTimeConverter().toJson(instance.createdAt),
      'updatedAt':
          const NullableIsoDateTimeConverter().toJson(instance.updatedAt),
    };
