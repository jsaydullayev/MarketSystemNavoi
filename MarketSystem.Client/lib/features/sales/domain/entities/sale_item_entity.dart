/// Sale Item Entity
/// Sotuvdagi mahsulot obyekti

import 'package:equatable/equatable.dart';

/// Sale Item Entity - sotuvdagi bitta mahsulot
class SaleItemEntity extends Equatable {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double quantity;      // ✅ DECIMAL - 22.5 m, 15.5 kg bo'lishi mumkin
  final double salePrice;
  final double totalPrice;
  final String? comment;

  const SaleItemEntity({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salePrice,
    required this.totalPrice,
    this.comment,
  });

  /// JSON dan SaleItemEntity yaratish
  factory SaleItemEntity.fromJson(Map<String, dynamic> json) {
    return SaleItemEntity(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toDouble() : 0.0,  // ✅ DECIMAL
      salePrice: (json['salePrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      comment: json['comment'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        saleId,
        productId,
        productName,
        quantity,
        salePrice,
        totalPrice,
        comment,
      ];
}
