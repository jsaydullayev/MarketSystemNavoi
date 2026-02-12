/// Update Customer Use Case
/// Mijoz ma'lumotlarini yangilash biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository_interface.dart';

/// Update Customer Use Case
class UpdateCustomerUseCase {
  final CustomerRepositoryInterface repository;

  const UpdateCustomerUseCase(this.repository);

  /// Mijoz ma'lumotlarini yangilash
  Future<ApiResult<CustomerEntity>> call({
    required String phone,
    String? fullName,
  }) async {
    // Biznes validatsiyalar
    if (phone.isEmpty) {
      return ApiResult.failure('Telefon raqami bo\'sh bo\'lishi mumkin emas');
    }

    // Telefon raqami formatini tekshirish
    if (phone.length != 12 || !phone.startsWith('998')) {
      return ApiResult.failure('Telefon raqami noto\'g\'ri formatda');
    }

    // Agar ism berilgan bo'lsa, u bo'sh bo'lmasligi kerak
    if (fullName != null && fullName!.trim().isEmpty) {
      return ApiResult.failure('Mijoz ismi bo\'sh bo\'lishi mumkin emas');
    }

    return repository.updateCustomer(
      phone: phone,
      fullName: fullName?.trim(),
    );
  }
}
