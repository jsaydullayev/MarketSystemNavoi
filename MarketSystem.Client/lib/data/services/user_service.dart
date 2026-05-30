import 'dart:convert';
import 'http_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';

class UserService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  UserService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  // Get my profile
  Future<dynamic> getMyProfile() async {
    final response = await _httpService.get('${ApiConstants.users}/MyProfile');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load profile',
      );
    }
  }

  // Update my profile
  Future<dynamic> updateProfile({
    String? fullName,
    String? currentPassword,
    String? newPassword,
  }) async {
    final response = await _httpService.put(
      '${ApiConstants.users}/UpdateMyProfile',
      body: {
        if (fullName != null) 'fullName': fullName,
        if (currentPassword != null) 'currentPassword': currentPassword,
        if (newPassword != null) 'newPassword': newPassword,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to update profile',
      );
    }
  }

  // Upload profile image - use base64 JSON (all platforms compatible)
  //
  // ApiException-2 — converted from the old "throw Exception" pattern so
  // the call site (ProfileImagePicker) can branch on `ApiException.statusCode`
  // / `.code` instead of substring-matching error messages. The previous
  // pattern double-wrapped errors as `Exception: Exception: ...` because the
  // outer catch re-wrapped whatever the inner try produced.
  Future<dynamic> uploadProfileImage(
    List<int> imageBytes,
    String filename,
  ) async {
    final fileSizeInMB = imageBytes.length / (1024 * 1024);
    if (fileSizeInMB > 5) {
      throw ApiException(
        statusCode: 0,
        message:
            'Rasm hajmi juda katta. Iltimos, kichikroq rasm tanlang (maksimum 5MB).',
      );
    }

    final base64Image = base64Encode(imageBytes);
    final extension = filename.toLowerCase().split('.').last;
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final response = await _httpService.put(
      '${ApiConstants.users}/UpdateProfileImage',
      body: {'profileImage': 'data:$mimeType;base64,$base64Image'},
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
          statusCode: 200,
          message: 'Server javobini o\'qib bo\'lmadi',
        );
      }
    }
    if (response.statusCode == 404) {
      // G7 — backend S3 added market-scoping to UpdateProfileImage. The
      // service now returns 404 when the looked-up user's MarketId doesn't
      // match the caller's current market — most commonly a freshly-
      // registered Owner who hasn't created their market yet. Surface
      // a directed message instead of a generic 404.
      throw ApiException(
        statusCode: 404,
        message:
            'Avval do\'kon yarating, keyin profil rasmini o\'zgartirishingiz mumkin.',
      );
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Rasm yuklashda xatolik',
    );
  }

  // --- Owner RBAC — per-user permission management (Owner-only) ---------

  /// Reads one user's permission configuration. Returns a map shaped like
  /// the backend `UserPermissionsDto`: userId, role, isCustomized,
  /// effectivePermissions[], roleDefaults[], catalog[].
  Future<Map<String, dynamic>> getUserPermissions(String userId) async {
    final response = await _httpService.get(
      '${ApiConstants.users}/GetUserPermissions/$userId',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to load permissions',
    );
  }

  /// Overwrites a user's explicit permission set. Pass an empty list to reset
  /// the user back to its role default. Returns the refreshed configuration.
  Future<Map<String, dynamic>> updateUserPermissions(
    String userId,
    List<String> permissions,
  ) async {
    final response = await _httpService.put(
      '${ApiConstants.users}/UpdateUserPermissions/$userId',
      body: {'permissions': permissions},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to update permissions',
    );
  }
}
