/// Delete Customer Use Case
/// Mijozni o'chirish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/customer_repository_interface.dart';

/// Delete Customer Use Case
class DeleteCustomerUseCase {
  final CustomerRepositoryInterface repository;

  const DeleteCustomerUseCase(this.repository);

  /// Mijozni o'chirish
  Future<ApiResult<void>> call(String id) async {
    // Biznes validatsiya
    if (id.isEmpty) {
      return ApiResult.failure('Mijoz ID bo\'sh bo\'lishi mumkin emas');
    }

    return repository.deleteCustomer(id);
  }
}
