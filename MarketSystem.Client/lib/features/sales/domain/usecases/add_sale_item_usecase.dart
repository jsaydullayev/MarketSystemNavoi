/// Add Sale Item Use Case
/// Sotuvga mahsulot qo'shish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Add Sale Item Use Case
class AddSaleItemUseCase {
  final SaleRepositoryInterface repository;

  const AddSaleItemUseCase(this.repository);

  /// Sotuvga mahsulot qo'shish
  Future<ApiResult<void>> call({
    required String saleId,
    required String productId,
    required int quantity,
    required double salePrice,
    String? comment,
  }) async {
    // Biznes validatsiyalar
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    if (productId.isEmpty) {
      return ApiResult.failure('Mahsulot ID bo\'sh bo\'lishi mumkin emas');
    }

    if (quantity <= 0) {
      return ApiResult.failure('Miqdor 0 dan katta bo\'lishi kerak');
    }

    if (salePrice < 0) {
      return ApiResult.failure('Sotuv narxi manfiy bo\'lishi mumkin emas');
    }

    return repository.addSaleItem(
      saleId: saleId,
      productId: productId,
      quantity: quantity,
      salePrice: salePrice,
      comment: comment,
    );
  }
}
