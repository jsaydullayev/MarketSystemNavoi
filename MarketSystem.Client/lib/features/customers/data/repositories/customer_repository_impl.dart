/// Customer Repository Implementation
/// Customer Repository interfeysining amaliyoti

import '../../../../core/failure/api_result.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository_interface.dart';
import '../datasources/customer_remote_data_source.dart';

/// Customer Repository Implementation
class CustomerRepositoryImpl implements CustomerRepositoryInterface {
  final CustomerRemoteDataSource remoteDataSource;

  const CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResult<List<CustomerEntity>>> getAllCustomers() async {
    try {
      final data = await remoteDataSource.getAllCustomers();

      final customers = data
          .map((customerJson) =>
              CustomerEntity.fromJson(customerJson as Map<String, dynamic>))
          .toList();

      return ApiResult.success(customers);
    } catch (e) {
      return ApiResult.failure('Mijozlarni yuklashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<CustomerEntity?>> getCustomerByPhone(String phone) async {
    try {
      final data = await remoteDataSource.getCustomerByPhone(phone);

      if (data == null) {
        return ApiResult.success(null);
      }

      final customer = CustomerEntity.fromJson(data as Map<String, dynamic>);
      return ApiResult.success(customer);
    } catch (e) {
      return ApiResult.failure('Mijozni qidirishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<CustomerEntity>> createCustomer({
    required String phone,
    String? fullName,
    String? comment,
    double? initialDebt,
  }) async {
    try {
      final data = await remoteDataSource.createCustomer(
        phone: phone,
        fullName: fullName,
        comment: comment,
        initialDebt: initialDebt,
      );

      final customer = CustomerEntity.fromJson(data as Map<String, dynamic>);
      return ApiResult.success(customer);
    } catch (e) {
      return ApiResult.failure('Mijoz yaratishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<CustomerEntity>> updateCustomer({
    required String phone,
    String? fullName,
  }) async {
    try {
      final data = await remoteDataSource.updateCustomer(
        phone: phone,
        fullName: fullName,
      );

      final customer = CustomerEntity.fromJson(data as Map<String, dynamic>);
      return ApiResult.success(customer);
    } catch (e) {
      return ApiResult.failure('Mijoz ma\'lumotlarini yangilashda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<void>> deleteCustomer(String id) async {
    try {
      await remoteDataSource.deleteCustomer(id);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Mijozni o\'chirishda xatolik: $e');
    }
  }

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> getCustomerDebts(String customerId) async {
    try {
      final data = await remoteDataSource.getCustomerDebts(customerId);
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure('Mijoz qarzlarini yuklashda xatolik: $e');
    }
  }
}
