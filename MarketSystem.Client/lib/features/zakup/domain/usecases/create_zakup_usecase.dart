/// Create Zakup Use Case
/// Yangi xarid yaratish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/zakup_entity.dart';
import '../repositories/zakup_repository_interface.dart';

/// Create Zakup Use Case
class CreateZakupUseCase {
  final ZakupRepositoryInterface repository;

  const CreateZakupUseCase(this.repository);

  /// Yangi xarid yaratish
  Future<ApiResult<ZakupEntity>> call({
    required String productId,
    required double quantity,
    required double costPrice,
  }) async {
    // Biznes validatsiyalar
    if (productId.isEmpty) {
      return ApiResult.failure('Mahsulot ID bo\'sh bo\'lishi mumkin emas');
    }

    if (quantity <= 0) {
      return ApiResult.failure('Miqdor 0 dan katta bo\'lishi kerak');
    }

    if (costPrice < 0) {
      return ApiResult.failure('Narx manfiy bo\'lishi mumkin emas');
    }

    return repository.createZakup(
      productId: productId,
      quantity: quantity,
      costPrice: costPrice,
    );
  }
}
