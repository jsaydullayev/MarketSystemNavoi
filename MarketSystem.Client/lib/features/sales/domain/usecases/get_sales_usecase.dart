/// Get Sales Use Case
/// Barcha sotuvlarni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/sale_entity.dart';
import '../repositories/sale_repository_interface.dart';

/// Get Sales Use Case
class GetSalesUseCase {
  final SaleRepositoryInterface repository;

  const GetSalesUseCase(this.repository);

  /// Barcha sotuvlarni olish
  Future<ApiResult<List<SaleEntity>>> call() async {
    return repository.getAllSales();
  }
}
