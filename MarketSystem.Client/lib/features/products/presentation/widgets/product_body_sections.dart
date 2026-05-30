// Products body — chrome sections.
//
// The sticky search bar plus the empty-state and error-state views.
// Extracted from `product_body.dart` as part of a code-move refactor.

import 'package:flutter/material.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Sticky search input below the screen AppBar. Light gray fill, 14px radius,
/// search icon prefix — matches `.search-input-big` in the demo.
class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.search,
          hintStyle: AppTextStyles.bodyMedium().copyWith(
            color: context.colors.textMuted,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.colors.textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: context.colors.inputFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg + 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: context.colors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class ProductEmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const ProductEmptyView({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: context.colors.textMuted,
          ),
          16.height,
          Text(
            l10n.noProducts,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final AppLocalizations l10n;
  const ProductErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.danger,
          ),
          16.height,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium().copyWith(color: AppColors.danger),
          ),
          24.height,
          SizedBox(
            width: 200,
            child: AppPrimaryButton(label: l10n.loading, onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}
