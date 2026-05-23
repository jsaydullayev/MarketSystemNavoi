// Cancel Sale Use Case
// Sotuvni bekor qilish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Cancel Sale Use Case
class CancelSaleUseCase {
  final SaleRepositoryInterface repository;

  const CancelSaleUseCase(this.repository);

  /// Sotuvni bekor qilish (Admin/Owner). Backend audit row aktorini JWT'dan
  /// oladi — adminId bu yerdan o'tmaydi.
  Future<ApiResult<void>> call({required String saleId}) async {
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    return repository.cancelSale(saleId: saleId);
  }
}
