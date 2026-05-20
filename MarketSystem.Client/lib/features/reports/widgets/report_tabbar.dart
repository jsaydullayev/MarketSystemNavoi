import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Segmented tab control rendered under the Reports AppBar.
///
/// Demo reference: segmented control at the top of `id="page-rpt-hub"` —
/// inputFill pill with a brand-tinted pill indicator behind the active
/// tab and `text` / `textSecondary` foreground.
class ReportTabBar extends StatelessWidget {
  final TabController controller;

  const ReportTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md + 2),
      height: 42,
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: context.colors.brand,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: context.colors.brand.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: context.colors.textSecondary,
        labelStyle: AppTextStyles.labelSmall()
            .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelSmall()
            .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: l10n.daily),
          Tab(text: l10n.monthly),
          Tab(text: l10n.warehouse),
        ],
      ),
    );
  }
}
