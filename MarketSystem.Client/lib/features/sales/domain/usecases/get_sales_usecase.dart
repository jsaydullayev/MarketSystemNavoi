// Get Sales Use Case
// Barcha sotuvlarni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/sale_entity.dart';
import '../entities/sale_page_result.dart';
import '../repositories/sale_repository_interface.dart';

class GetSalesUseCase {
  final SaleRepositoryInterface repository;

  const GetSalesUseCase(this.repository);

  Future<ApiResult<List<SaleEntity>>> call() async {
    return repository.getAllSales();
  }

  Future<ApiResult<SalePageResult>> paged({int page = 1, int size = 50}) async {
    return repository.getPagedSales(page: page, size: size);
  }
}
