/// Return Sale Item Use Case
/// Sotilgan mahsulotni qaytarish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Return Sale Item Use Case
class ReturnSaleItemUseCase {
  final SaleRepositoryInterface repository;

  const ReturnSaleItemUseCase(this.repository);

  /// Sotilgan mahsulotni qaytarish
  Future<ApiResult<void>> call({
    required String saleId,
    required String saleItemId,
    required double quantity,
    String? comment,
  }) async {
    // Biznes validatsiyalar
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    if (saleItemId.isEmpty) {
      return ApiResult.failure('Mahsulot ID bo\'sh bo\'lishi mumkin emas');
    }

    if (quantity <= 0) {
      return ApiResult.failure('Miqdor 0 dan katta bo\'lishi kerak');
    }

    return repository.returnSaleItem(
      saleId: saleId,
      saleItemId: saleItemId,
      quantity: quantity,
      comment: comment,
    );
  }
}
