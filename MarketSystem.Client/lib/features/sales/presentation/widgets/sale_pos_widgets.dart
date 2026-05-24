import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';

/// Round back button for the POS header — 36×36, grey-fill.
class PosBackButton extends StatelessWidget {
  const PosBackButton({super.key, required this.onTap});

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

/// Customer chip — pill button shown in the POS header.
class CustomerChip extends StatelessWidget {
  const CustomerChip({
    super.key,
    required this.customer,
    required this.fallbackLabel,
    required this.onTap,
  });

  final Map<String, dynamic>? customer;
  final String fallbackLabel;
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 6),
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
                  PosInitialAvatar(name: name)
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
                      fontWeight: FontWeight.w600,
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

/// 18×18 orange-tinted circle showing the customer's first initial.
class PosInitialAvatar extends StatelessWidget {
  const PosInitialAvatar({super.key, required this.name});

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

/// Tappable summary row above the pay button.
class CartSummaryRow extends StatelessWidget {
  const CartSummaryRow({
    super.key,
    required this.itemCount,
    required this.itemNames,
    required this.total,
    required this.onTap,
    required this.productsSuffix,
  });

  final int itemCount;
  final String itemNames;
  final double total;
  final VoidCallback onTap;
  final String productsSuffix;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: '$itemCount $productsSuffix',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (itemNames.isNotEmpty)
                      TextSpan(text: ' · $itemNames'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              NumberFormatter.format(total),
              style: AppTextStyles.titleLarge().copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.text,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 32×32 minus/plus quantity button used inside cart sheet rows.
class CartSheetQtyBtn extends StatelessWidget {
  const CartSheetQtyBtn({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.colors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: context.colors.brand),
      ),
    );
  }
}

/// 32×32 action button (edit / delete) for cart sheet rows.
class CartSheetActionBtn extends StatelessWidget {
  const CartSheetActionBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
