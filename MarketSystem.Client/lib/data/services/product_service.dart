import 'dart:convert';

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class ProductService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  ProductService({required this.authProvider, HttpService? httpService})
      : _httpService = httpService ?? HttpService();


  Future<List<dynamic>> getAllProducts() async {
    final response =
        await _httpService.get('${ApiConstants.products}/GetAllProducts');

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to load products');
    }
  }

  Future<dynamic> getProductById(String id) async {
    final response =
        await _httpService.get('${ApiConstants.products}/GetProduct/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to load product');
    }
  }

  Future<dynamic> createProduct({
    required String name,
    required bool isTemporary,
    required double salePrice,
    required double minSalePrice,
    required int minThreshold,
    int? categoryId,
    required int unit,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.products}/CreateProduct',
      body: {
        'name': name,
        'isTemporary': isTemporary,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'minThreshold': minThreshold,
        if (categoryId != null) 'categoryId': categoryId,
        'unit': unit,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to create product');
    }
  }

  Future<dynamic> updateProduct({
    required String id,
    required String name,
    required double salePrice,
    required double minSalePrice,
    required int minThreshold,
    int? categoryId,
    required int unit,
    required bool isTemporary,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.products}/UpdateProduct/$id',
      body: {
        'id': id,
        'name': name,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'minThreshold': minThreshold,
        'isTemporary': isTemporary,
        if (categoryId != null) 'categoryId': categoryId,
        'unit': unit,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to update product');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await _httpService
        .delete('${ApiConstants.products}/DeleteProduct/$id');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to delete product');
    }
  }

  /// Downloads the products workbook. Pass `lang: 'ru'` to get
  /// Russian column headers; defaults to Uzbek when omitted.
  Future<List<int>?> downloadProductsExcel({String lang = 'uz'}) async {
    return await _httpService.downloadBytes(
      '${ApiConstants.productsExportExcel}?lang=$lang',
    );
  }
}
