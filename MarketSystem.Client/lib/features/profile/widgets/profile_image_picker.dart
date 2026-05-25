// Profile avatar picker mapped to the demo's profile/logo upload visuals.
//
// Public API (unchanged):
// - [ProfileImagePicker]({ currentImageUrl, onImageUpdated })
//
// Visuals are light-only and based on the design system tokens:
// - 120x120 brand-light circle showing image, base64, or first letter
// - Brand-orange floating action chip with camera icon
// - Bottom sheet with two options: Galereya / Kamera (driven by image_picker)

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/services/user_service.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';

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

    return Center(
      child: GestureDetector(
        onTap: _isUploading ? null : () => _showImageSourceSheet(context),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.brandLight,
                border: Border.all(color: context.colors.surface, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.brand.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _isUploading
                    ? _buildLoadingOverlay()
                    : (profileImage != null && profileImage.isNotEmpty)
                    ? _buildSmartImage(profileImage)
                    : _buildDefaultPlaceholder(user),
              ),
            ),
            _buildEditBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartImage(String imageStr) {
    if (imageStr.startsWith('http')) {
      return CachedNetworkImage(imageUrl: imageStr, fit: BoxFit.cover);
    } else if (imageStr.startsWith('data:image') || imageStr.length > 100) {
      try {
        final base64Str = imageStr.contains(',')
            ? imageStr.split(',').last
            : imageStr;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {
        return Icon(
          Icons.broken_image_outlined,
          color: context.colors.textMuted,
        );
      }
    }
    return Icon(Icons.person_outline, color: context.colors.textMuted);
  }

  Widget _buildDefaultPlaceholder(dynamic user) {
    final initial = (user?['fullName'] ?? 'U')[0].toUpperCase();
    return Container(
      color: context.colors.brandLight,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.displayLarge().copyWith(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          color: context.colors.brand,
        ),
      ),
    );
  }

  Widget _buildEditBadge() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.brand,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: context.colors.brand.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.camera_alt_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: context.colors.brandLight,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.brand),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with two options. Mirrors the brand-light tile look used by
  /// the demo's settings rows / logo upload section.
  Future<void> _showImageSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Rasm tanlang', style: AppTextStyles.titleMedium()),
            const SizedBox(height: AppSpacing.xl),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              label: 'Kameradan',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Galereyadan',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      await _handleImagePick(source);
    }
  }

  Future<void> _handleImagePick(ImageSource source) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imageBytes = await image.readAsBytes();
      final result = await UserService(
        authProvider: auth,
      ).uploadProfileImage(imageBytes, image.name);

      if (widget.onImageUpdated != null && result != null) {
        widget.onImageUpdated!(result['profileImage']);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.brandLight,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: context.colors.brand, size: 20),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                label,
                style: AppTextStyles.bodyMedium().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.brandDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
