// Dashboard widgets aligned to the new design system (lib/design/*).
//
// These widgets render the Owner / Admin / Seller dashboard surfaces
// described in design-demo/index.html (#page-owner-dash and #page-staff-dash):
// greeting card, sales hero card, KPI grid, alert strip, mini chart, and
// top-sellers list. They are presentation-only StatelessWidgets — caller
// supplies the data and tap handlers.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_card.dart';
import '../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// GreetingCard — top-of-screen "Salom, <name>" + role chip + bell/settings.
// ---------------------------------------------------------------------------

class GreetingCard extends StatelessWidget {
  const GreetingCard({
    super.key,
    required this.fullName,
    required this.role,
    required this.dateLabel,
    this.hasNotification = false,
    this.unreadNotifications = 0,
    this.onNotificationTap,
    this.onSettingsTap,
    this.profileImage,
  });

  final String fullName;
  final String role; // 'Owner' | 'Admin' | 'Seller'
  final String dateLabel;
  // Red-dot toggle. Either `hasNotification` (legacy, explicit bool) or
  // `unreadNotifications > 0` produces the badge. Numeric value is kept so
  // future iterations can render a count chip — current design just shows
  // the dot.
  final bool hasNotification;
  final int unreadNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  /// Optional user-uploaded profile image. Accepted forms (same convention as
  /// ProfileImagePicker, so they stay in sync):
  ///   - "http..."         → loaded with [Image.network]
  ///   - "data:image/...,<b64>" or raw base64 longer than 100 chars
  ///       → decoded as bytes and shown with [Image.memory]
  ///   - null / empty / unrecognised → falls back to the first-letter circle.
  final String? profileImage;

  String get _initial =>
      fullName.trim().isEmpty ? 'U' : fullName.trim()[0].toUpperCase();

  /// Render the user's profile image as a 44×44 rounded tile, or a coloured
  /// first-letter tile if no image is available. Kept identical in size to
  /// the original letter tile so the rest of the row layout doesn't shift.
  Widget _buildAvatar() {
    final img = profileImage;
    final hasImage = img != null && img.isNotEmpty;
    final letterTile = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: AppTextStyles.titleMedium()
            .copyWith(color: AppColors.brand, fontWeight: FontWeight.w800),
      ),
    );
    if (!hasImage) return letterTile;

    Widget? imgWidget;
    if (img.startsWith('http')) {
      imgWidget = Image.network(
        img,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => letterTile,
      );
    } else if (img.startsWith('data:image') || img.length > 100) {
      try {
        final b64 = img.contains(',') ? img.split(',').last : img;
        imgWidget = Image.memory(
          base64Decode(b64),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => letterTile,
        );
      } catch (_) {
        imgWidget = null;
      }
    }
    if (imgWidget == null) return letterTile;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: imgWidget,
    );
  }

  ({Color bg, Color fg, String emoji}) _roleStyle() {
    switch (role) {
      case 'Owner':
        return (
          bg: AppColors.accentPurpleLight,
          fg: AppColors.accentPurpleDeep,
          emoji: '\u{1F451}', // crown
        );
      case 'Admin':
        return (
          bg: AppColors.infoLight,
          fg: AppColors.infoDeep,
          emoji: '\u{1F465}', // busts
        );
      case 'Seller':
      default:
        return (
          bg: AppColors.successLight,
          fg: AppColors.successDeep,
          emoji: '\u{1F6D2}', // cart
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = _roleStyle();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.greetingHello}, $fullName',
                  style: AppTextStyles.bodyLarge()
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                    Text(
                      ' · ',
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rs.bg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${rs.emoji} $role',
                        style: AppTextStyles.caption().copyWith(
                          color: rs.fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _IconCircle(
            icon: Icons.notifications_none_rounded,
            badge: hasNotification || unreadNotifications > 0,
            onTap: onNotificationTap,
          ),
          const SizedBox(width: AppSpacing.md),
          _IconCircle(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    this.badge = false,
    this.onTap,
  });

  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: AppColors.text),
          ),
          if (badge)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SalesHeroCard — dark gradient "Bugungi sotuv" card with 3-stat footer.
// ---------------------------------------------------------------------------

class SalesHeroStat {
  const SalesHeroStat({required this.value, required this.label});
  final String value;
  final String label;
}

class SalesHeroCard extends StatelessWidget {
  const SalesHeroCard({
    super.key,
    required this.amount,
    required this.label,
    required this.stats,
    this.deltaText,
    this.deltaIsPositive = true,
  });

  final String amount;
  final String label;

  /// Optional comparison line ("15% kechagidan ko'p"). When null/empty, the
  /// row is hidden entirely. Previously this was required and callers
  /// passed a plain label string ("Bugungi sotuv") here, which combined
  /// with the hardcoded "↑" arrow rendered "↑ Bugungi sotuv" — a green
  /// up-arrow next to text that wasn't actually a growth indicator.
  final String? deltaText;

  /// Controls the arrow + colour for the optional delta line. Ignored when
  /// deltaText is null/empty.
  final bool deltaIsPositive;
  final List<SalesHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Same dark-blue gradient as the demo's `.today-card`, sourced
          // from the dark-theme token family so the dashboard hero
          // stays in step with the rest of the palette.
          colors: [AppColors.darkBg, AppColors.darkSurface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTextStyles.displayLarge().copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          // Optional delta line. Hidden when deltaText is null/empty so
          // the card doesn't render an orphan green up-arrow on its own.
          if (deltaText != null && deltaText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${deltaIsPositive ? '↑' : '↓'} $deltaText',
              style: AppTextStyles.bodySmall().copyWith(
                color: deltaIsPositive
                    ? AppColors.success
                    : AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (final s in stats)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          s.value,
                          style: AppTextStyles.titleMedium().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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

  ({Color bg, Color fg}) _toneColors() {
    switch (tone) {
      case KpiTone.green:
        return (bg: AppColors.successLight, fg: AppColors.success);
      case KpiTone.purple:
        return (bg: AppColors.accentPurpleLight, fg: AppColors.accentPurple);
      case KpiTone.blue:
        return (bg: AppColors.infoLight, fg: AppColors.infoDeep);
      case KpiTone.orange:
        return (bg: AppColors.brandLight, fg: AppColors.brand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _toneColors();
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
              color: AppColors.textSecondary,
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
                    style: AppTextStyles.bodySmall()
                        .copyWith(color: c.desc, fontSize: 12),
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
// ChartCard — 7-day vertical bar chart with title, period chip, footer.
// ---------------------------------------------------------------------------

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.period,
    required this.bars, // values 0..1 — last bar highlighted
    required this.footerValue,
    required this.footerDelta,
    this.deltaIsPositive = true,
    this.isEmpty = false,
  });

  final String title;
  final String period;
  final List<double> bars;
  final String footerValue;
  /// Already-formatted delta string (e.g. "5%"). The card adds the sign
  /// arrow ("↑" or "↓") based on [deltaIsPositive]; do NOT include an arrow
  /// in [footerDelta] yourself or you'll get a double arrow.
  final String footerDelta;

  /// Tints the delta arrow green (true) or red (false). Ignored when
  /// footerDelta is empty.
  final bool deltaIsPositive;

  /// When true, the bars are dimmed (placeholder mode) so the card doesn't
  /// look like it shows real data of value zero. Use for the "no data yet"
  /// state without hiding the chart entirely.
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  period,
                  style: AppTextStyles.caption()
                      .copyWith(fontSize: 10, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: FractionallySizedBox(
                      // Empty-state placeholder bars are short (just enough
                      // to hint at the axis) so the card isn't visually
                      // dominated by full-height orange columns when there's
                      // no real data behind them.
                      heightFactor: isEmpty
                          ? 0.08
                          : bars[i].clamp(0.05, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isEmpty
                              ? AppColors.borderSoft
                              : (i == bars.length - 1
                                  ? AppColors.brandDark
                                  : AppColors.brand),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i != bars.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footerValue,
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
              // Only render the arrow + percent when we actually have one.
              // Previously this always showed "↑" even with an empty delta,
              // producing an orphan green up-arrow next to "— UZS" — see the
              // empty-state screenshots from 2026-05-19.
              if (footerDelta.isNotEmpty)
                Text(
                  '${deltaIsPositive ? '↑' : '↓'} $footerDelta',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: deltaIsPositive
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TopSellersCard — "Eng ko'p sotilgan" ranked list with emoji + count.
// ---------------------------------------------------------------------------

class TopSellerEntry {
  const TopSellerEntry({
    required this.emoji,
    required this.name,
    required this.countLabel,
  });

  final String emoji;
  final String name;
  final String countLabel; // e.g. "248 dona"
}

class TopSellersCard extends StatelessWidget {
  const TopSellersCard({
    super.key,
    required this.title,
    required this.period,
    required this.entries,
  });

  final String title;
  final String period;
  final List<TopSellerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  period,
                  style: AppTextStyles.caption()
                      .copyWith(fontSize: 10, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(entries[i].emoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entries[i].name,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entries[i].countLabel,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontSize: 13,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
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
              color: AppColors.textSecondary,
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
                  color: AppColors.brand,
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand, AppColors.brandDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
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

// ---------------------------------------------------------------------------
// SellerStatsRow — three compact stat tiles for the Seller dashboard.
// ---------------------------------------------------------------------------

class SellerStatsRow extends StatelessWidget {
  const SellerStatsRow({super.key, required this.stats});

  final List<SalesHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[i].value,
                    style: AppTextStyles.titleMedium()
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 10,
                      letterSpacing: 0.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (i != stats.length - 1)
              Container(
                width: 1,
                height: 30,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}
