import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Empty state shown when a day has no sales line items.
///
/// `isDark` is preserved on the constructor for source compatibility and
/// ignored — the migrated design is light-only.
class EmptyItems extends StatelessWidget {
  final bool isDark;

  const EmptyItems({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.noSalesToday,
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
