/// Zakup Repository Implementation
/// Zakup Repository interfeysining amaliyoti

import '../../../../core/failure/api_result.dart';
import '../../domain/entities/zakup_entity.dart';
import '../../domain/repositories/zakup_repository_interface.dart';
import '../datasources/zakup_remote_data_source.dart';

/// Zakup Repository Implementation
class ZakupRepositoryImpl implements ZakupRepositoryInterface {
  final ZakupRemoteDataSource remoteDataSource;

  const ZakupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResult<List<ZakupEntity>>> getAllZakups() async {
    try {
      final data = await remoteDataSource.getAllZakups();

      final zakups = data
          .map((zakupJson) =>
              ZakupEntity.fromJson(zakupJson as Map<String, dynamic>))
          .toList();

      return ApiResult.success(zakups);
    } catch (e) {
      return ApiResult.failure('Xaridlarni yuklashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<List<ZakupEntity>>> getZakupsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final data = await remoteDataSource.getZakupsByDateRange(start, end);

      final zakups = data
          .map((zakupJson) =>
              ZakupEntity.fromJson(zakupJson as Map<String, dynamic>))
          .toList();

      return ApiResult.success(zakups);
    } catch (e) {
      return ApiResult.failure('Sana bo\'yicha xaridlarni yuklashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<ZakupEntity>> createZakup({
    required String productId,
    required double quantity,
    required double costPrice,
  }) async {
    try {
      final data = await remoteDataSource.createZakup(
        productId: productId,
        quantity: quantity,
        costPrice: costPrice,
      );

      final zakup = ZakupEntity.fromJson(data as Map<String, dynamic>);
      return ApiResult.success(zakup);
    } catch (e) {
      return ApiResult.failure('Xarid yaratishda xatolik: $e');
    }
  }
}
