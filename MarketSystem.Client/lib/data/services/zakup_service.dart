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

  Future<List<int>?> downloadZakupsExcel() async {
    return await _httpService.downloadBytes(ApiConstants.zakupsExportExcel);
  }
}
