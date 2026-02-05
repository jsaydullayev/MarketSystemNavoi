import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class ZakupService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  ZakupService({required this.authProvider}) {
    _httpService = HttpService();
  }

  Future<List<dynamic>> getAllZakups() async {
    final response = await _httpService.get('${ApiConstants.zakups}/GetAllZakups');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load zakups: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getZakupsByDateRange(DateTime start, DateTime end) async {
    final response = await _httpService.get(
      '${ApiConstants.zakups}/GetZakupsByDateRange?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load zakups by date: ${response.statusCode}');
    }
  }

  Future<dynamic> createZakup({
    required String productId,
    required int quantity,
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
      throw Exception('Failed to create zakup: ${response.body}');
    }
  }
}
