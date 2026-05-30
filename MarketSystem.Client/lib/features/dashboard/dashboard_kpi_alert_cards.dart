// Dashboard KPI + alert surfaces aligned to the new design system
// (lib/design/*).
//
// KpiCard (small mini-stat card), AlertCard (colored info strip) and
// PendingSaleCard (amber strip wrapping an AlertCard). Presentation-only
// StatelessWidgets — caller supplies the data and tap handlers.

import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_card.dart';

// ---------------------------------------------------------------------------
// KpiCard — small mini-stat card: colored icon tile, big value, small label.
// ---------------------------------------------------------------------------

enum KpiTone { green, purple, blue, orange }

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.tone = KpiTone.orange,
    this.onTap,
  });

  final String emoji;
  final String value;
  final String label;
  final KpiTone tone;
  final VoidCallback? onTap;

  ({Color bg, Color fg}) _toneColors(BuildContext context) {
    switch (tone) {
      case KpiTone.green:
        return (bg: AppColors.successLight, fg: AppColors.success);
      case KpiTone.purple:
        return (bg: AppColors.accentPurpleLight, fg: AppColors.accentPurple);
      case KpiTone.blue:
        return (bg: AppColors.infoLight, fg: AppColors.infoDeep);
      case KpiTone.orange:
        return (bg: context.colors.brandLight, fg: context.colors.brand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _toneColors(context);
    final card = AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.fg,
            ),
            // Some KPI values are now strings (e.g. top-product name) instead
            // of numbers — long product names need to truncate rather than
            // overflow the card.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 11,
              color: context.colors.textSecondary,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: card,
    );
  }
}

// ---------------------------------------------------------------------------
// AlertCard — colored info strip (danger / warning) with title + desc + chevron.
// ---------------------------------------------------------------------------

enum AlertTone { danger, warning, success }

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    this.tone = AlertTone.warning,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final AlertTone tone;
  final VoidCallback? onTap;

  ({Color bg, Color border, Color title, Color desc}) _colors() {
    switch (tone) {
      case AlertTone.danger:
        return (
          bg: AppColors.dangerLight,
          border: AppColors.danger,
          title: AppColors.dangerDeep,
          desc: AppColors.dangerStrong,
        );
      case AlertTone.warning:
        return (
          bg: AppColors.warningLight,
          border: AppColors.warning,
          title: AppColors.warningDeep,
          desc: AppColors.warningDark,
        );
      case AlertTone.success:
        return (
          bg: AppColors.successLight,
          border: AppColors.success,
          title: AppColors.successDeep,
          desc: AppColors.successDeep,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: c.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge().copyWith(
                      color: c.title,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: c.desc,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.title, size: 22),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PendingSaleCard — amber strip showing an open / suspended sale.
// ---------------------------------------------------------------------------

class PendingSaleCard extends StatelessWidget {
  const PendingSaleCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AlertCard(
      emoji: '⏳',
      title: title,
      description: subtitle,
      tone: AlertTone.warning,
      onTap: onTap,
    );
  }
}
