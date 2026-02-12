/// Zakup Repository Interface
/// Xarid (Zakup) repository interfeysi - data layer uchun kontrakt

import '../../../../core/failure/api_result.dart';
import '../entities/zakup_entity.dart';

/// Zakup Repository Interface
/// Data layer implementation qilishi kerak bo'lgan metodlar
abstract class ZakupRepositoryInterface {
  /// Barcha xaridlarni olish
  Future<ApiResult<List<ZakupEntity>>> getAllZakups();

  /// Sana bo'yicha xaridlarni olish
  Future<ApiResult<List<ZakupEntity>>> getZakupsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Yangi xarid yaratish
  Future<ApiResult<ZakupEntity>> createZakup({
    required String productId,
    required int quantity,
    required double costPrice,
  });
}
