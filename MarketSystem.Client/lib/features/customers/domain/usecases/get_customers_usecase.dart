/// Get Customers Use Case
/// Barcha mijozlarni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository_interface.dart';

/// Get Customers Use Case
class GetCustomersUseCase {
  final CustomerRepositoryInterface repository;

  const GetCustomersUseCase(this.repository);

  /// Barcha mijozlarni olish
  Future<ApiResult<List<CustomerEntity>>> call() async {
    return repository.getAllCustomers();
  }
}
