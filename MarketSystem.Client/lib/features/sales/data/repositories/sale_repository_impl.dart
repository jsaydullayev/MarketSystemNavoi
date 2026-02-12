/// Sale Repository Implementation
/// Sale Repository interfeysining amaliyoti

import '../../../../core/failure/api_result.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sale_repository_interface.dart';
import '../datasources/sale_remote_data_source.dart';

/// Sale Repository Implementation
class SaleRepositoryImpl implements SaleRepositoryInterface {
  final SaleRemoteDataSource remoteDataSource;

  const SaleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResult<List<SaleEntity>>> getAllSales() async {
    try {
      final data = await remoteDataSource.getAllSales();

      final sales = data
          .map((saleJson) => SaleEntity.fromJson(saleJson as Map<String, dynamic>))
          .toList();

      return ApiResult.success(sales);
    } catch (e) {
      return ApiResult.failure('Sotuvlarni yuklashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<List<SaleEntity>>> getMyDraftSales() async {
    try {
      final data = await remoteDataSource.getMyDraftSales();

      final sales = data
          .map((saleJson) => SaleEntity.fromJson(saleJson as Map<String, dynamic>))
          .toList();

      return ApiResult.success(sales);
    } catch (e) {
      return ApiResult.failure('Draft sotuvlarni yuklashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<SaleEntity>> createSale({String? customerId}) async {
    try {
      final data = await remoteDataSource.createSale(customerId: customerId);

      final sale = SaleEntity.fromJson(data as Map<String, dynamic>);

      return ApiResult.success(sale);
    } catch (e) {
      return ApiResult.failure('Sotuv yaratishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<void>> addSaleItem({
    required String saleId,
    required String productId,
    required int quantity,
    required double salePrice,
    String? comment,
  }) async {
    try {
      await remoteDataSource.addSaleItem(
        saleId: saleId,
        productId: productId,
        quantity: quantity,
        salePrice: salePrice,
        comment: comment,
      );

      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Mahsulot qo\'shishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<void>> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
  }) async {
    try {
      await remoteDataSource.addPayment(
        saleId: saleId,
        paymentType: paymentType,
        amount: amount,
      );

      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('To\'lov qo\'shishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<void>> cancelSale({
    required String saleId,
    required String adminId,
  }) async {
    try {
      await remoteDataSource.cancelSale(
        saleId: saleId,
        adminId: adminId,
      );

      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Sotuvni bekor qilishda xatolik: $e');
    }
  }
}
