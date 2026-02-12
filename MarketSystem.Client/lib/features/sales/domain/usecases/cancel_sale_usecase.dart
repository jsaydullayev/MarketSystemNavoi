/// Cancel Sale Use Case
/// Sotuvni bekor qilish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Cancel Sale Use Case
class CancelSaleUseCase {
  final SaleRepositoryInterface repository;

  const CancelSaleUseCase(this.repository);

  /// Sotuvni bekor qilish (Admin/Owner)
  Future<ApiResult<void>> call({
    required String saleId,
    required String adminId,
  }) async {
    // Biznes validatsiyalar
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    if (adminId.isEmpty) {
      return ApiResult.failure('Admin ID bo\'sh bo\'lishi mumkin emas');
    }

    return repository.cancelSale(
      saleId: saleId,
      adminId: adminId,
    );
  }
}
