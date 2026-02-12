/// Add Payment Use Case
/// Sotuvga to'lov qo'shish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Add Payment Use Case
class AddPaymentUseCase {
  final SaleRepositoryInterface repository;

  const AddPaymentUseCase(this.repository);

  /// Sotuvga to'lov qo'shish
  Future<ApiResult<void>> call({
    required String saleId,
    required String paymentType,
    required double amount,
  }) async {
    // Biznes validatsiyalar
    if (saleId.isEmpty) {
      return ApiResult.failure('Sotuv ID bo\'sh bo\'lishi mumkin emas');
    }

    if (paymentType.isEmpty) {
      return ApiResult.failure('To\'lov turi bo\'sh bo\'lishi mumkin emas');
    }

    if (amount <= 0) {
      return ApiResult.failure('To\'lov miqdori 0 dan katta bo\'lishi kerak');
    }

    return repository.addPayment(
      saleId: saleId,
      paymentType: paymentType,
      amount: amount,
    );
  }
}
