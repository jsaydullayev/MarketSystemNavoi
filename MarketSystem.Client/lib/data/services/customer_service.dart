import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class CustomerService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  CustomerService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Barcha mijozlarni olish
  Future<List<dynamic>> getAllCustomers() async {
    final response =
        await _httpService.get('${ApiConstants.customers}/GetAllCustomers');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load customers: ${response.statusCode}');
    }
  }

  // Telefon bo'yicha mijoz topish
  Future<dynamic> getCustomerByPhone(String phone) async {
    final response =
        await _httpService.get('${ApiConstants.customers}/phone/$phone');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load customer: ${response.statusCode}');
    }
  }

  // Yangi mijoz yaratish
  Future<dynamic> createCustomer({
    required String phone,
    String? fullName,
    String? comment,
    double? initialDebt,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.customers}/CreateCustomer',
      body: {
        'phone': phone,
        if (fullName != null) 'fullName': fullName,
        if (comment != null) 'comment': comment,
        if (initialDebt != null) 'initialDebt': initialDebt,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create customer: ${response.body}');
    }
  }

  // Mijoz ma'lumotlarini yangilash
  Future<dynamic> updateCustomer({
    required String phone,
    String? fullName,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.customers}/UpdateCustomer',
      body: {
        'phone': phone,
        if (fullName != null) 'fullName': fullName,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update customer: ${response.body}');
    }
  }

  // Mijozni o'chirish
  Future<void> deleteCustomer(String id) async {
    final response = await _httpService
        .delete('${ApiConstants.customers}/DeleteCustomer/$id');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete customer: ${response.body}');
    }
  }

  // Mijoz o'chirish ma'lumotlarini olish
  Future<Map<String, dynamic>> getCustomerDeleteInfo(String id) async {
    final response = await _httpService
        .get('${ApiConstants.customers}/GetCustomerDeleteInfo/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get customer delete info: ${response.body}');
    }
  }

  // Mijoz qarzlarini olish
  Future<List<Map<String, dynamic>>> getCustomerDebts(String customerId) async {
    final response = await _httpService
        .get('${ApiConstants.debts}/GetCustomerDebts/$customerId');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load customer debts: ${response.statusCode}');
    }
  }
}
