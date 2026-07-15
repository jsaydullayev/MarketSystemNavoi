import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'zakup_receipt_entity.g.dart';

/// One product line of a goods-receipt. Cost fields arrive as 0 for Sellers
/// (server redacts them) — the FlexibleDoubleConverter maps the absent keys to 0.
@JsonSerializable()
class ZakupReceiptLineEntity extends Equatable {
  final String id;
  final String productId;
  @JsonKey(defaultValue: '')
  final String productName;
  @FlexibleDoubleConverter()
  final double quantity;
  @FlexibleDoubleConverter()
  final double costPrice;
  @FlexibleDoubleConverter()
  final double lineTotal;

  const ZakupReceiptLineEntity({
    required this.id,
    required this.productId,
    this.productName = '',
    this.quantity = 0,
    this.costPrice = 0,
    this.lineTotal = 0,
  });

  factory ZakupReceiptLineEntity.fromJson(Map<String, dynamic> json) =>
      _$ZakupReceiptLineEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ZakupReceiptLineEntityToJson(this);

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    costPrice,
    lineTotal,
  ];
}

/// A goods-receipt (priyomka) header + its lines — mirrors the backend
/// ZakupReceiptDto. Money/payment fields are 0 / "Unpaid" for Sellers.
@JsonSerializable(explicitToJson: true)
class ZakupReceiptEntity extends Equatable {
  final String id;
  final String? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  @FlexibleDoubleConverter()
  final double totalAmount;
  @FlexibleDoubleConverter()
  final double paidAmount;
  @FlexibleDoubleConverter()
  final double outstandingAmount;
  @JsonKey(defaultValue: 'Unpaid')
  final String paymentStatus;
  final String? comment;
  @JsonKey(defaultValue: 0)
  final int itemCount;
  @IsoDateTimeConverter()
  final DateTime createdAt;
  @JsonKey(defaultValue: '')
  final String createdBy;
  @JsonKey(defaultValue: [])
  final List<ZakupReceiptLineEntity> items;

  const ZakupReceiptEntity({
    required this.id,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.paymentStatus = 'Unpaid',
    this.comment,
    this.itemCount = 0,
    required this.createdAt,
    this.createdBy = '',
    this.items = const [],
  });

  factory ZakupReceiptEntity.fromJson(Map<String, dynamic> json) =>
      _$ZakupReceiptEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ZakupReceiptEntityToJson(this);

  bool get isPaid => paymentStatus == 'Paid';
  bool get isPartial => paymentStatus == 'Partial';
  bool get isUnpaid => paymentStatus == 'Unpaid';

  @override
  List<Object?> get props => [
    id,
    supplierId,
    supplierName,
    invoiceNumber,
    totalAmount,
    paidAmount,
    outstandingAmount,
    paymentStatus,
    comment,
    itemCount,
    createdAt,
    createdBy,
    items,
  ];
}
