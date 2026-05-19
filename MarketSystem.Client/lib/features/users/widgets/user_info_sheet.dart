import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// User detail bottom sheet matching the staff-detail hero card from
/// `id="page-staff-detail"`: 72x72 avatar tile with role-tinted background,
/// full name + `@username`, role chip with semantic color + active/inactive
/// status, info rows, and a primary "Close" button.
class UserInfoSheet extends StatelessWidget {
  final dynamic user;
  const UserInfoSheet({super.key, required this.user});

  static void show(BuildContext context, {required dynamic user}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UserInfoSheet(user: user),
    );
  }

  // Role chip colors (mirror UserCard so chips read consistently).
  static const _adminBg = Color(0xFFF3E8FF);
  static const _adminFg = Color(0xFF7C3AED);
  static const _sellerBg = Color(0xFFECFDF5);
  static const _sellerFg = Color(0xFF047857);

  ({Color bg, Color fg}) _roleColors(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (bg: AppColors.brandLight, fg: AppColors.brandDark);
      case 'admin':
        return (bg: _adminBg, fg: _adminFg);
      case 'seller':
        return (bg: _sellerBg, fg: _sellerFg);
      default:
        return (bg: AppColors.inputFill, fg: AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = user['isActive'] ?? false;
    final role = user['role'] ?? '';
    final fullName = user['fullName'] ?? l10n.unknown;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final colors = _roleColors(role);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.lg,
        AppSpacing.xl2,
        AppSpacing.xl4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2 + 10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl3),

          // Hero avatar (72x72 tile, role-tinted)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(AppRadius.xl + 4),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTextStyles.displayMedium().copyWith(
                  color: colors.fg,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Full name
          Text(
            fullName,
            style: AppTextStyles.titleLarge().copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),

          // @username
          Text(
            '@${user['username'] ?? ''}',
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Info rows: role + status
          _InfoTile(
            icon: Icons.badge_rounded,
            label: l10n.role,
            value: role,
            valueColor: colors.fg,
          ),
          _InfoTile(
            icon: Icons.circle,
            label: l10n.status,
            value: isActive ? l10n.active : l10n.inactive,
            valueColor: isActive ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.md),

          AppPrimaryButton(
            label: l10n.closed,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md + 2),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
