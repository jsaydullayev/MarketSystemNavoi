import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class SalesService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  SalesService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Barcha sotuvlarni olish.
  // The API returns a paginated wrapper `{ items: [...], page, size, total, totalPages }`.
  // We accept both shapes (bare list or wrapped) so older deployments don't break.
  Future<List<dynamic>> getAllSales() async {
    final response = await _httpService.get(ApiConstants.sales);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      if (data is List) return List<dynamic>.from(data);
      if (data is Map && data['items'] is List) {
        return List<dynamic>.from(data['items']);
      }
      return [];
    } else {
      throw Exception('Failed to load sales: ${response.statusCode}');
    }
  }

  // Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    final response = await _httpService.get('${ApiConstants.sales}/$saleId');
    debugPrint('=== GET SALE RESPONSE ===');
    debugPrint(response.body);
    debugPrint('========================');

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
      ApiConstants.sales,
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
    debugPrint('=== UPDATE SALE CUSTOMER ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('Customer ID: ${customerId ?? "null"}');
    debugPrint('===========================');

    final response = await _httpService.patch(
      '${ApiConstants.sales}/$saleId/customer',
      body: {
        if (customerId != null) 'customerId': customerId,
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('===========================');

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
    debugPrint('=== ADD SALE ITEM DEBUG ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('Product ID: $productId');
    debugPrint('Is External: $isExternal');
    debugPrint('External Product Name: $externalProductName');
    debugPrint('External Cost Price: $externalCostPrice');
    debugPrint('Quantity: $quantity');
    debugPrint('Sale Price: $salePrice');
    debugPrint('Min Sale Price: $minSalePrice');
    debugPrint('Comment: ${comment ?? "(empty string)"}');
    debugPrint('==========================');

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

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

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
    debugPrint('=== REMOVE SALE ITEM DEBUG ===');
    debugPrint('URL: $url');
    debugPrint('Sale ID: $saleId');
    debugPrint('Sale Item ID: $saleItemId');
    debugPrint('Quantity to remove: $quantity');
    debugPrint('Body: {"saleItemId": "$saleItemId", "quantity": $quantity}');
    debugPrint('============================');

    final response = await _httpService.post(
      url,
      body: {
        'saleItemId': saleItemId,
        'quantity': quantity,
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

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

    debugPrint('=== ADD PAYMENT RESPONSE ===');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('============================');

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
    debugPrint('=== CANCEL SALE REQUEST ===');
    debugPrint('URL: ${ApiConstants.sales}/$saleId/cancel');
    debugPrint('Admin ID: $adminId');
    debugPrint('Body: {"adminId": "$adminId"}');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/cancel',
      body: {
        'adminId': adminId,
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==========================');

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
    debugPrint('=== UPDATE SALE ITEM PRICE ===');
    debugPrint('Sale Item ID: $saleItemId');
    debugPrint('New Price: $newPrice');
    debugPrint('Comment: $comment');
    debugPrint('==============================');

    final response = await _httpService.patch(
      '${ApiConstants.sales}/items/price',
      body: {
        'saleItemId': saleItemId,
        'newPrice': newPrice,
        'comment': comment,
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==============================');

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
    debugPrint('=== RETURN SALE ITEM ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('Sale Item ID: $saleItemId');
    debugPrint('Quantity: $quantity');
    debugPrint('Comment: $comment');
    debugPrint('=======================');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/return-item',
      body: {
        'saleItemId': saleItemId,
        'quantity': quantity,
        'comment': comment ?? '',
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('=======================');

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
    debugPrint('=== DELETE SALE ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('URL: ${ApiConstants.sales}/$saleId');
    debugPrint('==================');

    final response = await _httpService.delete(
      '${ApiConstants.sales}/$saleId',
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete sale: ${response.body}');
    }
  }

  // Qarzdorlarni olish
  Future<List<dynamic>> getDebtors() async {
    debugPrint('=== GET DEBTORS ===');

    final response = await _httpService.get('${ApiConstants.sales}/debtors');

    debugPrint('Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      debugPrint('Debtors count: ${data?.length ?? 0}');
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to get debtors: ${response.statusCode}');
    }
  }

  Future<List<int>?> downloadSalesExcel({String lang = 'uz'}) async {
    return await _httpService
        .downloadBytes('${ApiConstants.sales}/export?lang=$lang');
  }

  // Barcha sotuvlarni PDF formatda yuklab olish
  Future<List<int>?> downloadSalesPdf({DateTime? startDate, DateTime? endDate}) async {
    debugPrint('=== DOWNLOAD SALES PDF ===');
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
    debugPrint('URL: $url');
    debugPrint('=======================');

    return await _httpService.downloadBytes(url);
  }

  // Savdo uchun faktura (PDF) yuklab olish
  Future<List<int>?> downloadInvoice(String saleId) async {
    debugPrint('=== DOWNLOAD INVOICE ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('URL: ${ApiConstants.sales}/$saleId/invoice');
    debugPrint('=======================');

    return await _httpService.downloadBytes('${ApiConstants.sales}/$saleId/invoice');
  }
}
