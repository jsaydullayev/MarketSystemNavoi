/// Product Model
/// Data transfer object for products

import '../../domain/entities/product_entity.dart';

/// Product DTO
class ProductModel {
  final String id;
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final double quantity;        // ✅ DECIMAL - 1.5 kg bo'lishi mumkin
  final double minThreshold;    // ✅ DECIMAL
  final int unit;               // ✅ UNIT: 1=dona, 2=kg, 3=m
  final String unitName;        // ✅ "dona", "kg", "m"
  final int? categoryId;
  final String? categoryName;
  final bool isInStock;
  final bool isLowStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
    required this.unitName,
    this.categoryId,
    this.categoryName,
    required this.isInStock,
    required this.isLowStock,
  });

  /// Create from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      isTemporary: json['isTemporary'] ?? false,
      costPrice: json['costPrice'] is num ? (json['costPrice'] as num).toDouble() : 0.0,
      salePrice: json['salePrice'] is num ? (json['salePrice'] as num).toDouble() : 0.0,
      minSalePrice: json['minSalePrice'] is num ? (json['minSalePrice'] as num).toDouble() : 0.0,
      quantity: json['quantity'] is num ? (json['quantity'] as num).toDouble() : 0.0,
      minThreshold: json['minThreshold'] is num ? (json['minThreshold'] as num).toDouble() : 5.0,
      unit: json['unit'] is int ? json['unit'] as int : 1,  // Default: dona
      unitName: json['unitName'] ?? 'dona',
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      isInStock: json['isInStock'] ?? true,
      isLowStock: json['isLowStock'] ?? false,
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
      quantity: quantity,       // ✅ DECIMAL
      minThreshold: minThreshold,  // ✅ DECIMAL
      unit: unit,
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
      'unit': unit,
      'categoryId': categoryId,
    };
  }
}

/// Unit Type Enum
enum UnitType {
  piece(1, 'dona', 'Piece'),
  kilogram(2, 'kg', 'Kilogram'),
  meter(3, 'm', 'Meter');

  final int value;
  final String nameUz;
  final String nameEn;

  const UnitType(this.value, this.nameUz, this.nameEn);

  /// Get enum from value
  static UnitType fromValue(int value) {
    return UnitType.values.firstWhere(
      (unit) => unit.value == value,
      orElse: () => UnitType.piece,
    );
  }
}

/// Unit Info Model for Dropdown
class UnitInfo {
  final int value;
  final String nameUz;
  final String nameEn;
  final String nameRu;

  UnitInfo({
    required this.value,
    required this.nameUz,
    required this.nameEn,
    required this.nameRu,
  });

  /// Create from JSON
  factory UnitInfo.fromJson(Map<String, dynamic> json) {
    return UnitInfo(
      value: json['value'] as int,
      nameUz: json['nameUz'] as String,
      nameEn: json['nameEn'] as String,
      nameRu: json['nameRu'] as String,
    );
  }

  /// Get display name based on locale
  String getDisplayName(String locale) {
    switch (locale) {
      case 'uz':
        return nameUz;
      case 'en':
        return nameEn;
      case 'ru':
        return nameRu;
      default:
        return nameUz;
    }
  }
}
