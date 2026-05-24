import 'package:flutter/material.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import 'sale_pos_widgets.dart';

/// Draggable bottom sheet that shows the current cart items.
///
/// [cartItems] is the live list (passed by reference) so mutations made
/// via the callbacks are reflected on every [setSheet] rebuild.
/// Total is recomputed from the list on each rebuild so it stays in sync.
void showCartSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> cartItems,
  required void Function(int index, double newQty) onUpdateQuantity,
  required void Function(int index, Map<String, dynamic> item)
      onEditItemPrice,
  required void Function(int index) onRemoveFromCart,
  required VoidCallback onCheckout,
}) {
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final totalAmount = cartItems.fold<double>(
            0.0,
            (sum, item) =>
                sum +
                (item['quantity'] as num).toDouble() *
                    (item['salePrice'] as num).toDouble(),
          );
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          Text(
                            l10n.cartTitle,
                            style: AppTextStyles.titleMedium(),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.brandLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(
                              '${cartItems.length}',
                              style: AppTextStyles.labelSmall().copyWith(
                                color: context.colors.brand,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close,
                                color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: cartItems.isEmpty
                          ? Center(
                              child: Text(
                                l10n.cartEmptyWarning,
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: context.colors.textMuted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                  16, 4, 16, 16),
                              itemCount: cartItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (_, index) =>
                                  _buildItem(
                                context,
                                ctx,
                                index,
                                cartItems[index],
                                l10n,
                                onUpdateQuantity: onUpdateQuantity,
                                onEditItemPrice: onEditItemPrice,
                                onRemoveFromCart: onRemoveFromCart,
                                refreshSheet: () => setSheet(() {}),
                              ),
                            ),
                    ),
                    _buildFooter(
                      context,
                      l10n,
                      totalAmount: totalAmount,
                      onCheckout: () {
                        Navigator.pop(ctx);
                        onCheckout();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildItem(
  BuildContext context,
  BuildContext sheetCtx,
  int index,
  Map<String, dynamic> item,
  AppLocalizations l10n, {
  required void Function(int, double) onUpdateQuantity,
  required void Function(int, Map<String, dynamic>) onEditItemPrice,
  required void Function(int) onRemoveFromCart,
  required VoidCallback refreshSheet,
}) {
  final isExternal = item['isExternal'] ?? false;
  final qty = (item['quantity'] as num).toDouble();
  final price = (item['salePrice'] as num).toDouble();
  final subtotal = qty * price;

  return Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: isExternal
          ? context.colors.brandLight
          : context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color:
            isExternal ? AppColors.brandTint : context.colors.border,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isExternal
                    ? AppColors.brandTint
                    : context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isExternal
                    ? Icons.add_business_rounded
                    : Icons.inventory_2_rounded,
                color: isExternal
                    ? context.colors.brand
                    : context.colors.textSecondary,
                size: 18,
              ),
            ),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? '',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: isExternal
                          ? context.colors.brandDark
                          : context.colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.height,
                  Text(
                    '${qty % 1 == 0 ? qty.toInt() : qty} × ${NumberFormatter.format(price)}',
                    style: AppTextStyles.caption().copyWith(
                      letterSpacing: 0,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              NumberFormatter.format(subtotal),
              style: AppTextStyles.bodySmall().copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: context.colors.brand,
              ),
            ),
          ],
        ),
        10.height,
        Row(
          children: [
            CartSheetQtyBtn(
              icon: Icons.remove_rounded,
              onTap: () {
                onUpdateQuantity(index, qty - 1);
                refreshSheet();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
            ),
            CartSheetQtyBtn(
              icon: Icons.add_rounded,
              onTap: () {
                onUpdateQuantity(index, qty + 1);
                refreshSheet();
              },
            ),
            const Spacer(),
            CartSheetActionBtn(
              icon: Icons.edit_rounded,
              color: context.colors.brand,
              onTap: () {
                Navigator.pop(sheetCtx);
                onEditItemPrice(index, item);
              },
            ),
            8.width,
            CartSheetActionBtn(
              icon: Icons.delete_outline_rounded,
              color: AppColors.danger,
              onTap: () {
                onRemoveFromCart(index);
                refreshSheet();
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildFooter(
  BuildContext context,
  AppLocalizations l10n, {
  required double totalAmount,
  required VoidCallback onCheckout,
}) {
  return Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border:
          Border(top: BorderSide(color: context.colors.borderSoft)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg + 2),
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandTint),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalSum,
                  style: AppTextStyles.bodyMedium()
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  NumberFormatter.format(totalAmount),
                  style: AppTextStyles.titleLarge().copyWith(
                    color: context.colors.brand,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: l10n.processReturn
                .replaceAll(l10n.returnText, l10n.saleText),
            icon: Icons.credit_card_rounded,
            onPressed: onCheckout,
          ),
        ],
      ),
    ),
  );
}
