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

  // Upload profile image
  Future<dynamic> uploadProfileImage(String imagePath) async {
    try {
      // Read image file and convert to base64
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      // Check file size (max 5MB before base64 encoding)
      final fileSizeInMB = bytes.length / (1024 * 1024);
      if (fileSizeInMB > 5) {
        throw Exception('Rasm hajmi juda katta. Iltimos, kichikroq rasm tanlang (maksimum 5MB).');
      }

      final base64Image = base64Encode(bytes);

      // Check base64 size (should be under 10MB)
      final base64SizeInMB = base64Image.length / (1024 * 1024);
      if (base64SizeInMB > 10) {
        throw Exception('Rasm hajmi encodingdan keyin juda katta bo\'ldi. Iltimos, kichikroq rasm tanlang.');
      }

      final response = await _httpService.put(
        '${ApiConstants.users}/UpdateProfileImage',
        body: {
          'profileImage': 'data:image/jpeg;base64,$base64Image',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Parse error message for better debugging
        String errorMessage = 'Failed to upload image: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Failed to upload image: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
