/// Zakup Remote Data Source
/// Zakups API dan ma'lumot olish

import '../../../../data/services/zakup_service.dart';

/// Zakup Remote Data Source
/// API bilan ishlash uchun mas'ul
class ZakupRemoteDataSource {
  final ZakupService _zakupService;

  const ZakupRemoteDataSource({required ZakupService zakupService})
      : _zakupService = zakupService;

  /// Barcha xaridlarni olish
  Future<List<dynamic>> getAllZakups() async {
    return _zakupService.getAllZakups();
  }

  /// Sana bo'yicha xaridlarni olish
  Future<List<dynamic>> getZakupsByDateRange(DateTime start, DateTime end) async {
    return _zakupService.getZakupsByDateRange(start, end);
  }

  /// Yangi xarid yaratish
  Future<dynamic> createZakup({
    required String productId,
    required double quantity,
    required double costPrice,
  }) async {
    return _zakupService.createZakup(
      productId: productId,
      quantity: quantity,
      costPrice: costPrice,
    );
  }
}
