/// Zakup Entity
/// Xarid (Zakup) obyekti - biznes mantik uchun asosiy model

import 'package:equatable/equatable.dart';

/// Zakup Entity - xarid obyekti
class ZakupEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double costPrice;
  final DateTime createdAt;
  final String createdBy;

  const ZakupEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.createdAt,
    required this.createdBy,
  });

  /// JSON dan ZakupEntity yaratish
  factory ZakupEntity.fromJson(Map<String, dynamic> json) {
    return ZakupEntity(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
      costPrice: (json['costPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String? ?? 'Noma\'lum',
    );
  }

  /// Narxni formatlash
  String getFormattedCostPrice() {
    return costPrice.toStringAsFixed(2);
  }

  /// ZakupEntity ni JSON ga aylantirish
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'costPrice': costPrice,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        costPrice,
        createdAt,
        createdBy,
      ];
}
