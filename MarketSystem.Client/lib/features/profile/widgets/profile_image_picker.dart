import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/user_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String)? onImageUpdated;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.onImageUpdated,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profileImage = widget.currentImageUrl ?? user?['profileImage'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(context);

    return GestureDetector(
      onTap: _isUploading ? null : () => _handleImagePick(context),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: _isUploading
                  ? _buildLoadingOverlay()
                  : (profileImage != null && profileImage.isNotEmpty)
                      ? _buildSmartImage(profileImage)
                      : _buildDefaultPlaceholder(user, primaryColor),
            ),
          ),
          _buildEditIcon(primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildSmartImage(String imageStr) {
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover);
    } else if (imageStr.startsWith('data:image') || imageStr.length > 100) {
      try {
        final base64Str =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image_outlined);
      }
    }
    return const Icon(Icons.person_outline);
  }

  Widget _buildDefaultPlaceholder(dynamic user, Color primary) {
    final initial = (user?['fullName'] ?? 'U')[0].toUpperCase();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initial,
            style: AppStyles.brandTitle
                .copyWith(fontSize: 40, color: Colors.white)),
      ),
    );
  }

  Widget _buildEditIcon(Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        border: Border.all(
            color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 3),
      ),
      child:
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildLoadingOverlay() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }

  Future<void> _handleImagePick(BuildContext context) async {
    print('=== PROFILE IMAGE PICKER START ===');

    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    print('Image picked: ${image != null}');
    print('Image path: ${image?.path}');

    if (image == null) {
      print('No image selected, returning');
      return;
    }

    setState(() => _isUploading = true);

    try {
      print('Starting upload...');
      final auth = Provider.of<AuthProvider>(context, listen: false);
      print('Auth provider obtained');

      final result =
          await UserService(authProvider: auth).uploadProfileImage(image.path);

      print('Upload result: $result');

      if (widget.onImageUpdated != null && result != null) {
        widget.onImageUpdated!(result['profileImage']);
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        String errorMessage = e.toString();
        // Remove "Exception: " prefix for cleaner display
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
