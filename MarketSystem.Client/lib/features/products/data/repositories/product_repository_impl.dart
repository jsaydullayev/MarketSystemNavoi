/// Product Repository Implementation
/// Data layer implementation for products
library;

import '../../../../core/failure/failures.dart';
import '../../../../core/handlers/network_handler.dart';
import '../../../../core/utils/di.dart' as di;

import '../models/product_model.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

/// Product Repository Implementation
class ProductRepositoryImpl implements ProductRepository {
  final NetworkHandler _networkHandler;

  ProductRepositoryImpl()
      : _networkHandler = di.sl<NetworkHandler>();

  @override
  Future<List<ProductEntity>> getAllProducts() async {
    try {
      final response = await _networkHandler.get('/Products/GetAllProducts');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          return ProductModel.fromJson(json).toEntity();
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ProductEntity?> getProductById(String id) async {
    try {
      final response = await _networkHandler.get('/Products/GetProduct/$id');

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data);
        return product.toEntity();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProductEntity>> getLowStockProducts() async {
    try {
      final response = await _networkHandler.get('/Products/GetLowStock');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          return ProductModel.fromJson(json).toEntity();
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ProductEntity?> createProduct({
    required String name,
    required bool isTemporary,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required double quantity,
    required int minThreshold,
  }) async {
    try {
      final response = await _networkHandler.post('/Products/CreateProduct', data: {
        'name': name,
        'isTemporary': isTemporary,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'quantity': quantity,
        'minThreshold': minThreshold,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final product = ProductModel.fromJson(response.data);
        return product.toEntity();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ProductEntity?> updateProduct({
    required String id,
    required String name,
    required bool isTemporary,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required double quantity,
    required int minThreshold,
  }) async {
    try {
      final response = await _networkHandler.put('/Products/UpdateProduct/$id', data: {
        'id': id,
        'name': name,
        'isTemporary': isTemporary,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'quantity': quantity,
        'minThreshold': minThreshold,
      });

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data);
        return product.toEntity();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _networkHandler.delete('/Products/DeleteProduct/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
