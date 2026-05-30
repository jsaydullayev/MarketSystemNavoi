// Shared leaf widgets for SuperAdminConsoleScreen's two tabs.
// Grouped in one file because they are each <40 lines and only used within
// the superadmin console; splitting them further would create more navigation
// friction than benefit.

import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Stat card for the requests stats grid (Pending / Approved / Rejected).
class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final String value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Small pill-shaped refresh button shown next to section headers.
class RefreshChip extends StatelessWidget {
  const RefreshChip({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh, size: 14),
      label: Text(l10n.refresh),
      style: TextButton.styleFrom(
        foregroundColor: context.colors.textSecondary,
        textStyle: AppTextStyles.bodySmall().copyWith(fontSize: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: context.colors.border),
        ),
      ),
    );
  }
}

/// Centred empty-state placeholder with an icon and a single line of text.
class ConsoleEmptyState extends StatelessWidget {
  const ConsoleEmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 32, color: context.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(text, style: AppTextStyles.bodyMedium()),
          ],
        ),
      ),
    );
  }
}

/// Full-screen error state with a retry button.
class ConsoleErrorState extends StatelessWidget {
  const ConsoleErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = error == 'console_not_configured'
        ? l10n.superAdminConsoleNotConfigured
        : l10n.superAdminLoadFailed;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 220,
              child: AppPrimaryButton(
                onPressed: onRetry,
                icon: Icons.refresh,
                label: l10n.retry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab label with an icon and a count badge.
class TabLabelBadge extends StatelessWidget {
  const TabLabelBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.brand
        : context.colors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: selected ? context.colors.brand : context.colors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? context.colors.onBrand : context.colors.brand,
            ),
          ),
        ),
      ],
    );
  }
}
