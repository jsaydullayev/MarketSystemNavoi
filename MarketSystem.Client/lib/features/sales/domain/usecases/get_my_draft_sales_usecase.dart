/// Get My Draft Sales Use Case
/// Mening draft sotuvlarimni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/sale_entity.dart';
import '../repositories/sale_repository_interface.dart';

/// Get My Draft Sales Use Case
class GetMyDraftSalesUseCase {
  final SaleRepositoryInterface repository;

  const GetMyDraftSalesUseCase(this.repository);

  /// Mening draft sotuvlarimni olish
  Future<ApiResult<List<SaleEntity>>> call() async {
    return repository.getMyDraftSales();
  }
}
