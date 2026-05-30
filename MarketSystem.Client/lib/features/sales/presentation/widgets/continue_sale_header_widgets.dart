import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Round 36×36 back button — matches the demo's `.pos-back` element.
class ContinueSalePosBackButton extends StatelessWidget {
  const ContinueSalePosBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: context.colors.text,
          ),
        ),
      ),
    );
  }
}

/// Customer chip — pill on the right of the header. Brand-tinted when a
/// customer is selected, neutral grey otherwise. Closed sales disable
/// tapping (the API rejects customer updates on closed sales).
class ContinueSaleCustomerChip extends StatelessWidget {
  const ContinueSaleCustomerChip({
    super.key,
    required this.customer,
    required this.fallbackLabel,
    required this.enabled,
    required this.onTap,
  });

  final Map<String, dynamic>? customer;
  final String fallbackLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCustomer = customer != null;
    final name = hasCustomer
        ? (customer!['fullName']?.toString() ?? fallbackLabel)
        : fallbackLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: hasCustomer
                  ? context.colors.brandLight
                  : context.colors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCustomer)
                  _InitialAvatar(name: name)
                else
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: context.colors.textSecondary,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall().copyWith(
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                      color: hasCustomer
                          ? context.colors.brand
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 18×18 orange-filled circle with the customer's first initial. Mirrors
/// the avatar used in the `NewSaleScreen` header for visual continuity.
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.brand,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: AppTextStyles.caption().copyWith(
          fontSize: 10,
          color: Colors.white,
          letterSpacing: 0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Gray-fill search input with brand-orange focus. Replaces the inline
/// dark-mode-aware TextField from the legacy implementation.
class ContinueSaleSearchInput extends StatelessWidget {
  const ContinueSaleSearchInput({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onClear,
  });

  final TextEditingController controller;
  final AppLocalizations l10n;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: l10n.searchProduct,
        hintStyle: AppTextStyles.bodyMedium().copyWith(
          color: context.colors.textMuted,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: context.colors.textMuted,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                color: context.colors.textSecondary,
                onPressed: () {
                  controller.clear();
                  onClear();
                },
              )
            : null,
        filled: true,
        fillColor: context.colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          borderSide: BorderSide(color: context.colors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}

/// Empty-state shown when the product search yields no results.
class ContinueSaleEmptyState extends StatelessWidget {
  const ContinueSaleEmptyState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: context.colors.border,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.productsNotFound,
            style: AppTextStyles.bodySmall().copyWith(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 44×44 brand-orange tile that opens the external-product sheet. Replaces
/// the legacy gradient + custom shadow with the design-system brand color.
class ContinueSaleExternalProductButton extends StatelessWidget {
  const ContinueSaleExternalProductButton({
    super.key,
    required this.tooltip,
    required this.onTap,
  });

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brand,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              boxShadow: [
                BoxShadow(
                  color: context.colors.brand.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
