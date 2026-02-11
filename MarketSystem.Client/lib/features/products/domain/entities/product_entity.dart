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
  final int quantity;
  final int minThreshold;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.quantity,
    required this.minThreshold,
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
      ];

  /// Check if product is in low stock
  bool get isLowStock => quantity <= minThreshold;

  /// Calculate potential profit
  double get potentialProfit => salePrice - costPrice;

  /// Check if sale price is below minimum
  bool get isSalePriceInvalid => salePrice < minSalePrice;
}
