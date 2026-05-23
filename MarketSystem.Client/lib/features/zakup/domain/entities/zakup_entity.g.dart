// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zakup_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZakupEntity _$ZakupEntityFromJson(Map<String, dynamic> json) => ZakupEntity(
  id: json['id'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String? ?? '',
  quantity: const FlexibleDoubleConverter().fromJson(json['quantity']),
  costPrice: const FlexibleDoubleConverter().fromJson(json['costPrice']),
  createdAt: const IsoDateTimeConverter().fromJson(json['createdAt']),
  createdBy: json['createdBy'] as String? ?? "Noma'lum",
);

Map<String, dynamic> _$ZakupEntityToJson(ZakupEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': const FlexibleDoubleConverter().toJson(instance.quantity),
      'costPrice': const FlexibleDoubleConverter().toJson(instance.costPrice),
      'createdAt': const IsoDateTimeConverter().toJson(instance.createdAt),
      'createdBy': instance.createdBy,
    };
