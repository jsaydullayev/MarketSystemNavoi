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
    final response = await _httpService.get('${ApiConstants.sales}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to load sales: ${response.statusCode}');
    }
  }

  // Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    final response = await _httpService.get('${ApiConstants.sales}/$saleId');
    print('=== GET SALE RESPONSE ===');
    print(response.body);
    print('========================');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Invalid response format: expected Map');
    } else if (response.statusCode == 404) {
      throw Exception('Sotuv topilmadi');
    } else {
      throw Exception('Failed to load sale: ${response.statusCode}');
    }
  }

  // Mening draft sotuvlarim
  Future<List<dynamic>> getMyDraftSales() async {
    final response = await _httpService.get('${ApiConstants.sales}/my-drafts');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to load draft sales: ${response.statusCode}');
    }
  }

  // Mening tugatilmagan sotuvlarim (Draft + Debt)
  Future<List<dynamic>> getMyUnfinishedSales() async {
    final response = await _httpService.get('${ApiConstants.sales}/my-unfinished');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to load unfinished sales: ${response.statusCode}');
    }
  }

  // Yangi sotuv yaratish
  Future<dynamic> createSale({String? customerId}) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}',
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

  // Savdo uchun mijozni yangilash/qo'shish
  Future<dynamic> updateSaleCustomer({
    required String saleId,
    String? customerId,
  }) async {
    print('=== UPDATE SALE CUSTOMER ===');
    print('Sale ID: $saleId');
    print('Customer ID: ${customerId ?? "null"}');
    print('===========================');

    final response = await _httpService.patch(
      '${ApiConstants.sales}/$saleId/customer',
      body: {
        if (customerId != null) 'customerId': customerId,
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('===========================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Xatolik yuz berdi');
    } else {
      throw Exception('Failed to update sale customer: ${response.statusCode}');
    }
  }

  // Sotuvga mahsulot qo'shish
  Future<dynamic> addSaleItem({
    required String saleId,
    String? productId,  // ✅ Nullable - tashqi mahsulot uchun bo'sh bo'lishi mumkin
    required double quantity,
    required double salePrice,
    required double minSalePrice,
    String? comment,
    bool isExternal = false,  // ✅ Tashqi mahsulot flag
    String? externalProductName,  // ✅ Tashqi mahsulot nomi
    double? externalCostPrice,  // ✅ Tashqi tannarx
  }) async {
    print('=== ADD SALE ITEM DEBUG ===');
    print('Sale ID: $saleId');
    print('Product ID: $productId');
    print('Is External: $isExternal');
    print('External Product Name: $externalProductName');
    print('External Cost Price: $externalCostPrice');
    print('Quantity: $quantity');
    print('Sale Price: $salePrice');
    print('Min Sale Price: $minSalePrice');
    print('Comment: ${comment ?? "(empty string)"}');
    print('==========================');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/items',
      body: {
        if (productId != null && !isExternal) 'productId': productId,  // ✅ Faqat oddiy mahsulot uchun
        'isExternal': isExternal,  // ✅ Tashqi mahsulot flag
        'quantity': quantity,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'comment': comment ?? '',
        if (isExternal) 'externalProductName': externalProductName,  // ✅ Tashqi mahsulot nomi
        if (isExternal) 'externalCostPrice': externalCostPrice,  // ✅ Tashqi tannarx
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'Failed to add sale item';
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? errorData['title'] ?? response.body;
      } catch (_) {
        errorMsg = response.body.isNotEmpty
            ? response.body
            : 'Server error: ${response.statusCode}';
      }
      throw Exception(
          'Failed to add sale item: $errorMsg (Status: ${response.statusCode})');
    }
  }

  // Sotuvdan mahsulot o'chirish yoki miqdorni kamaytirish
  Future<dynamic> removeSaleItem({
    required String saleId,
    required String saleItemId,
    required double quantity,
  }) async {
    final url = '${ApiConstants.sales}/$saleId/items/remove';
    print('=== REMOVE SALE ITEM DEBUG ===');
    print('URL: $url');
    print('Sale ID: $saleId');
    print('Sale Item ID: $saleItemId');
    print('Quantity to remove: $quantity');
    print('Body: {"saleItemId": "$saleItemId", "quantity": $quantity}');
    print('============================');

    final response = await _httpService.post(
      url,
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
      String errorMsg = 'Failed to remove sale item';
      try {
        final errorData = jsonDecode(response.body);
        errorMsg = errorData['message'] ?? errorData['title'] ?? response.body;
      } catch (_) {
        errorMsg = response.body.isNotEmpty
            ? response.body
            : 'Server error: ${response.statusCode}';
      }
      throw Exception(
          'Failed to remove sale item: $errorMsg (Status: ${response.statusCode})');
    }
  }

  // To'lov qo'shish
  Future<dynamic> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/payments',
      body: {
        'paymentType': paymentType,
        'amount': amount,
      },
    );

    print('=== ADD PAYMENT RESPONSE ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('============================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add payment: ${response.body}');
    }
  }

  // Savdoni qarzga yozish (Mark as Debt)
  Future<dynamic> markSaleAsDebt(String saleId) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/mark-debt',
      body: {},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark sale as debt: ${response.body}');
    }
  }

  // Sotuvni bekor qilish (Admin/Owner)
  Future<dynamic> cancelSale({
    required String saleId,
    required String adminId,
  }) async {
    print('=== CANCEL SALE REQUEST ===');
    print('URL: ${ApiConstants.sales}/$saleId/cancel');
    print('Admin ID: $adminId');
    print('Body: {"adminId": "$adminId"}');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/cancel',
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
      throw Exception(
          'Failed to cancel sale. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Savdo item narxini o'zgartirish
  Future<dynamic> updateSaleItemPrice({
    required String saleItemId,
    required double newPrice,
    required String comment,
  }) async {
    print('=== UPDATE SALE ITEM PRICE ===');
    print('Sale Item ID: $saleItemId');
    print('New Price: $newPrice');
    print('Comment: $comment');
    print('==============================');

    final response = await _httpService.patch(
      '${ApiConstants.sales}/items/price',
      body: {
        'saleItemId': saleItemId,
        'newPrice': newPrice,
        'comment': comment,
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==============================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Ruxsat yo\'q: Bu amalni bajarish huquqingiz yo\'q');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Xatolik yuz berdi');
    } else {
      throw Exception('Narxni yangilashda xatolik: ${response.statusCode}');
    }
  }

  // Tovarni qaytarish (vozvrat)
  Future<dynamic> returnSaleItem({
    required String saleId,
    required String saleItemId,
    required double quantity,
    String? comment,
  }) async {
    print('=== RETURN SALE ITEM ===');
    print('Sale ID: $saleId');
    print('Sale Item ID: $saleItemId');
    print('Quantity: $quantity');
    print('Comment: $comment');
    print('=======================');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/return-item',
      body: {
        'saleItemId': saleItemId,
        'quantity': quantity,
        'comment': comment ?? '',
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=======================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to return sale item: ${response.body}');
    }
  }

  // Savdoni o'chirish
  Future<dynamic> deleteSale({
    required String saleId,
  }) async {
    print('=== DELETE SALE ===');
    print('Sale ID: $saleId');
    print('URL: ${ApiConstants.sales}/$saleId');
    print('==================');

    final response = await _httpService.delete(
      '${ApiConstants.sales}/$saleId',
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete sale: ${response.body}');
    }
  }

  // Qarzdorlarni olish
  Future<List<dynamic>> getDebtors() async {
    print('=== GET DEBTORS ===');

    final response = await _httpService.get('${ApiConstants.sales}/debtors');

    print('Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      print('Debtors count: ${data?.length ?? 0}');
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to get debtors: ${response.statusCode}');
    }
  }

  Future<List<int>?> downloadSalesExcel() async {
    return await _httpService
        .downloadBytes('${ApiConstants.sales}/export');
  }

  // Barcha sotuvlarni PDF formatda yuklab olish
  Future<List<int>?> downloadSalesPdf({DateTime? startDate, DateTime? endDate}) async {
    print('=== DOWNLOAD SALES PDF ===');
    String url = '${ApiConstants.sales}/export-pdf';
    List<String> queryParams = [];
    if (startDate != null) {
      queryParams.add('startDate=${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      queryParams.add('endDate=${endDate.toIso8601String()}');
    }
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    print('URL: $url');
    print('=======================');

    return await _httpService.downloadBytes(url);
  }

  // Savdo uchun faktura (PDF) yuklab olish
  Future<List<int>?> downloadInvoice(String saleId) async {
    print('=== DOWNLOAD INVOICE ===');
    print('Sale ID: $saleId');
    print('URL: ${ApiConstants.sales}/$saleId/invoice');
    print('=======================');

    return await _httpService.downloadBytes('${ApiConstants.sales}/$saleId/invoice');
  }
}
