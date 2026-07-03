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
    final response = await _httpService.get(
      '${ApiConstants.products}/GetAllProducts',
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load products',
      );
    }
  }

  Future<dynamic> getProductById(String id) async {
    final response = await _httpService.get(
      '${ApiConstants.products}/GetProduct/$id',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load product',
      );
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
    double quantity = 0,
    bool hidePriceFromSellers = false,
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
        'quantity': quantity,
        'hidePriceFromSellers': hidePriceFromSellers,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to create product',
      );
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
    bool hidePriceFromSellers = false,
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
        'hidePriceFromSellers': hidePriceFromSellers,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to update product',
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await _httpService.delete(
      '${ApiConstants.products}/DeleteProduct/$id',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete product',
      );
    }
  }

  /// Attaches (or replaces) a product's image. Sends a base64 data-URL as JSON
  /// — the same transport the avatar upload uses — so it works on every
  /// platform without a multipart helper. The backend re-validates the bytes
  /// (magic-byte + 5MB cap) and returns the updated product (with `imageUrl`).
  Future<dynamic> uploadProductImage(
    String productId,
    List<int> imageBytes,
    String filename,
  ) async {
    final fileSizeInMB = imageBytes.length / (1024 * 1024);
    if (fileSizeInMB > 5) {
      throw ApiException(
        statusCode: 0,
        message:
            'Rasm hajmi juda katta. Iltimos, kichikroq rasm tanlang (maksimum 5MB).',
      );
    }

    final base64Image = base64Encode(imageBytes);
    final extension = filename.toLowerCase().split('.').last;
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final response = await _httpService.post(
      ApiConstants.productImage(productId),
      body: {'image': 'data:$mimeType;base64,$base64Image'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Rasm yuklashda xatolik',
    );
  }

  /// Removes a product's image. Returns the updated product (imageUrl == null).
  Future<dynamic> removeProductImage(String productId) async {
    final response = await _httpService.delete(
      ApiConstants.productImageRemove(productId),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Rasmni o\'chirishda xatolik',
    );
  }

  /// Downloads the products workbook. Pass `lang: 'ru'` to get
  /// Russian column headers; defaults to Uzbek when omitted.
  Future<List<int>?> downloadProductsExcel({String lang = 'uz'}) async {
    return await _httpService.downloadBytes(
      '${ApiConstants.productsExportExcel}?lang=$lang',
    );
  }
}
