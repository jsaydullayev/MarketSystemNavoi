import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class SalesService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  SalesService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Barcha sotuvlarni olish
  Future<List<dynamic>> getAllSales() async {
    final response = await _httpService.get('${ApiConstants.sales}/GetAllSales');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load sales: ${response.statusCode}');
    }
  }

  // Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    final response = await _httpService.get('${ApiConstants.sales}/GetSale/$saleId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Sotuv topilmadi');
    } else {
      throw Exception('Failed to load sale: ${response.statusCode}');
    }
  }

  // Mening draft sotuvlarim
  Future<List<dynamic>> getMyDraftSales() async {
    final response = await _httpService.get('${ApiConstants.sales}/GetMyDraftSales');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load draft sales: ${response.statusCode}');
    }
  }

  // Yangi sotuv yaratish
  Future<dynamic> createSale({String? customerId}) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/CreateSale',
      body: {
        if (customerId != null) 'customerId': customerId,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create sale: ${response.body}');
    }
  }

  // Sotuvga mahsulot qo'shish
  Future<dynamic> addSaleItem({
    required String saleId,
    required String productId,
    required int quantity,
    required double salePrice,
    required double minSalePrice,  // ✅ Yangi: minPrice parametri qo'shildi
    String? comment,
  }) async {
    print('=== ADD SALE ITEM DEBUG ===');
    print('Sale ID: $saleId');
    print('Product ID: $productId');
    print('Quantity: $quantity');
    print('Sale Price: $salePrice');
    print('Min Sale Price: $minSalePrice');  // ✅ Debug: minPrice
    print('Comment: ${comment ?? "(empty string)"}');
    print('==========================');

    final response = await _httpService.post(
      '${ApiConstants.sales}/AddSaleItem/$saleId',
      body: {
        'productId': productId,
        'quantity': quantity,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,  // ✅ Backendga minPrice yuborish
        'comment': comment ?? '', // Null bo'lsa bo'sh string yuboramiz
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add sale item: ${response.body}');
    }
  }

  // Sotuvdan mahsulot o'chirish yoki miqdorni kamaytirish
  Future<dynamic> removeSaleItem({
    required String saleId,
    required String saleItemId,
    required int quantity,  // 0 = butunlay o'chirish, >0 = shunchaki miqdorni kamaytirish
  }) async {
    print('=== REMOVE SALE ITEM DEBUG ===');
    print('Sale ID: $saleId');
    print('Sale Item ID: $saleItemId');
    print('Quantity to remove: $quantity');
    print('============================');

    final response = await _httpService.post(
      '${ApiConstants.sales}/remove-item/$saleId',
      body: {
        'saleItemId': saleItemId,
        'quantity': quantity,
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to remove sale item: ${response.body}');
    }
  }

  // To'lov qo'shish
  Future<dynamic> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/AddPayment/$saleId',
      body: {
        'paymentType': paymentType,
        'amount': amount,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add payment: ${response.body}');
    }
  }

  // Sotuvni bekor qilish (Admin/Owner)
  Future<dynamic> cancelSale({
    required String saleId,
    required String adminId,
  }) async {
    print('=== CANCEL SALE REQUEST ===');
    print('URL: ${ApiConstants.sales}/CancelSale/$saleId');
    print('Admin ID: $adminId');
    print('Body: {"adminId": "$adminId"}');

    final response = await _httpService.post(
      '${ApiConstants.sales}/CancelSale/$saleId',
      body: {
        'adminId': adminId,
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==========================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to cancel sale. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Savdo item narxini o'zgartirish
  Future<dynamic> updateSaleItemPrice({
    required String saleItemId,
    required double newPrice,
  }) async {
    print('=== UPDATE SALE ITEM PRICE ===');
    print('Sale Item ID: $saleItemId');
    print('New Price: $newPrice');
    print('==============================');

    final response = await _httpService.patch(
      '${ApiConstants.sales}/UpdateSaleItemPrice',
      body: {
        'saleItemId': saleItemId,
        'newPrice': newPrice,
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==============================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update sale item price: ${response.body}');
    }
  }
}
