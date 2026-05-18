import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Horizontal cart-item card used in the strip above the product grid on
/// the "continue sale" screen. Mirrors the demo's `.cart-item` row in
/// `#page-pos-cart` but laid out vertically inside a 155-px-wide tile so
/// several items can scroll horizontally without dominating the screen.
///
/// Closed sales (status == 'Closed') hide the qty stepper + remove icon
/// and show a return button instead — Admin/Owner only, since the API
/// `/Sales/{id}/return-item` is gated by the `AdminOrOwner` policy.
class ContinueSaleCartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isClosed;
  final VoidCallback onEditPrice;
  final VoidCallback onReturn;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  /// Mirrors the backend's `[Authorize(Policy = "AdminOrOwner")]` on
  /// /Sales/{id}/return-item. Hiding the button for Sellers prevents
  /// them from tapping it and seeing a 403 they can't act on.
  final bool canReturn;

  const ContinueSaleCartItem({
    super.key,
    required this.item,
    required this.isClosed,
    required this.onEditPrice,
    required this.onReturn,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
    this.canReturn = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = price * qty;

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name + remove (×) — close button sits flush right.
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['productName'] ?? '',
                    style: AppTextStyles.bodySmall().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isClosed)
                  InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // qty × price meta line — muted caption.
            Text(
              '${qty % 1 == 0 ? qty.toInt() : qty} × ${NumberFormatter.format(price)}',
              style: AppTextStyles.caption().copyWith(
                fontSize: 10,
                letterSpacing: 0,
                color: AppColors.textMuted,
              ),
            ),

            // Subtotal + edit-price chip.
            Row(
              children: [
                Expanded(
                  child: Text(
                    NumberFormatter.formatDecimal(itemTotal),
                    style: AppTextStyles.labelLarge().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isClosed)
                  InkWell(
                    onTap: onEditPrice,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 11,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Closed → return button (Admin/Owner only). Otherwise → qty
            // stepper. Mirrors the demo's `.cart-stepper` (− N +).
            if (isClosed && canReturn)
              InkWell(
                onTap: onReturn,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_return_rounded,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.returnAction,
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isClosed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QtyButton(icon: Icons.remove_rounded, onTap: onDecrement),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      qty % 1 == 0 ? '${qty.toInt()}' : '$qty',
                      style: AppTextStyles.labelLarge().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  _QtyButton(icon: Icons.add_rounded, onTap: onIncrement),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Small 24×24 brand-tinted button used in the qty stepper above. Matches
/// the demo's `.cart-stepper button` element.
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 13, color: AppColors.brand),
      ),
    );
  }
}
