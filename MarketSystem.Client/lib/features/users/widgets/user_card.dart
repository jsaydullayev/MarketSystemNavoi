import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/base64_image.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Staff row card matching `id="page-staff-list"` rows in the demo:
/// rounded avatar tile with role-tinted bg + online indicator dot,
/// name + `@username` + role chip (semantic colors per role),
/// trailing action buttons (activate/deactivate, delete).
class UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  // RBAC: users.manage bo'lmasa, bloklash/o'chirish tugmalari ko'rsatilmaydi.
  final bool canManage;

  const UserCard({
    super.key,
    required this.user,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onTap,
    this.canManage = true,
  });

  /// Role chip colors per design spec:
  /// - Admin: purple bg #F3E8FF, text #7C3AED
  /// - Seller: green bg #ECFDF5, text #047857
  /// - Owner: brand orange tones
  static const _adminBg = AppColors.roleAdminBg;
  static const _adminFg = AppColors.roleAdminFg;
  static const _sellerBg = AppColors.roleSellerBg;
  static const _sellerFg = AppColors.roleSellerFg;

  ({Color bg, Color fg}) _roleColors(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (bg: context.colors.brandLight, fg: context.colors.brandDark);
      case 'admin':
        return (bg: _adminBg, fg: _adminFg);
      case 'seller':
        return (bg: _sellerBg, fg: _sellerFg);
      default:
        return (bg: context.colors.inputFill, fg: context.colors.textSecondary);
    }
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.workspace_premium_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'seller':
        return Icons.storefront_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  /// 48×48 rounded avatar tile. Shows the user's uploaded profile photo when
  /// present — a full `http` URL renders via [CachedNetworkImage], a base64
  /// / data-URI payload via [Base64Image] (same URL-or-base64 handling the
  /// dashboard drawer uses for the current user). Falls back to the role-tinted
  /// initial tile when there's no image, it's still loading, or it fails to
  /// decode.
  Widget _buildAvatar(String? img, String initial, ({Color bg, Color fg}) c) {
    final fallback = _avatarFallback(initial, c);
    if (img == null || img.isEmpty) return fallback;

    Widget? imgWidget;
    if (img.startsWith('http')) {
      imgWidget = CachedNetworkImage(
        imageUrl: img,
        width: 48,
        height: 48,
        memCacheWidth: 144,
        memCacheHeight: 144,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      );
    } else if (img.startsWith('data:image') || img.length > 100) {
      final b64 = img.contains(',') ? img.split(',').last : img;
      imgWidget = Base64Image(
        data: b64,
        width: 48,
        height: 48,
        cacheWidth: 144,
        cacheHeight: 144,
        errorWidget: fallback,
      );
    }
    if (imgWidget == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: imgWidget,
    );
  }

  Widget _avatarFallback(String initial, ({Color bg, Color fg}) c) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: AppTextStyles.titleMedium().copyWith(
        color: c.fg,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = user['isActive'] ?? false;
    final role = user['role'] ?? '';
    final fullName = user['fullName'] ?? l10n.unknown;
    final username = user['username'] ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final profileImage = user['profileImage'] as String?;
    final colors = _roleColors(context, role);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: context.colors.border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg + 2,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildAvatar(profileImage, initial, colors),
                  // Online indicator dot (smena ochiq xodimlar uchun)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success
                            : context.colors.textMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTextStyles.bodyLarge().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@$username',
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(AppRadius.md - 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_roleIcon(role), size: 11, color: colors.fg),
                          const SizedBox(width: 4),
                          Text(
                            role,
                            style: AppTextStyles.caption().copyWith(
                              color: colors.fg,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions — faqat users.manage ruxsati bilan ko'rinadi.
              // Owner/SuperAdmin'ni esa bloklab/o'chirib bo'lmaydi (backend
              // 404 qaytaradi), shuning uchun ular uchun ham ko'rsatilmaydi.
              if (canManage &&
                  role.toLowerCase() != 'owner' &&
                  role.toLowerCase() != 'superadmin')
                Column(
                  children: [
                    _ActionBtn(
                      icon: isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      color: isActive ? AppColors.warning : AppColors.success,
                      onTap: onToggleStatus,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionBtn(
                      icon: Icons.delete_rounded,
                      color: AppColors.danger,
                      onTap: onDelete,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
