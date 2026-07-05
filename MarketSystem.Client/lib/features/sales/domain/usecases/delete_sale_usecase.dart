// Delete Sale Use Case
// Sotuvni o'chirish biznes mantig'i (Owner data-cleanup)

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Delete Sale Use Case
///
/// Noto'g'ri kiritilgan sotuvni o'chirish (Owner). Backend yumshoq o'chirish
/// qiladi, ombor/kassani qaytaradi va amalni audit'ga yozadi — aktor JWT'dan
/// olinadi, bu yerdan uzatilmaydi.
class DeleteSaleUseCase {
  final SaleRepositoryInterface repository;

  const DeleteSaleUseCase(this.repository);

  Future<ApiResult<void>> call({required String saleId}) async {
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    return repository.deleteSale(saleId: saleId);
  }
}
