// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zakup_receipt_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZakupReceiptLineEntity _$ZakupReceiptLineEntityFromJson(
  Map<String, dynamic> json,
) => ZakupReceiptLineEntity(
  id: json['id'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String? ?? '',
  quantity: json['quantity'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['quantity']),
  costPrice: json['costPrice'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['costPrice']),
  lineTotal: json['lineTotal'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['lineTotal']),
);

Map<String, dynamic> _$ZakupReceiptLineEntityToJson(
  ZakupReceiptLineEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'productName': instance.productName,
  'quantity': const FlexibleDoubleConverter().toJson(instance.quantity),
  'costPrice': const FlexibleDoubleConverter().toJson(instance.costPrice),
  'lineTotal': const FlexibleDoubleConverter().toJson(instance.lineTotal),
};

ZakupReceiptEntity _$ZakupReceiptEntityFromJson(Map<String, dynamic> json) =>
    ZakupReceiptEntity(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      totalAmount: json['totalAmount'] == null
          ? 0
          : const FlexibleDoubleConverter().fromJson(json['totalAmount']),
      paidAmount: json['paidAmount'] == null
          ? 0
          : const FlexibleDoubleConverter().fromJson(json['paidAmount']),
      outstandingAmount: json['outstandingAmount'] == null
          ? 0
          : const FlexibleDoubleConverter().fromJson(json['outstandingAmount']),
      paymentStatus: json['paymentStatus'] as String? ?? 'Unpaid',
      comment: json['comment'] as String?,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: const IsoDateTimeConverter().fromJson(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ZakupReceiptLineEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$ZakupReceiptEntityToJson(
  ZakupReceiptEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'supplierId': instance.supplierId,
  'supplierName': instance.supplierName,
  'invoiceNumber': instance.invoiceNumber,
  'totalAmount': const FlexibleDoubleConverter().toJson(instance.totalAmount),
  'paidAmount': const FlexibleDoubleConverter().toJson(instance.paidAmount),
  'outstandingAmount': const FlexibleDoubleConverter().toJson(
    instance.outstandingAmount,
  ),
  'paymentStatus': instance.paymentStatus,
  'comment': instance.comment,
  'itemCount': instance.itemCount,
  'createdAt': const IsoDateTimeConverter().toJson(instance.createdAt),
  'createdBy': instance.createdBy,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
