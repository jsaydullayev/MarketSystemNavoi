import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Shown when a report tab has no data loaded yet (e.g. API failure).
class EmptyReport extends StatelessWidget {
  const EmptyReport({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.noReports,
            style: AppTextStyles.bodyLarge().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
