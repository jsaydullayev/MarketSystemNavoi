/// Payment Entity
/// To'lov obyekti

import 'package:equatable/equatable.dart';

/// To'lov turlari
enum PaymentType {
  cash,
  card,
  transfer,
}

/// Payment Entity - to'lov obyekti
class PaymentEntity extends Equatable {
  final String id;
  final String saleId;
  final PaymentType paymentType;
  final double amount;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.saleId,
    required this.paymentType,
    required this.amount,
    required this.createdAt,
  });

  /// JSON dan PaymentEntity yaratish
  factory PaymentEntity.fromJson(Map<String, dynamic> json) {
    return PaymentEntity(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      paymentType: _parsePaymentType(json['paymentType'] as String?),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Payment type string dan enum ga o'tkazish
  static PaymentType _parsePaymentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'cash':
        return PaymentType.cash;
      case 'card':
        return PaymentType.card;
      case 'transfer':
        return PaymentType.transfer;
      default:
        return PaymentType.cash;
    }
  }

  /// Payment type enum dan string ga o'tkazish
  String getPaymentTypeText() {
    switch (paymentType) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.card:
        return 'card';
      case PaymentType.transfer:
        return 'transfer';
    }
  }

  /// To'lov turi nomini olish
  String getPaymentTypeName() {
    switch (paymentType) {
      case PaymentType.cash:
        return 'Naqd';
      case PaymentType.card:
        return 'Plastik';
      case PaymentType.transfer:
        return 'O\'tkazma';
    }
  }

  @override
  List<Object?> get props => [id, saleId, paymentType, amount, createdAt];
}
