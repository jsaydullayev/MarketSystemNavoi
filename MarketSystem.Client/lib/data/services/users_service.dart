import 'dart:convert';

import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

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
      '${ApiConstants.users}/DeleteUser/$id',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = response.body.isNotEmpty
          ? response.body
          : 'Server javobi yo\'q (${response.statusCode})';
      throw Exception('Failed to delete user: $msg');
    }
  }

  // User deactivate/activate
  // Backend route: POST /api/Users/{Deactivate,Activate}User/{id}/{deactivate,activate}
  // (The doubled `/api/Users/` in the old path was a copy-paste artifact that
  // 404'd on every call.)
  // TODO: hoist into ApiConstants as `deactivateUser(id)` / `activateUser(id)` helpers.
  Future<void> deactivateUser(dynamic id) async {
    final response = await _httpService.post(
      '${ApiConstants.users}/DeactivateUser/$id/deactivate',
      body: {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deactivate: ${response.body}');
    }
  }

  Future<void> activateUser(dynamic id) async {
    final response = await _httpService.post(
      '${ApiConstants.users}/ActivateUser/$id/activate',
      body: {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to activate: ${response.body}');
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

    // The backend returns { "message": "..." } on a 400 (bad window etc.).
    String msg = 'Failed to update shift: ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        msg = body['message'].toString();
      }
    } catch (_) {}
    throw Exception(msg);
  }
}
