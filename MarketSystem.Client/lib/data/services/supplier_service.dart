import 'dart:convert';

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

/// HTTP client for the Suppliers (yetkazib beruvchilar) directory. Mirrors
/// [CustomerService]: every call routes through the shared [HttpService] which
/// attaches the auth token and tenant headers.
class SupplierService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  SupplierService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  Future<List<dynamic>> getAllSuppliers() async {
    final response = await _httpService.get(
      '${ApiConstants.suppliers}/GetAllSuppliers',
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to load suppliers',
    );
  }

  Future<Map<String, dynamic>> getSuppliersPaged({
    int page = 1,
    int size = 50,
    String? search,
  }) async {
    var url =
        '${ApiConstants.suppliers}/GetSuppliersPaged?page=$page&size=$size';
    if (search != null && search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }
    final response = await _httpService.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to load suppliers',
    );
  }

  Future<dynamic> createSupplier({
    required String name,
    String? phone,
    String? address,
    String? comment,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.suppliers}/CreateSupplier',
      body: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to create supplier',
    );
  }

  Future<dynamic> updateSupplier({
    required String id,
    String? name,
    String? phone,
    String? address,
    String? comment,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.suppliers}/UpdateSupplier',
      body: {
        'id': id,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (comment != null) 'comment': comment,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to update supplier',
    );
  }

  Future<void> deleteSupplier(String id) async {
    final response = await _httpService.delete(
      ApiConstants.deleteSupplier(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to delete supplier',
      );
    }
  }

  Future<List<int>?> downloadSuppliersExcel() async {
    return await _httpService.downloadBytes(ApiConstants.suppliersExportExcel);
  }
}
