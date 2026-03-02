import '../../../../core/failure/api_result.dart';
import '../repositories/customer_repository_interface.dart';

/// Get customer debts use case
class GetCustomerDebtsUseCase {
  final CustomerRepositoryInterface repository;

  GetCustomerDebtsUseCase(this.repository);

  Future<ApiResult<List<Map<String, dynamic>>>> call(String customerId) async {
    // Validate customer ID
    if (customerId.isEmpty) {
      return ApiResult.failure('Customer ID is required');
    }

    return repository.getCustomerDebts(customerId);
  }
}
