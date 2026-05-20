// Product Category Model
// Data transfer object for product categories

class ProductCategoryModel {
  final int id;
  final String name;
  final String? description;

  /// Emoji glyph chosen in the category form. Null for legacy rows created
  /// before the icon field existed — the UI falls back to a name-based guess.
  final String? icon;
  final bool isActive;
  final int productCount;

  ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
    required this.productCount,
  });

  /// Create from JSON
  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'] as String?,
      isActive: json['isActive'] ?? false,
      productCount: json['productCount'] ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
      'productCount': productCount,
    };
  }
}

/// Create Category Request Model
class CreateCategoryRequestModel {
  final String name;
  final String? description;
  final String? icon;

  CreateCategoryRequestModel({
    required this.name,
    this.description,
    this.icon,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
    };
  }
}

/// Update Category Request Model
class UpdateCategoryRequestModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  UpdateCategoryRequestModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      'isActive': isActive,
    };
  }
}
