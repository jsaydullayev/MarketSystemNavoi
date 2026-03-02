/// Product Repository Interface
/// Domain repository interface for products
library;

import '../entities/product_entity.dart';

/// Result type for operations that can fail
typedef ResultFuture<T> = Future<T?>;

/// Product Repository Interface
abstract class ProductRepository {
  /// Get all products
  ResultFuture<List<ProductEntity>> getAllProducts();

  /// Get product by ID
  ResultFuture<ProductEntity?> getProductById(String id);

  /// Get products with low stock
  ResultFuture<List<ProductEntity>> getLowStockProducts();

  /// Create new product
  ResultFuture<ProductEntity?> createProduct({
    required String name,
    required bool isTemporary,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required int quantity,
    required int minThreshold,
  });

  /// Update existing product
  ResultFuture<ProductEntity?> updateProduct({
    required String id,
    required String name,
    required bool isTemporary,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required int quantity,
    required int minThreshold,
  });

  /// Delete product
  ResultFuture<bool> deleteProduct(String id);
}
