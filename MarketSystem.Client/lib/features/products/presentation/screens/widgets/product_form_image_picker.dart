// Image picker for the product add/edit form (ProductBottomSheet).
//
// Unlike the admin section (which uploads immediately), this picker DEFERS the
// upload: it only surfaces the chosen bytes to the parent, which uploads them
// after the product is created/updated (a new product has no id until saved).
// Source is camera OR gallery, downscaled at capture to keep uploads small.
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../design/tokens/app_theme_colors.dart';
import '../../../../../design/tokens/app_tokens.dart';
import '../../../../../design/tokens/app_typography.dart';

class ProductFormImagePicker extends StatelessWidget {
  const ProductFormImagePicker({
    super.key,
    required this.pickedBytes,
    required this.existingImageUrl,
    required this.removed,
    required this.onPicked,
    required this.onRemoved,
  });

  /// Locally chosen image not yet uploaded (preview via memory).
  final Uint8List? pickedBytes;

  /// Raw server-relative path the product already has (edit mode), or null.
  final String? existingImageUrl;

  /// True after the user tapped remove (hide the existing image).
  final bool removed;

  final void Function(Uint8List bytes, String name) onPicked;
  final VoidCallback onRemoved;

  bool get _showsExisting =>
      pickedBytes == null && !removed && (existingImageUrl?.isNotEmpty ?? false);

  bool get _hasSomething => pickedBytes != null || _showsExisting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _chooseAndPick(context),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPreview(context),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => _chooseAndPick(context),
                icon: Icon(
                  _hasSomething
                      ? Icons.swap_horiz_rounded
                      : Icons.add_photo_alternate_outlined,
                  size: 20,
                  color: context.colors.brand,
                ),
                label: Text(
                  _hasSomething ? 'Rasmni almashtirish' : 'Rasm qo\'shish',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
              ),
              if (_hasSomething)
                TextButton.icon(
                  onPressed: onRemoved,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'Rasmni o\'chirish',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (pickedBytes != null) {
      return Image.memory(pickedBytes!, fit: BoxFit.cover);
    }
    if (_showsExisting) {
      final full = ApiConstants.productImageUrl(existingImageUrl);
      if (full != null) {
        return CachedNetworkImage(
          imageUrl: full,
          fit: BoxFit.cover,
          memCacheWidth: 252,
          errorWidget: (_, __, ___) => _placeholder(context),
        );
      }
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) => Icon(
    Icons.inventory_2_outlined,
    size: 34,
    color: context.colors.brand,
  );

  Future<void> _chooseAndPick(BuildContext context) async {
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
            ListTile(
              leading: Icon(
                Icons.photo_camera_rounded,
                color: context.colors.brand,
              ),
              title: const Text('Kameradan'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: context.colors.brand,
              ),
              title: const Text('Galereyadan'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    onPicked(bytes, image.name);
  }
}
