import 'dart:convert';

import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class UsersService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  UsersService({required this.authProvider, HttpService? httpService})
      : _httpService = httpService ?? HttpService();


  // Barcha userlarni olish
  Future<List<dynamic>> getAllUsers() async {
    final response =
        await _httpService.get('${ApiConstants.users}/GetAllUsers');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to load users');
    }
  }

  // User by ID
  Future<dynamic> getUserById(String id) async {
    final response =
        await _httpService.get('${ApiConstants.users}/GetUser/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to load user');
    }
  }

  // Yangi user yaratish (Admin/Owner only)
  Future<dynamic> createUser({
    required String fullName,
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await _httpService.post(
      '${ApiConstants.users}/CreateUser',
      body: {
        'fullName': fullName,
        'username': username,
        'password': password,
        'role': role,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to create user');
    }
  }

  // User yangilash (Admin/Owner only)
  Future<dynamic> updateUser({
    required String id,
    required String fullName,
    String? password,
    required String role,
    required bool isActive,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.users}/UpdateUser/$id',
      body: {
        'id': id,
        'fullName': fullName,
        if (password != null) 'password': password,
        'role': role,
        'isActive': isActive,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to update user');
    }
  }

  // User o'chirish
  Future<void> deleteUser(dynamic id) async {
    final response = await _httpService.delete(
      '${ApiConstants.users}/DeleteUser/$id',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to delete user');
    }
  }

  // User deactivate/activate
  // Backend route: POST /api/Users/{Deactivate,Activate}User/{id}/{deactivate,activate}
  // The ApiConstants helpers keep the (doubled-segment) shape in one place
  // so the original `/api/Users/api/Users/...` copy-paste typo can't sneak
  // back in.
  Future<void> deactivateUser(dynamic id) async {
    final response = await _httpService.post(
      ApiConstants.deactivateUser(id),
      body: {},
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to deactivate');
    }
  }

  Future<void> activateUser(dynamic id) async {
    final response = await _httpService.post(
      ApiConstants.activateUser(id),
      body: {},
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response, fallbackMessage: 'Failed to activate');
    }
  }

  // Seller smenasini o'rnatish (Admin/Owner only).
  // Backend route: PUT /api/Users/UpdateShift/{id}/shift
  // [status] is 'Active' | 'Blocked' | 'Scheduled'; the window is required
  // only for 'Scheduled' and is sent as UTC ISO-8601.
  Future<dynamic> updateShift({
    required String id,
    required String status,
    DateTime? startUtc,
    DateTime? endUtc,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.users}/UpdateShift/$id/shift',
      body: {
        'status': status,
        if (startUtc != null) 'startUtc': startUtc.toUtc().toIso8601String(),
        if (endUtc != null) 'endUtc': endUtc.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    // ApiException.fromResponse picks up the `message` field on its own;
    // the previous manual try/jsonDecode block is redundant now.
    throw ApiException.fromResponse(response, fallbackMessage: 'Failed to update shift');
  }
}
