/// Product Entity
/// Core domain entity for product
library;

import 'package:equatable/equatable.dart';

/// Product domain entity
class ProductEntity extends Equatable {
  final int id;
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final double quantity;      // ✅ DECIMAL - 1.5 kg bo'lishi mumkin
  final double minThreshold;  // ✅ DECIMAL
  final int unit;             // ✅ UNIT: 1=dona, 2=kg, 3=m

  const ProductEntity({
    required this.id,
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.quantity,
    required this.minThreshold,
    required this.unit,        // ✅ NEW
  });

  @override
  List<Object?> get props => [
        id,
        name,
        isTemporary,
        costPrice,
        salePrice,
        minSalePrice,
        quantity,
        minThreshold,
        unit,  // ✅ NEW
      ];

  /// Check if product is in low stock
  bool get isLowStock => quantity <= minThreshold;

  /// Calculate potential profit
  double get potentialProfit => salePrice - costPrice;

  /// Check if sale price is below minimum
  bool get isSalePriceInvalid => salePrice < minSalePrice;

  /// Get unit name in Uzbek
  String get unitName {
    switch (unit) {
      case 1:
        return 'dona';
      case 2:
        return 'kg';
      case 3:
        return 'm';
      default:
        return 'noma\'lum';
    }
  }
}
