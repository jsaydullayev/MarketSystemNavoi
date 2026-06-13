// Product image section for the admin product form (edit mode only).
//
// Product images are optional and shown only in the sales (POS) flow to help
// the cashier identify a product. Uploading lives here, in the admin form,
// behind the products.edit permission. A product must already exist (have an
// id) to attach an image, so the parent renders this only when editing.
//
// Mirrors the profile-avatar picker UX: tap to choose Camera/Gallery, capture
// is downscaled (quality 50, max 1024px) so uploads stay small.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/product_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';

class AdminProductImageSection extends StatefulWidget {
  const AdminProductImageSection({
    super.key,
    required this.productId,
    this.initialImageUrl,
  });

  final String productId;

  /// Raw server-relative path (`imageUrl`) the product currently has, or null.
  final String? initialImageUrl;

  @override
  State<AdminProductImageSection> createState() =>
      _AdminProductImageSectionState();
}

class _AdminProductImageSectionState extends State<AdminProductImageSection> {
  late String? _imageUrl = widget.initialImageUrl;
  bool _isBusy = false;

  bool get _hasImage => _imageUrl != null && _imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiConstants.productImageUrl(_imageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Preview / tap target.
            GestureDetector(
              onTap: _isBusy ? null : _pickAndUpload,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isBusy
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: context.colors.brand,
                          ),
                        ),
                      )
                    : fullUrl != null
                    ? CachedNetworkImage(
                        imageUrl: fullUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 264,
                        errorWidget: (_, __, ___) => _placeholderIcon(context),
                      )
                    : _placeholderIcon(context),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isBusy ? null : _pickAndUpload,
                    icon: Icon(
                      _hasImage
                          ? Icons.swap_horiz_rounded
                          : Icons.add_photo_alternate_outlined,
                      size: 20,
                      color: context.colors.brand,
                    ),
                    label: Text(
                      _hasImage ? 'Rasmni almashtirish' : 'Rasm qo\'shish',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: context.colors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                  ),
                  if (_hasImage)
                    TextButton.icon(
                      onPressed: _isBusy ? null : _remove,
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Rasm savdo ekranida mahsulotni tezroq tanib olish uchun ko\'rsatiladi. (ixtiyoriy, maksimum 5MB)',
          style: AppTextStyles.caption().copyWith(color: context.colors.textMuted),
        ),
      ],
    );
  }

  Widget _placeholderIcon(BuildContext context) => Icon(
    Icons.inventory_2_outlined,
    size: 36,
    color: context.colors.brand,
  );

  Future<void> _pickAndUpload() async {
    final source = await _chooseSource();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    // Downscale at capture so a phone photo doesn't upload as multiple MB.
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null || !mounted) return;

    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final bytes = await picked.readAsBytes();
      final result = await ProductService(
        authProvider: auth,
      ).uploadProductImage(widget.productId, bytes, picked.name);

      if (!mounted) return;
      setState(() {
        _imageUrl = result is Map ? result['imageUrl'] as String? : _imageUrl;
        _isBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showError(messenger, e);
    }
  }

  Future<void> _remove() async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      await ProductService(authProvider: auth).removeProductImage(
        widget.productId,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _isBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showError(messenger, e);
    }
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
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
  }

  void _showError(ScaffoldMessengerState messenger, Object e) {
    var msg = e.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring(11);
    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }
}
