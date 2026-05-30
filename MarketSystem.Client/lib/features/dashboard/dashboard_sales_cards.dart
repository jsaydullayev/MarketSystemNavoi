// Dashboard sales/stat surfaces aligned to the new design system (lib/design/*).
//
// SalesHeroCard (dark gradient "Bugungi sotuv" hero) plus SellerStatsRow
// (three compact stat tiles for the Seller dashboard) and the shared
// SalesHeroStat value object. Presentation-only StatelessWidgets — caller
// supplies the data.

import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_card.dart';

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
          if (deltaText case final delta? when delta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${deltaIsPositive ? '↑' : '↓'} $delta',
              style: AppTextStyles.bodySmall().copyWith(
                color: deltaIsPositive ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
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
                    style: AppTextStyles.titleMedium().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 10,
                      letterSpacing: 0.3,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (i != stats.length - 1)
              Container(width: 1, height: 30, color: context.colors.border),
          ],
        ],
      ),
    );
  }
}
