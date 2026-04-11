import 'dart:convert';
import 'dart:io';
import 'http_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';

class UserService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  UserService({required this.authProvider}) {
    _httpService = HttpService();
  }

  // Get my profile
  Future<dynamic> getMyProfile() async {
    final response = await _httpService.get('${ApiConstants.users}/MyProfile');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
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
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Upload profile image - use base64 JSON (Windows compatible)
  Future<dynamic> uploadProfileImage(String imagePath) async {
    try {
      // Check file size first (before reading entire file)
      final file = File(imagePath);
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);

      if (fileSizeInMB > 5) {
        throw Exception('Rasm hajmi juda katta. Iltimos, kichikroq rasm tanlang (maksimum 5MB).');
      }

      // Read file and convert to base64
      final imageBytes = await file.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Determine MIME type from file extension
      final extension = imagePath.toLowerCase().split('.').last;
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      // Send as JSON body - Windows compatible!
      final response = await _httpService.put(
        '${ApiConstants.users}/UpdateProfileImage',
        body: {
          'profileImage': 'data:$mimeType;base64,$base64Image',
        },
      );

      if (response.statusCode == 200) {
        // For successful upload, parse JSON response
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception('Server javobini o\'qib bo\'lmadi');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Avtorizatsiya xatosi. Iltimos, qaytadan kiring.');
      } else {
        // Parse error message for better debugging
        String errorMessage = 'Xatolik: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          // Handle common errors
          if (errorMessage.contains('5MB') || errorMessage.contains('5 MB')) {
            errorMessage = 'Rasm hajmi juda katta. Maksimum 5MB.';
          }
        } catch (_) {
          // If JSON parse fails, use raw body (truncated)
          final bodyPreview = response.body.length > 200
              ? '${response.body.substring(0, 200)}...'
              : response.body;
          errorMessage = 'Xatolik ($response.statusCode): $bodyPreview';
        }
        throw Exception(errorMessage);
      }
    } on FileSystemException catch (e) {
      throw Exception('Faylni o\'qib bo\'lmadi: ${e.message}');
    } catch (e) {
      throw Exception('Rasm yuklashda xatolik: $e');
    }
  }
}
