// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleEntity _$SaleEntityFromJson(Map<String, dynamic> json) => SaleEntity(
  id: json['id'] as String,
  customerId: json['customerId'] as String?,
  sellerId: json['sellerId'] as String,
  customerName: json['customerName'] as String?,
  customerPhone: json['customerPhone'] as String?,
  totalAmount: const FlexibleDoubleConverter().fromJson(json['totalAmount']),
  paidAmount: const FlexibleDoubleConverter().fromJson(json['paidAmount']),
  remainingAmount: const FlexibleDoubleConverter().fromJson(
    json['remainingAmount'],
  ),
  status: const SaleStatusConverter().fromJson(json['status']),
  createdAt: const IsoDateTimeConverter().fromJson(json['createdAt']),
  sellerName: json['sellerName'] as String?,
);

Map<String, dynamic> _$SaleEntityToJson(
  SaleEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'customerId': instance.customerId,
  'sellerId': instance.sellerId,
  'customerName': instance.customerName,
  'customerPhone': instance.customerPhone,
  'totalAmount': const FlexibleDoubleConverter().toJson(instance.totalAmount),
  'paidAmount': const FlexibleDoubleConverter().toJson(instance.paidAmount),
  'remainingAmount': const FlexibleDoubleConverter().toJson(
    instance.remainingAmount,
  ),
  'status': const SaleStatusConverter().toJson(instance.status),
  'createdAt': const IsoDateTimeConverter().toJson(instance.createdAt),
  'sellerName': instance.sellerName,
};
