import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class UsersService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  UsersService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Barcha userlarni olish
  Future<List<dynamic>> getAllUsers() async {
    final response =
        await _httpService.get('${ApiConstants.users}/GetAllUsers');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  // User by ID
  Future<dynamic> getUserById(String id) async {
    final response =
        await _httpService.get('${ApiConstants.users}/GetUser/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
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
      throw Exception('Failed to create user: ${response.body}');
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
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // User o'chirish
  Future<void> deleteUser(dynamic id) async {
    final response = await _httpService.delete(
      '${ApiConstants.users}/DeleteUser/api/Users/DeleteUser/$id',
    );

    print('DELETE url: ${ApiConstants.users}/DeleteUser/$id');
    print('DELETE status: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = response.body.isNotEmpty
          ? response.body
          : 'Server javobi yo\'q (${response.statusCode})';
      throw Exception('Failed to delete user: $msg');
    }
  }

  // User deactivate/activate
  Future<void> deactivateUser(dynamic id) async {
    final response = await _httpService.post(
      '${ApiConstants.users}/DeactivateUser/api/Users/$id/deactivate',
      body: {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deactivate: ${response.body}');
    }
  }

  Future<void> activateUser(dynamic id) async {
    final response = await _httpService.post(
      '${ApiConstants.users}/ActivateUser/api/Users/$id/activate',
      body: {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to activate: ${response.body}');
    }
  }
}
