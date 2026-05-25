import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'sale_entity.g.dart';

enum SaleStatus { draft, paid, debt, closed, cancelled }

// SaleStatusConverter lives here (not in json_converters.dart) to avoid a
// circular import: json_converters ↔ sale_entity.
class SaleStatusConverter implements JsonConverter<SaleStatus, dynamic> {
  const SaleStatusConverter();

  @override
  SaleStatus fromJson(dynamic value) {
    // Backend sends PascalCase ("Draft"); toLowerCase() keeps us safe if
    // that ever changes to ALL_CAPS or camelCase.
    switch (value?.toString().toLowerCase()) {
      case 'paid':
        return SaleStatus.paid;
      case 'debt':
        return SaleStatus.debt;
      case 'closed':
        return SaleStatus.closed;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.draft;
    }
  }

  @override
  dynamic toJson(SaleStatus value) => value.name;
}

/// Sale Entity - asosiy sotuv obyekti
@JsonSerializable()
class SaleEntity extends Equatable {
  final String id;
  final String? customerId;
  final String sellerId;
  final String? customerName;
  final String? customerPhone;
  @FlexibleDoubleConverter()
  final double totalAmount;
  @FlexibleDoubleConverter()
  final double paidAmount;
  @FlexibleDoubleConverter()
  final double remainingAmount;
  @SaleStatusConverter()
  final SaleStatus status;
  @IsoDateTimeConverter()
  final DateTime createdAt;
  final String? sellerName;

  const SaleEntity({
    required this.id,
    this.customerId,
    required this.sellerId,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    this.sellerName,
  });

  factory SaleEntity.fromJson(Map<String, dynamic> json) =>
      _$SaleEntityFromJson(json);

  Map<String, dynamic> toJson() => _$SaleEntityToJson(this);

  bool hasDebt() => remainingAmount > 0;

  bool isFullyPaid() => remainingAmount <= 0;

  String getStatusText() => status.name;

  @override
  List<Object?> get props => [
    id,
    customerId,
    sellerId,
    customerName,
    customerPhone,
    totalAmount,
    paidAmount,
    remainingAmount,
    status,
    createdAt,
    sellerName,
  ];
}
