// Dashboard chart + ranked-list surfaces aligned to the new design system
// (lib/design/*).
//
// ChartCard (7-day vertical bar chart) and TopSellersCard ("Eng ko'p
// sotilgan" ranked list) plus the shared TopSellerEntry value object.
// Presentation-only StatelessWidgets — caller supplies the data.

import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_card.dart';

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
    this.deltaCaption = '',
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

  /// Tiny caption rendered under the delta % to say what the percent is
  /// measured against (e.g. "vs last week"). Hidden when empty.
  final String deltaCaption;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  period,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
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
                      heightFactor: isEmpty ? 0.08 : bars[i].clamp(0.05, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isEmpty
                              ? context.colors.borderSoft
                              : (i == bars.length - 1
                                    ? context.colors.brandDark
                                    : context.colors.brand),
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
              // Delta % + a caption saying what it's measured against
              // (week-over-week), so a figure like "↑ 1535%" isn't an
              // unexplained number.
              if (footerDelta.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    if (deltaCaption.isNotEmpty)
                      Text(
                        deltaCaption,
                        style: AppTextStyles.caption().copyWith(
                          color: context.colors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                  ],
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  period,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
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
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(entries[i].emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entries[i].name,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 13,
                        color: context.colors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entries[i].countLabel,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontSize: 13,
                      color: context.colors.text,
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
