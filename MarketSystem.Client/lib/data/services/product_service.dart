import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class ProductService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  ProductService({required this.authProvider}) {
    _httpService = HttpService();
  }

  Future<List<dynamic>> getAllProducts() async {
    final response = await _httpService.get('${ApiConstants.products}/GetAllProducts');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<dynamic> getProductById(String id) async {
    final response = await _httpService.get('${ApiConstants.products}/GetProduct/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<dynamic> createProduct({
    required String name,
    required bool isTemporary,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required int quantity,
    required int minThreshold,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.products}/CreateProduct',
      body: {
        'name': name,
        'isTemporary': isTemporary,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'quantity': quantity,
        'minThreshold': minThreshold,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  Future<dynamic> updateProduct({
    required String id,
    required String name,
    required double costPrice,
    required double salePrice,
    required double minSalePrice,
    required int quantity,
    required int minThreshold,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.products}/UpdateProduct/$id',
      body: {
        'id': id,
        'name': name,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'quantity': quantity,
        'minThreshold': minThreshold,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await _httpService.delete('${ApiConstants.products}/DeleteProduct/$id');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
}
