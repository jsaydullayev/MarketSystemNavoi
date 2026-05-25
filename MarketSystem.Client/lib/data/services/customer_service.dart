import 'dart:convert';

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class CustomerService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  CustomerService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  Future<List<dynamic>> getAllCustomers() async {
    final response = await _httpService.get(
      '${ApiConstants.customers}/GetAllCustomers',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customers',
      );
    }
  }

  Future<Map<String, dynamic>> getCustomersPaged({
    int page = 1,
    int size = 50,
    String? search,
  }) async {
    var url =
        '${ApiConstants.customers}/GetCustomersPaged?page=$page&size=$size';
    if (search != null && search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }
    final response = await _httpService.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customers',
      );
    }
  }

  // Telefon bo'yicha mijoz topish
  Future<dynamic> getCustomerByPhone(String phone) async {
    final response = await _httpService.get(
      ApiConstants.customerByPhone(phone),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customer',
      );
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
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to create customer',
      );
    }
  }

  // Mijoz ma'lumotlarini yangilash
  Future<dynamic> updateCustomer({
    required String phone,
    String? fullName,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.customers}/UpdateCustomer',
      body: {'phone': phone, if (fullName != null) 'fullName': fullName},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to update customer',
      );
    }
  }

  // Mijozni o'chirish
  Future<void> deleteCustomer(String id) async {
    final response = await _httpService.delete(
      '${ApiConstants.customers}/DeleteCustomer/$id',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete customer',
      );
    }
  }

  // Mijoz o'chirish ma'lumotlarini olish
  Future<Map<String, dynamic>> getCustomerDeleteInfo(String id) async {
    final response = await _httpService.get(
      ApiConstants.customerDeleteInfo(id),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to get customer delete info',
      );
    }
  }

  // Mijoz qarzlarini olish
  Future<List<Map<String, dynamic>>> getCustomerDebts(String customerId) async {
    final response = await _httpService.get(
      '${ApiConstants.debts}/GetCustomerDebts/$customerId',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load customer debts',
      );
    }
  }
}
