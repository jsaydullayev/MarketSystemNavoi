import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';

import '../../../../l10n/app_localizations.dart';

class AdminProductsEmptyState extends StatelessWidget {
  final bool isSearching;
  final AppLocalizations l10n;
  const AdminProductsEmptyState({
    super.key,
    required this.isSearching,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isSearching ? l10n.productNotFound : l10n.noProducts,
            style: AppTextStyles.titleMedium().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProductsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const AdminProductsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: l10n.retry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
