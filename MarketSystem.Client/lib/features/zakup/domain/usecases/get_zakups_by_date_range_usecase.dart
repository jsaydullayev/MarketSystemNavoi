/// Get Zakups By Date Range Use Case
/// Sana bo'yicha xaridlarni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/zakup_entity.dart';
import '../repositories/zakup_repository_interface.dart';

/// Get Zakups By Date Range Use Case
class GetZakupsByDateRangeUseCase {
  final ZakupRepositoryInterface repository;

  const GetZakupsByDateRangeUseCase(this.repository);

  /// Sana bo'yicha xaridlarni olish
  Future<ApiResult<List<ZakupEntity>>> call(
    DateTime start,
    DateTime end,
  ) async {
    // Biznes validatsiya
    if (start.isAfter(end)) {
      return ApiResult.failure('Boshlanish sanasi tugash sanasidan keyinda bo\'lishi mumkin emas');
    }

    return repository.getZakupsByDateRange(start, end);
  }
}
