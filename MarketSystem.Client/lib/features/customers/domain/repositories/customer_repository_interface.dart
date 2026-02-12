/// Customer Repository Interface
/// Mijoz repository interfeysi - data layer uchun kontrakt

import '../../../../core/failure/api_result.dart';
import '../entities/customer_entity.dart';

/// Customer Repository Interface
/// Data layer implementation qilishi kerak bo'lgan metodlar
abstract class CustomerRepositoryInterface {
  /// Barcha mijozlarni olish
  Future<ApiResult<List<CustomerEntity>>> getAllCustomers();

  /// Telefon bo'yicha mijoz topish
  Future<ApiResult<CustomerEntity?>> getCustomerByPhone(String phone);

  /// Yangi mijoz yaratish
  Future<ApiResult<CustomerEntity>> createCustomer({
    required String phone,
    String? fullName,
    String? comment,
  });

  /// Mijoz ma'lumotlarini yangilash
  Future<ApiResult<CustomerEntity>> updateCustomer({
    required String phone,
    String? fullName,
  });

  /// Mijozni o'chirish
  Future<ApiResult<void>> deleteCustomer(String id);
}
