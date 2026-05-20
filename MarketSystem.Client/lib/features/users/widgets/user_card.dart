import 'package:flutter/material.dart';
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

  const UserCard({
    super.key,
    required this.user,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onTap,
  });

  /// Role chip colors per design spec:
  /// - Admin: purple bg #F3E8FF, text #7C3AED
  /// - Seller: green bg #ECFDF5, text #047857
  /// - Owner: brand orange tones
  static const _adminBg = Color(0xFFF3E8FF);
  static const _adminFg = Color(0xFF7C3AED);
  static const _sellerBg = Color(0xFFECFDF5);
  static const _sellerFg = Color(0xFF047857);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = user['isActive'] ?? false;
    final role = user['role'] ?? '';
    final fullName = user['fullName'] ?? l10n.unknown;
    final username = user['username'] ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTextStyles.titleMedium().copyWith(
                          color: colors.fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
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
              // Actions
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
