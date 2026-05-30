// Presentational section widgets for the Admin Product form.
//
// Extracted from `admin_product_form_screen.dart` as a pure code-move:
// the hero strip, section/field labels, price card + tip, the quantity
// notice, and the temporary-product toggle.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

import '../../../l10n/app_localizations.dart';

/// Top-of-form hero with the brand icon tile + helper sub-label.
class HeroStrip extends StatelessWidget {
  final bool isEditing;
  final AppLocalizations l10n;
  const HeroStrip({super.key, required this.isEditing, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandTint, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brand,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? l10n.adminEditProductTitle
                      : l10n.adminNewProductTitle,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.brandDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.adminCanEditPriceAndSettings,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.brandDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Small label rendered above each non-AppTextInput control.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// Brand-light card grouping price inputs. Demo's `.price-grid`.
class PriceCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const PriceCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandTint, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 16,
                color: context.colors.brandDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: context.colors.brandDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

/// Soft yellow hint shown under the "minimum sotish narxi" input.
class PriceTip extends StatelessWidget {
  final String text;
  const PriceTip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption().copyWith(
                fontSize: 11,
                letterSpacing: 0,
                color: context.colors.text,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityNotice extends StatelessWidget {
  final bool isEditing;
  final dynamic product;
  final AppLocalizations l10n;
  const QuantityNotice({
    super.key,
    required this.isEditing,
    required this.product,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isEditing
                  ? l10n.productQuantityImmutable(
                      (product['quantity'] as num?)?.toDouble() ?? 0.0,
                    )
                  : l10n.productCreatedWithZeroInfo,
              style: AppTextStyles.caption().copyWith(
                fontSize: 11,
                letterSpacing: 0,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TempToggle extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const TempToggle({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeThumbColor: context.colors.brand,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
