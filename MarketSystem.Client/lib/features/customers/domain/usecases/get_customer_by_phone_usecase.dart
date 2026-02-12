/// Get Customer By Phone Use Case
/// Telefon bo'yicha mijoz topish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository_interface.dart';

/// Get Customer By Phone Use Case
class GetCustomerByPhoneUseCase {
  final CustomerRepositoryInterface repository;

  const GetCustomerByPhoneUseCase(this.repository);

  /// Telefon bo'yicha mijoz topish
  Future<ApiResult<CustomerEntity?>> call(String phone) async {
    // Biznes validatsiya
    if (phone.isEmpty) {
      return ApiResult.failure('Telefon raqami bo\'sh bo\'lishi mumkin emas');
    }

    // Telefon raqami formatini tekshirish (998 bilan boshlanadi)
    if (phone.length != 12 || !phone.startsWith('998')) {
      return ApiResult.failure('Telefon raqami noto\'g\'ri formatda');
    }

    return repository.getCustomerByPhone(phone);
  }
}
