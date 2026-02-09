import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Yaxshi sifat
        maxWidth: 600,   // Yaxshi o'lcham
        maxHeight: 600,  // Yaxshi o'lcham
      );

      if (image != null && mounted) {
        setState(() => _isUploading = true);

        // Upload image to server
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final userService = UserService(authProvider: authProvider);

          final result = await userService.uploadProfileImage(image.path);

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil rasmi muvaffaqiyatli yangilandi!'),
                backgroundColor: Colors.green,
              ),
            );

            // Notify parent widget with the new image URL
            if (widget.onImageUpdated != null && result != null) {
              widget.onImageUpdated!(result['profileImage']);
            }
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rasmni yuklashda xatolik: $uploadError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isUploading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasmni tanlashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper method to build image from base64 or URL
  Widget _buildProfileImage(String imageString) {
    // Check if it's a base64 data URL
    if (imageString.startsWith('data:image/')) {
      try {
        // Extract base64 data
        final base64Data = imageString.split(',').last;
        final imageBytes = base64Decode(base64Data);

        return Image.memory(
          imageBytes,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } catch (e) {
        // If base64 decode fails, show default avatar
        return _buildDefaultAvatar();
      }
    }
    // If it's a URL (http/https), use Image.network
    else if (imageString.startsWith('http')) {
      return Image.network(
        imageString,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    // Otherwise, try as raw base64
    else {
      try {
        final imageBytes = base64Decode(imageString);
        return Image.memory(
          imageBytes,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final profileImage = widget.currentImageUrl ?? user?['profileImage'];

    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: Colors.blue.shade300,
                width: 3,
              ),
            ),
            child: _isUploading
                ? const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : profileImage != null && profileImage.isNotEmpty
                    ? ClipOval(
                        child: _buildProfileImage(profileImage),
                      )
                    : _buildDefaultAvatar(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final user = Provider.of<AuthProvider>(context).user;
    final initial = (user?['fullName'] ?? 'U')[0].toUpperCase();

    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.purple],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
