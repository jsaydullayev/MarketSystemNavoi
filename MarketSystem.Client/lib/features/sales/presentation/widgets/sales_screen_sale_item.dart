import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../design/widgets/tappable.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sale_entity.dart';
import 'sales_screen_status_helpers.dart';

// PERF: DateFormat is stateless for formatting, so share one instance instead
// of constructing two per row on every paginated-list build/scroll frame.
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _dayFormat = DateFormat('dd MMM');

class SalesSaleItem extends StatelessWidget {
  final SaleEntity sale;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const SalesSaleItem({
    super.key,
    required this.sale,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = sale.getStatusText().toLowerCase();
    final statusColor = SalesStatusHelpers.getStatusColor(context, statusText);
    final dateStr = _timeFormat.format(sale.createdAt);
    final dayStr = _dayFormat.format(sale.createdAt);

    // Pick a payment icon by status: paid=cash, closed=card, debt=notebook,
    // draft=hourglass. Matches the demo's `.pay-ic.cash/.card/.debt` palette.
    // Colours come from the design tokens — no raw hex.
    final (IconData icon, Color tone) = switch (statusText) {
      'paid' => (Icons.payments_rounded, AppColors.success),
      'closed' => (Icons.credit_card_rounded, AppColors.darkPrimary),
      'debt' => (Icons.assignment_outlined, AppColors.danger),
      'draft' => (Icons.hourglass_bottom_rounded, AppColors.warning),
      _ => (Icons.receipt_long_rounded, context.colors.textSecondary),
    };

    final isCancelled = statusText == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Tappable(
        onTap: onTap,
        child: Opacity(
          opacity: isCancelled ? 0.65 : 1,
          // AppCard gives us the demo's 1px border + 14-radius + white
          // surface, matching `.sale-row` in design-demo/index.html.
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sale.customerName ?? l10n.noCustomer,
                              style: AppTextStyles.labelLarge().copyWith(
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCancelled) ...[
                            const SizedBox(width: AppSpacing.md),
                            // "Qaytarildi" badge mirrors `.badge-refund`
                            // in the demo's refunded sale rows.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                l10n.returnAction.toUpperCase(),
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.danger,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: AppSpacing.md),
                          Text(dateStr, style: AppTextStyles.bodySmall()),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$dayStr · ${sale.sellerName ?? ''}',
                              style: AppTextStyles.bodySmall().copyWith(
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            NumberFormatter.format(sale.totalAmount),
                            style: AppTextStyles.labelLarge().copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              // Refunded / cancelled rows: strike-through
                              // amount and recolour to danger, like
                              // `.sale-row.refunded .total` in the demo.
                              color: isCancelled
                                  ? AppColors.danger
                                  : context.colors.text,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              SalesStatusHelpers.getStatusName(
                                sale.getStatusText(),
                                l10n,
                              ).toUpperCase(),
                              style: AppTextStyles.caption().copyWith(
                                color: statusColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
