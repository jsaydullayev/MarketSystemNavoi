import 'dart:convert';

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class ZakupService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  ZakupService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  Future<List<dynamic>> getAllZakups() async {
    final response = await _httpService.get(
      '${ApiConstants.zakups}/GetAllZakups',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load zakups',
      );
    }
  }

  Future<Map<String, dynamic>> getZakupsPaged({
    int page = 1,
    int size = 50,
  }) async {
    final response = await _httpService.get(
      '${ApiConstants.zakups}/GetZakupsPaged?page=$page&size=$size',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load zakups',
      );
    }
  }

  Future<List<dynamic>> getZakupsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final response = await _httpService.get(
      ApiConstants.zakupsByDateRange(start, end),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load zakups by date',
      );
    }
  }

  Future<dynamic> createZakup({
    required String productId,
    required double quantity,
    required double costPrice,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.zakups}/CreateZakup',
      body: {
        'productId': productId,
        'quantity': quantity,
        'costPrice': costPrice,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to create zakup',
      );
    }
  }

  // ── Goods-receipts (priyomka) — multi-item + supplier + payment ──────────

  /// List goods-receipts, newest first. Each item is a receipt map with a
  /// nested `items` array (product lines).
  Future<List<dynamic>> getAllReceipts() async {
    final response = await _httpService.get(
      '${ApiConstants.zakups}/GetAllReceipts',
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to load receipts',
    );
  }

  /// Create one goods-receipt with N product lines in a single request.
  /// [items] entries: { productId, quantity, costPrice }.
  Future<dynamic> createReceipt({
    String? supplierId,
    String? invoiceNumber,
    required double paidAmount,
    String? comment,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.zakups}/CreateReceipt',
      body: {
        if (supplierId != null) 'supplierId': supplierId,
        if (invoiceNumber != null && invoiceNumber.isNotEmpty)
          'invoiceNumber': invoiceNumber,
        'paidAmount': paidAmount,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'items': items,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to create receipt',
    );
  }

  /// Delete a whole receipt (reverses each line's stock, clamped at 0).
  Future<void> deleteReceipt(String id) async {
    final response = await _httpService.delete(
      ApiConstants.deleteZakupReceipt(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete receipt',
      );
    }
  }

  /// Register a supplier payment against a receipt; returns the updated receipt.
  Future<dynamic> registerReceiptPayment(String id, double amount) async {
    final response = await _httpService.post(
      ApiConstants.zakupReceiptPay(id),
      body: {'amount': amount},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to register payment',
    );
  }

  Future<List<int>?> downloadZakupsExcel() async {
    return await _httpService.downloadBytes(ApiConstants.zakupsExportExcel);
  }

  /// O'chirish (Owner/zakup.delete) — backend ombor qoldig'ini qaytaradi.
  /// 204 (NoContent) yoki 200 — muvaffaqiyat.
  Future<void> deleteZakup(String id) async {
    final response = await _httpService.delete(ApiConstants.deleteZakup(id));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete zakup',
      );
    }
  }
}
