/// Customer Remote Data Source
/// Customers API dan ma'lumot olish

import '../../../../data/services/customer_service.dart';

/// Customer Remote Data Source
/// API bilan ishlash uchun mas'ul
class CustomerRemoteDataSource {
  final CustomerService _customerService;

  const CustomerRemoteDataSource({required CustomerService customerService})
      : _customerService = customerService;

  /// Barcha mijozlarni olish
  Future<List<dynamic>> getAllCustomers() async {
    return _customerService.getAllCustomers();
  }

  /// Telefon bo'yicha mijoz topish
  Future<dynamic> getCustomerByPhone(String phone) async {
    return _customerService.getCustomerByPhone(phone);
  }

  /// Yangi mijoz yaratish
  Future<dynamic> createCustomer({
    required String phone,
    String? fullName,
    String? comment,
    double? initialDebt,
  }) async {
    return _customerService.createCustomer(
      phone: phone,
      fullName: fullName,
      comment: comment,
      initialDebt: initialDebt,
    );
  }

  /// Mijoz ma'lumotlarini yangilash
  Future<dynamic> updateCustomer({
    required String phone,
    String? fullName,
  }) async {
    return _customerService.updateCustomer(
      phone: phone,
      fullName: fullName,
    );
  }

  /// Mijozni o'chirish
  Future<void> deleteCustomer(String id) async {
    return _customerService.deleteCustomer(id);
  }

  /// Mijoz qarzlarini olish
  Future<List<Map<String, dynamic>>> getCustomerDebts(String customerId) async {
    return _customerService.getCustomerDebts(customerId);
  }
}
