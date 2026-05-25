import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Pinned bottom cart bar for the "continue sale" flow. Surface-white,
/// 2-px top border, soft upward shadow — matches the demo's `.pos-cart`
/// container at the bottom of `#page-pos`.
///
/// Layout: total summary row on top ("Jami summa · 42 000 UZS"), then a
/// brand-orange primary button "To'lash". When the sale is already closed
/// we hide the button (read-only mode) — the totals row still remains so
/// the cashier can see the captured total.
class ContinueSaleBottomBar extends StatelessWidget {
  final double totalAmount;
  final bool cartIsEmpty;
  final bool isClosed;
  final VoidCallback onCheckout;

  const ContinueSaleBottomBar({
    super.key,
    required this.totalAmount,
    required this.cartIsEmpty,
    required this.isClosed,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total summary row — gray label on the left, big bold number on
              // the right. Mirrors the demo's `.cart-summary` line.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalSum,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.formatDecimal(totalAmount)} ${l10n.currencySom}',
                    style: AppTextStyles.titleLarge().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (!isClosed) ...[
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: l10n.makePayment,
                  icon: Icons.credit_card_rounded,
                  onPressed: cartIsEmpty ? null : onCheckout,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
