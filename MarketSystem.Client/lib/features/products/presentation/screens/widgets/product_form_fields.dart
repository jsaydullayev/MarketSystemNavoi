// Reusable presentation widgets for the product add/edit bottom sheet.
//
// Extracted from `product_form_screen.dart` to keep that file small. These
// are layout-only helpers (section labels, labeled fields, the pricing card,
// tips and the temporary-product toggle) used by `ProductBottomSheet`.

import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_theme_colors.dart';
import '../../../../../design/tokens/app_tokens.dart';
import '../../../../../design/tokens/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';

/// Uppercase section label used to title each form section.
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

/// Label + required/optional marker stacked above a child input. Demo's
/// `.form-label` look.
class LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final String? optional;
  final bool compact;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.optional,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  fontSize: compact ? 10 : 11,
                  letterSpacing: 0.5,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (required)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  '*',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.danger,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (optional case final opt?)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  opt,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: compact ? 10 : 11,
                    letterSpacing: 0,
                    color: context.colors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Brand-light card grouping pricing inputs. Demo's `.price-grid`.
class PriceCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const PriceCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
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
                size: 14,
                color: context.colors.brandDark,
              ),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: context.colors.brandDark,
                  fontWeight: FontWeight.w700,
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
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption().copyWith(
                fontSize: 10,
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

/// Compact toggle for the "vaqtinchalik mahsulot" flag. Brand-light pill
/// with a brand-orange-tinted switch.
class TempToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const TempToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md - 2,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.temporaryProductDesc,
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.text,
              ),
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
