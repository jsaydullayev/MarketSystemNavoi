// lib/features/users/widgets/role_selector.dart
//
// Role picker cards shared by the add-staff sheet and the Owner's change-role
// sheet, mapped to the demo `.role-picker` block.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

// Role chip colors mirror the staff list/detail so the picker chip reads
// consistently across the feature.
const _adminBg = AppColors.roleAdminBg;
const _adminFg = AppColors.roleAdminFg;
const _sellerBg = AppColors.roleSellerBg;
const _sellerFg = AppColors.roleSellerFg;

/// 2-card (Admin + Seller, plus Owner if role-gated) role picker: each card is
/// colour-tinted with the role's semantic palette and shows an icon + role name.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  final List<String> roles;
  final String selected;
  final ValueChanged<String> onChanged;

  ({Color bg, Color fg, IconData icon, String desc}) _roleSpec(
    BuildContext context,
    AppLocalizations l10n,
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (
          bg: context.colors.brandLight,
          fg: context.colors.brandDark,
          icon: Icons.workspace_premium_rounded,
          desc: l10n.roleOwnerDesc,
        );
      case 'admin':
        return (
          bg: _adminBg,
          fg: _adminFg,
          icon: Icons.admin_panel_settings_rounded,
          desc: l10n.roleAdminDesc,
        );
      case 'seller':
      default:
        return (
          bg: _sellerBg,
          fg: _sellerFg,
          icon: Icons.storefront_rounded,
          desc: l10n.roleSellerDesc,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.role.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: roles.map((r) {
            final sel = selected == r;
            final spec = _roleSpec(context, l10n, r);
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: r != roles.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? spec.bg : context.colors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: sel ? spec.fg : context.colors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        spec.icon,
                        color: sel ? spec.fg : context.colors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        r,
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: sel ? spec.fg : context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.desc,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 10,
                          color: sel
                              ? spec.fg.withValues(alpha: 0.8)
                              : context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
