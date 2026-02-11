/// Product Model
/// Data transfer object for products
library;

import '../../domain/entities/product_entity.dart';

/// Product DTO
class ProductModel {
  final String id;
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final int quantity;
  final int minThreshold;

  ProductModel({
    required this.id,
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.quantity,
    required this.minThreshold,
  });

  /// Create from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      isTemporary: json['isTemporary'] ?? false,
      costPrice: (json['costPrice'] is num ? json['costPrice'].toDouble() : 0.0,
      salePrice: (json['salePrice'] is num ? json['salePrice'].toDouble() : 0.0,
      minSalePrice: (json['minSalePrice'] is num ? json['minSalePrice'].toDouble() : 0.0,
      quantity: (json['quantity'] is num ? json['quantity'] : 0,
      minThreshold: (json['minThreshold'] is num ? json['minThreshold'] : 0,
    );
  }

  /// Convert to entity
  ProductEntity toEntity() {
    return ProductEntity(
      id: int.parse(id),
      name: name,
      isTemporary: isTemporary,
      costPrice: costPrice,
      salePrice: salePrice,
      minSalePrice: minSalePrice,
      quantity: quantity,
      minThreshold: minThreshold,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isTemporary': isTemporary,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'minSalePrice': minSalePrice,
      'quantity': quantity,
      'minThreshold': minThreshold,
    };
  }
}
