import 'dart:convert';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';

class SaleService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  SaleService({required this.authProvider}) {
    _httpService = HttpService();
  }

  /// Update sale item price
  /// Requires: saleItemId, newPrice, comment
  Future<Map<String, dynamic>> updateSaleItemPrice({
    required String saleItemId,
    required double newPrice,
    required String comment,
  }) async {
    final response = await _httpService.patch(
      '/api/Sales/UpdateSaleItemPrice',
      body: {
        'saleItemId': saleItemId,
        'newPrice': newPrice,
        'comment': comment,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Bu amalni bajarish huquqingiz yo\'q');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Xatolik yuz berdi');
    } else {
      throw Exception('Narxni yangilashda xatolik: ${response.statusCode}');
    }
  }
}
