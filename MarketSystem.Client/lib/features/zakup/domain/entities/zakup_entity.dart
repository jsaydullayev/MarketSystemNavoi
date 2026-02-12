/// Zakup Entity
/// Xarid (Zakup) obyekti - biznes mantik uchun asosiy model

import 'package:equatable/equatable.dart';

/// Zakup Entity - xarid obyekti
class ZakupEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double costPrice;
  final double totalCost;
  final DateTime createdAt;
  final String? createdByAdminId;
  final String? createdByName;

  const ZakupEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.totalCost,
    required this.createdAt,
    this.createdByAdminId,
    this.createdByName,
  });

  /// JSON dan ZakupEntity yaratish
  factory ZakupEntity.fromJson(Map<String, dynamic> json) {
    return ZakupEntity(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int,
      costPrice: (json['costPrice'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByAdminId: json['createdByAdminId'] as String?,
      createdByName: json['createdByName'] as String?,
    );
  }

  /// Jami narxni formatlash
  String getFormattedTotalCost() {
    return totalCost.toStringAsFixed(2);
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
      'totalCost': totalCost,
      'createdAt': createdAt.toIso8601String(),
      'createdByAdminId': createdByAdminId,
      'createdByName': createdByName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        costPrice,
        totalCost,
        createdAt,
        createdByAdminId,
        createdByName,
      ];
}
