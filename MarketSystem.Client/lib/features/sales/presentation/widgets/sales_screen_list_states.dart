import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class SalesLoadMoreIndicator extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadMore;

  const SalesLoadMoreIndicator({
    super.key,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colors.brand,
                ),
              )
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: Icon(Icons.expand_more, color: context.colors.brand),
                label: Text(
                  'Yana yuklash',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.brand,
                  ),
                ),
              ),
      ),
    );
  }
}

class SalesEmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const SalesEmptyState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: context.colors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.noData,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
