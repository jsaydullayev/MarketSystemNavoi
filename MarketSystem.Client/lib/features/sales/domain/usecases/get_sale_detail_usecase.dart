/// Get Sale Detail Use Case
/// Sotuv tafsilotlarini olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../repositories/sale_repository_interface.dart';

/// Get Sale Detail Use Case
class GetSaleDetailUseCase {
  final SaleRepositoryInterface repository;

  const GetSaleDetailUseCase(this.repository);

  /// Sotuv tafsilotlarini olish
  Future<ApiResult<Map<String, dynamic>>> call(String saleId) async {
    return repository.getSaleDetail(saleId);
  }
}
