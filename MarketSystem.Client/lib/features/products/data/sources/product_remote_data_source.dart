/// Product Remote Data Source
/// API data source for products

import 'package:dio/dio.dart';

import '../../../../core/handlers/network_handler.dart';
import '../../../../core/utils/di.dart' as di;

/// Product Remote Data Source
class ProductRemoteDataSource {
  final NetworkHandler _networkHandler;

  ProductRemoteDataSource() : _networkHandler = di.sl<NetworkHandler>();

  /// Get all products from API
  Future<Response> getAllProducts() async {
    return await _networkHandler.get('/Products/GetAllProducts');
  }

  /// Get single product by ID
  Future<Response> getProductById(String id) async {
    return await _networkHandler.get('/Products/GetProduct/$id');
  }

  /// Get low stock products
  Future<Response> getLowStockProducts() async {
    return await _networkHandler.get('/Products/GetLowStock');
  }

  /// Create new product
  Future<Response> createProduct(Map<String, dynamic> data) async {
    return await _networkHandler.post('/Products/CreateProduct', data: data);
  }

  /// Update product
  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    return await _networkHandler.put('/Products/UpdateProduct/$id', data: data);
  }

  /// Delete product
  Future<Response> deleteProduct(String id) async {
    return await _networkHandler.delete('/Products/DeleteProduct/$id');
  }
}
