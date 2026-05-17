import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class SalesService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  SalesService({required this.authProvider, HttpService? httpService})
      : _httpService = httpService ?? HttpService();


  // Barcha sotuvlarni olish
  Future<List<dynamic>> getAllSales() async {
    final response = await _httpService.get(ApiConstants.sales);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        return List<dynamic>.from(data['items'] ?? []);
      }
      return List<dynamic>.from(data ?? []);
    } else {
      throw Exception('Failed to load sales: ${response.statusCode}');
    }
  }

  // Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    final response = await _httpService.get('${ApiConstants.sales}/$saleId');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) throw Exception('Empty response from server');
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
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
      if (response.body.isEmpty) return [];
      return List<dynamic>.from(jsonDecode(response.body) ?? []);
    } else {
      throw Exception('Failed to load draft sales: ${response.statusCode}');
    }
  }

  // Mening tugatilmagan sotuvlarim (Draft + Debt)
  Future<List<dynamic>> getMyUnfinishedSales() async {
    final response =
        await _httpService.get('${ApiConstants.sales}/my-unfinished');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      return List<dynamic>.from(jsonDecode(response.body) ?? []);
    } else {
      throw Exception(
          'Failed to load unfinished sales: ${response.statusCode}');
    }
  }

  // Yangi sotuv yaratish
  Future<dynamic> createSale({String? customerId}) async {
    final response = await _httpService.post(
      ApiConstants.sales,
      body: {if (customerId != null) 'customerId': customerId},
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
    final response = await _httpService.patch(
      '${ApiConstants.sales}/$saleId/customer',
      body: {if (customerId != null) 'customerId': customerId},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Xatolik yuz berdi');
    } else {
      throw Exception(
          'Failed to update sale customer: ${response.statusCode}');
    }
  }

  // Sotuvga mahsulot qo'shish
  Future<dynamic> addSaleItem({
    required String saleId,
    String? productId,
    required double quantity,
    required double salePrice,
    required double minSalePrice,
    String? comment,
    bool isExternal = false,
    String? externalProductName,
    double? externalCostPrice,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/items',
      body: {
        if (productId != null && !isExternal) 'productId': productId,
        'isExternal': isExternal,
        'quantity': quantity,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'comment': comment ?? '',
        if (isExternal) 'externalProductName': externalProductName,
        if (isExternal) 'externalCostPrice': externalCostPrice,
      },
    );

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
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/items/remove',
      body: {'saleItemId': saleItemId, 'quantity': quantity},
    );

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
      body: {'paymentType': paymentType, 'amount': amount},
    );

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
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/cancel',
      body: {'adminId': adminId},
    );

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
    final response = await _httpService.patch(
      '${ApiConstants.sales}/items/price',
      body: {
        'saleItemId': saleItemId,
        'newPrice': newPrice,
        'comment': comment,
      },
    );

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
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/return-item',
      body: {
        'saleItemId': saleItemId,
        'quantity': quantity,
        'comment': comment ?? '',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to return sale item: ${response.body}');
    }
  }

  // Savdoni o'chirish
  Future<dynamic> deleteSale({required String saleId}) async {
    final response = await _httpService.delete('${ApiConstants.sales}/$saleId');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete sale: ${response.body}');
    }
  }

  // Qarzdorlarni olish
  Future<List<dynamic>> getDebtors() async {
    final response =
        await _httpService.get('${ApiConstants.sales}/debtors');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      return List<dynamic>.from(jsonDecode(response.body) ?? []);
    } else {
      throw Exception('Failed to get debtors: ${response.statusCode}');
    }
  }

  Future<List<int>?> downloadSalesExcel() async {
    return await _httpService.downloadBytes('${ApiConstants.sales}/export');
  }

  Future<List<int>?> downloadSalesPdf(
      {DateTime? startDate, DateTime? endDate}) async {
    String url = '${ApiConstants.sales}/export-pdf';
    final queryParams = <String>[];
    if (startDate != null) {
      queryParams.add('startDate=${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      queryParams.add('endDate=${endDate.toIso8601String()}');
    }
    if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';
    return await _httpService.downloadBytes(url);
  }

  Future<List<int>?> downloadInvoice(String saleId) async {
    return await _httpService
        .downloadBytes('${ApiConstants.sales}/$saleId/invoice');
  }
}
