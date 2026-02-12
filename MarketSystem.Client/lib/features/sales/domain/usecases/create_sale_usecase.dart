/// Create Sale Use Case
/// Yangi sotuv yaratish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/sale_entity.dart';
import '../repositories/sale_repository_interface.dart';

/// Create Sale Use Case
class CreateSaleUseCase {
  final SaleRepositoryInterface repository;

  const CreateSaleUseCase(this.repository);

  /// Yangi sotuv yaratish
  /// customerId - majburiy emas, null bo'lsa umumiy mijoz uchun
  Future<ApiResult<SaleEntity>> call({String? customerId}) async {
    // Biznes validatsiya
    // Agar customerId berilgan bo'lsa, u bo'sh bo'lmasligi kerak
    if (customerId != null && customerId.isEmpty) {
      return ApiResult.failure('Mijoz ID bo\'sh bo\'lishi mumkin emas');
    }

    return repository.createSale(customerId: customerId);
  }
}
