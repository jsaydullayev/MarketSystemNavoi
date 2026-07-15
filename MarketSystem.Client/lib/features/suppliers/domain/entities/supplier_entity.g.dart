// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplierEntity _$SupplierEntityFromJson(Map<String, dynamic> json) =>
    SupplierEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      comment: json['comment'] as String?,
      outstandingDebt: json['outstandingDebt'] == null
          ? 0
          : const FlexibleDoubleConverter().fromJson(json['outstandingDebt']),
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SupplierEntityToJson(SupplierEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
      'comment': instance.comment,
      'outstandingDebt': const FlexibleDoubleConverter().toJson(
        instance.outstandingDebt,
      ),
      'receiptCount': instance.receiptCount,
    };
