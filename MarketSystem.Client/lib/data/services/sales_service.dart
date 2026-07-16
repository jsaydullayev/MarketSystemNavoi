import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class SalesService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  SalesService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Paged sotuvlar.
  // Backend: GET /api/Sales?page=N&size=M → { items, page, size, total, totalPages }
  Future<({List<dynamic> items, int currentPage, int totalPages, int total})>
  getSalesPaged({int page = 1, int size = 50}) async {
    final response = await _httpService.get(
      '${ApiConstants.sales}?page=$page&size=$size',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return (items: <dynamic>[], currentPage: page, totalPages: 1, total: 0);
      }
      final data = jsonDecode(response.body);
      if (data is Map) {
        final items = data['items'] is List
            ? List<dynamic>.from(data['items'] as List)
            : <dynamic>[];
        return (
          items: items,
          currentPage: (data['page'] as num?)?.toInt() ?? page,
          totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
          total: (data['total'] as num?)?.toInt() ?? items.length,
        );
      }
      if (data is List) {
        return (items: List<dynamic>.from(data), currentPage: 1, totalPages: 1, total: data.length);
      }
      return (items: <dynamic>[], currentPage: page, totalPages: 1, total: 0);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load sales',
      );
    }
  }

  // Backward-compat: barcha sotuvlarni olish (birinchi sahifa, size=50)
  Future<List<dynamic>> getAllSales() async {
    final result = await getSalesPaged(page: 1, size: 50);
    return result.items;
  }

  // Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    final response = await _httpService.get('${ApiConstants.sales}/$saleId');
    debugPrint('=== GET SALE RESPONSE ===');
    debugPrint(response.body);
    debugPrint('========================');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw ApiException(
          statusCode: 200,
          message: 'Empty response from server',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw ApiException(
        statusCode: 200,
        message: 'Invalid response format: expected Map',
      );
    } else if (response.statusCode == 404) {
      throw ApiException(statusCode: 404, message: 'Sotuv topilmadi');
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load sale',
      );
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
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load draft sales',
      );
    }
  }

  // Mening tugatilmagan sotuvlarim (Draft + Debt)
  Future<List<dynamic>> getMyUnfinishedSales() async {
    final response = await _httpService.get(
      '${ApiConstants.sales}/my-unfinished',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data ?? []);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load unfinished sales',
      );
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
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to create sale',
      );
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
      body: {if (customerId != null) 'customerId': customerId},
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('===========================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    // ApiException.fromResponse already surfaces the `message` field from
    // 4xx JSON bodies, so the previous 400-special-case is redundant.
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to update sale customer',
    );
  }

  // Sotuvga mahsulot qo'shish
  Future<dynamic> addSaleItem({
    required String saleId,
    String?
    productId, // ✅ Nullable - tashqi mahsulot uchun bo'sh bo'lishi mumkin
    required double quantity,
    required double salePrice,
    required double minSalePrice,
    String? comment,
    bool isExternal = false, // ✅ Tashqi mahsulot flag
    String? externalProductName, // ✅ Tashqi mahsulot nomi
    double? externalCostPrice, // ✅ Tashqi tannarx
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
        if (productId != null && !isExternal)
          'productId': productId, // ✅ Faqat oddiy mahsulot uchun
        'isExternal': isExternal, // ✅ Tashqi mahsulot flag
        'quantity': quantity,
        'salePrice': salePrice,
        'minSalePrice': minSalePrice,
        'comment': comment ?? '',
        if (isExternal)
          'externalProductName': externalProductName, // ✅ Tashqi mahsulot nomi
        if (isExternal)
          'externalCostPrice': externalCostPrice, // ✅ Tashqi tannarx
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to add sale item',
    );
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
      body: {'saleItemId': saleItemId, 'quantity': quantity},
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to remove sale item',
    );
  }

  // To'lov qo'shish
  Future<dynamic> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
    // Qisman to'lov qarz qoldirsa — yaratilgan qarz to'lov muddati (ISO-8601).
    String? dueDate,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/payments',
      body: {
        'paymentType': paymentType,
        'amount': amount,
        if (dueDate != null) 'dueDate': dueDate,
      },
    );

    debugPrint('=== ADD PAYMENT RESPONSE ===');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('============================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to add payment',
      );
    }
  }

  /// Aralash (multi-tender) to'lov — barcha bo'laklarni BITTA atomik so'rovda
  /// yuboradi. Backend bo'laklar yig'indisini hisobga solib tekshiradi, shu
  /// sabab mijozsiz savdo ham naqd + karta bo'lib to'liq to'lanadi. Eski
  /// har-bo'lak-alohida sikl birinchi qisman bo'lakni "mijozsiz qarz" deb
  /// backend rad etardi.
  Future<dynamic> addPayments({
    required String saleId,
    required List<Map<String, dynamic>> payments,
    // Qisman to'lov qarz qoldirsa — qarz to'lov muddati (ISO-8601).
    String? dueDate,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/payments/batch',
      body: {
        'payments': [
          for (final p in payments)
            {
              'paymentType': p['paymentType'],
              'amount': p['amount'],
              if (dueDate != null) 'dueDate': dueDate,
            },
        ],
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to add payments',
      );
    }
  }

  // Savdoni qarzga yozish (Mark as Debt). dueDate — to'lov muddati (ISO-8601).
  Future<dynamic> markSaleAsDebt(String saleId, {String? dueDate}) async {
    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/mark-debt',
      body: {if (dueDate != null) 'dueDate': dueDate},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to mark sale as debt',
      );
    }
  }

  // Sotuvni bekor qilish (Admin/Owner). Backend audit row'ining actor'ini
  // JWT'dan oladi — bu yerdan adminId yubormaymiz. Avval body'da adminId
  // yuborilardi va server uni audit'ga aynan o'zini yozardi, bu esa istalgan
  // admin'ning ID'sini forgery qilish vektori edi. Endi body bo'sh.
  Future<dynamic> cancelSale({required String saleId}) async {
    debugPrint('=== CANCEL SALE REQUEST ===');
    debugPrint('URL: ${ApiConstants.sales}/$saleId/cancel');

    final response = await _httpService.post(
      '${ApiConstants.sales}/$saleId/cancel',
      body: const <String, dynamic>{},
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==========================');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to cancel sale',
    );
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
    }
    // ApiException carries the server's localized `message` for 400 (StrongPassword,
    // domain validation, …) and the 403 status surfaces as `statusCode: 403` so
    // a caller can branch on it without parsing the body again. Fallback string
    // applies only when the body isn't JSON.
    throw ApiException.fromResponse(
      response,
      fallbackMessage: response.statusCode == 403
          ? 'Ruxsat yo\'q: Bu amalni bajarish huquqingiz yo\'q'
          : 'Narxni yangilashda xatolik',
    );
  }

  // Sotuvga chegirma (skidka) qo'llash. Mahsulotlar qo'shilgach, to'lovdan
  // oldin chaqiriladi. Item narxlariga tegmaydi; faqat umumiy hisobni
  // (TotalAmount) kamaytiradi — keyingi to'lovlar shu summani yopadi.
  Future<dynamic> setSaleDiscount({
    required String saleId,
    required double discountAmount,
  }) async {
    final response = await _httpService.patch(
      '${ApiConstants.sales}/$saleId/discount',
      body: {'discountAmount': discountAmount},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to apply discount',
    );
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

    // 204 No Content = to'liq qaytarish (tovarning butun miqdori qaytarildi;
    // backend `Ok(null)` qaytaradi). Bu MUVAFFAQIYATLI amal — xato emas.
    // Ilgari 204 `else` shoxiga tushib "ApiException(204)" berardi.
    if (response.statusCode == 204) {
      return null;
    }
    if (response.statusCode == 200) {
      // 200 bo'lsa ham tana bo'sh bo'lishi mumkin — jsonDecode'ni himoyalaymiz.
      return response.body.isEmpty ? null : jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to return sale item',
      );
    }
  }

  // Savdoni o'chirish
  Future<dynamic> deleteSale({required String saleId}) async {
    debugPrint('=== DELETE SALE ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('URL: ${ApiConstants.sales}/$saleId');
    debugPrint('==================');

    final response = await _httpService.delete('${ApiConstants.sales}/$saleId');

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('==================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete sale',
      );
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
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to get debtors',
      );
    }
  }

  Future<List<int>?> downloadSalesExcel({String lang = 'uz'}) async {
    return await _httpService.downloadBytes(
      '${ApiConstants.sales}/export?lang=$lang',
    );
  }

  // Barcha sotuvlarni PDF formatda yuklab olish
  Future<List<int>?> downloadSalesPdf({
    DateTime? startDate,
    DateTime? endDate,
    String lang = 'uz',
  }) async {
    debugPrint('=== DOWNLOAD SALES PDF ===');
    String url = '${ApiConstants.sales}/export-pdf';
    List<String> queryParams = ['lang=$lang'];
    if (startDate != null) {
      queryParams.add('startDate=${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      queryParams.add('endDate=${endDate.toIso8601String()}');
    }
    url += '?${queryParams.join('&')}';
    debugPrint('URL: $url');
    debugPrint('=======================');

    return await _httpService.downloadBytes(url);
  }

  // Savdo uchun faktura (PDF) yuklab olish.
  // `compact: true` — pechatga mo'ljallangan ixcham variant (A4 varaq, kontent
  // yuqorida kichik blok). Default (false) — to'liq A4 faktura (yuklab olish/share).
  Future<List<int>?> downloadInvoice(
    String saleId, {
    String lang = 'uz',
    bool compact = false,
  }) async {
    final url = '${ApiConstants.sales}/$saleId/invoice?lang=$lang&compact=$compact';
    debugPrint('=== DOWNLOAD INVOICE ===');
    debugPrint('Sale ID: $saleId');
    debugPrint('URL: $url');
    debugPrint('=======================');

    return await _httpService.downloadBytes(url);
  }
}
