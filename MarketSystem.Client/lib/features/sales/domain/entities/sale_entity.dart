/// Sale Entity
/// Sotuv obyekti - biznes mantik uchun asosiy model

import 'package:equatable/equatable.dart';

/// Sale holatlari
enum SaleStatus {
  draft,
  paid,
  debt,
  cancelled,
}

/// Sale Entity - asosiy sotuv obyekti
class SaleEntity extends Equatable {
  final String id;
  final String? customerId;
  final String sellerId;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final SaleStatus status;
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

  /// JSON dan SaleEntity yaratish
  factory SaleEntity.fromJson(Map<String, dynamic> json) {
    return SaleEntity(
      id: json['id'] as String,
      customerId: json['customerId'] as String?,
      sellerId: json['sellerId'] as String,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sellerName: json['sellerName'] as String?,
    );
  }

  /// Status string dan enum ga o'tkazish
  static SaleStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return SaleStatus.draft;
      case 'paid':
        return SaleStatus.paid;
      case 'debt':
        return SaleStatus.debt;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.draft;
    }
  }

  /// Status enum dan string ga o'tkazish
  String getStatusText() {
    switch (status) {
      case SaleStatus.draft:
        return 'draft';
      case SaleStatus.paid:
        return 'paid';
      case SaleStatus.debt:
        return 'debt';
      case SaleStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Qarzdorlik borligini tekshirish
  bool hasDebt() => remainingAmount > 0;

  /// To'liq to'langanligini tekshirish
  bool isFullyPaid() => remainingAmount <= 0;

  /// SaleEntity ni JSON ga aylantirish
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'sellerId': sellerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': getStatusText(),
      'createdAt': createdAt.toIso8601String(),
      'sellerName': sellerName,
    };
  }

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
