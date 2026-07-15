import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'supplier_entity.g.dart';

/// Yetkazib beruvchi (goods supplier) — mirrors the backend SupplierDto.
@JsonSerializable()
class SupplierEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? comment;

  /// How much the shop still owes this supplier (0 for Sellers — redacted).
  @FlexibleDoubleConverter()
  final double outstandingDebt;

  final int receiptCount;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.comment,
    this.outstandingDebt = 0,
    this.receiptCount = 0,
  });

  factory SupplierEntity.fromJson(Map<String, dynamic> json) =>
      _$SupplierEntityFromJson(json);

  Map<String, dynamic> toJson() => _$SupplierEntityToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    address,
    comment,
    outstandingDebt,
    receiptCount,
  ];
}
