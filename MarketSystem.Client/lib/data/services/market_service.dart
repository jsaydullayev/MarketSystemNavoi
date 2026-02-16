import 'dart:convert';
import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';
import '../models/market_model.dart';

class MarketService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  MarketService({required this.authProvider}) {
    _httpService = HttpService();
  }

  /// Register market for Owner
  /// Owner creates a new market and gets linked to it
  Future<RegisterMarketResponseModel> registerMarket({
    required String name,
    String? subdomain,
    String? description,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.markets}/RegisterMarket',
      body: {
        'name': name,
        if (subdomain != null) 'subdomain': subdomain,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return RegisterMarketResponseModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Market registratsiyada xatolik');
    }
  }

  /// Get current Owner's market
  Future<MarketModel?> getMyMarket() async {
    try {
      final response = await _httpService.get('${ApiConstants.markets}/GetMyMarket');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarketModel.fromJson(data);
      } else if (response.statusCode == 404) {
        // Market not found - Owner hasn't registered a market yet
        return null;
      } else {
        throw Exception('Marketni olishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Marketni olishda xatolik: $e');
    }
  }

  /// Update current Owner's market
  Future<void> updateMyMarket({
    required String name,
    String? description,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.markets}/UpdateMyMarket',
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Marketni yangilashda xatolik');
    }
  }

  /// Get all markets (SuperAdmin only)
  Future<List<MarketModel>> getAllMarkets() async {
    final response = await _httpService.get('${ApiConstants.markets}/GetAllMarkets');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List)
          .map((item) => MarketModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Marketlarni olishda xatolik: ${response.statusCode}');
    }
  }

  /// Get market by ID (SuperAdmin only)
  Future<MarketModel?> getMarketById(int id) async {
    final response = await _httpService.get('${ApiConstants.markets}/GetMarketById/$id');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MarketModel.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Marketni olishda xatolik: ${response.statusCode}');
    }
  }
}
