// Dashboard section-level surfaces aligned to the new design system
// (lib/design/*).
//
// SectionHeader ("STATISTIKA" label + optional trailing action link) and
// SellerHeroCta (big "Yangi sotuv" call-to-action card for Seller/Admin
// roles). Presentation-only StatelessWidgets — caller supplies the data and
// tap handlers.

import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';

// ---------------------------------------------------------------------------
// SectionHeader — "STATISTIKA" label + optional trailing action link.
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: context.colors.textSecondary,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              child: Text(
                '$actionLabel →',
                style: AppTextStyles.bodySmall().copyWith(
                  color: context.colors.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SellerHeroCta — big "Yangi sotuv" call-to-action card for Seller/Admin role.
// ---------------------------------------------------------------------------

class SellerHeroCta extends StatelessWidget {
  const SellerHeroCta({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.colors.brand, context.colors.brandDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: context.colors.brand.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.titleLarge().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium().copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
