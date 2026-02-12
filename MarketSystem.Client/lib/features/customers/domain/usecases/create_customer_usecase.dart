/// Create Customer Use Case
/// Yangi mijoz yaratish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository_interface.dart';

/// Create Customer Use Case
class CreateCustomerUseCase {
  final CustomerRepositoryInterface repository;

  const CreateCustomerUseCase(this.repository);

  /// Yangi mijoz yaratish
  Future<ApiResult<CustomerEntity>> call({
    required String phone,
    String? fullName,
    String? comment,
  }) async {
    // Biznes validatsiyalar
    if (phone.isEmpty) {
      return ApiResult.failure('Telefon raqami bo\'sh bo\'lishi mumkin emas');
    }

    // Telefon raqami formatini tekshirish
    if (phone.length != 12 || !phone.startsWith('998')) {
      return ApiResult.failure('Telefon raqami noto\'g\'ri formatda (998********* ko\'rinishida bo\'lishi kerak)');
    }

    // Agar ism berilgan bo'lsa, u bo'sh bo'lmasligi kerak
    if (fullName != null && fullName!.trim().isEmpty) {
      return ApiResult.failure('Mijoz ismi bo\'sh bo\'lishi mumkin emas');
    }

    return repository.createCustomer(
      phone: phone,
      fullName: fullName?.trim(),
      comment: comment?.trim(),
    );
  }
}
