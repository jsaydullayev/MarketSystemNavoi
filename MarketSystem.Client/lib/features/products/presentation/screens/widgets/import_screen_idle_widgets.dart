import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_theme_colors.dart';
import '../../../../../design/tokens/app_tokens.dart';
import '../../../../../design/tokens/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.colors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.brand, size: 22),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textSecondary,
              )),
            ],
          ),
        ),
        action,
      ],
    ),
  );
}

class ColumnGuide extends StatelessWidget {
  const ColumnGuide(this.l10n, {super.key});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cols = [
      ('A', l10n.productName, true),
      ('B', l10n.salePrice, true),
      ('C', l10n.minPrice, false),
      ('D', l10n.category, false),
      ('E', l10n.importUnitHint, false),
      ('F', l10n.minThreshold, false),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importColumnGuide,
            style: AppTextStyles.bodyMedium()
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          ...cols.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(c.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    )),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(c.$2,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.text,
                  )),
              if (c.$3) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.importRequired,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ]),
          )),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(message,
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.danger)),
        ),
      ],
    ),
  );
}
