import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/zakup_receipt_entity.dart';

/// One goods-receipt (priyomka) in the history list — an expandable card with a
/// supplier/invoice header, payment status, totals (hidden for Sellers), the
/// product lines, and optional pay / delete actions.
class ZakupReceiptCard extends StatefulWidget {
  final ZakupReceiptEntity receipt;
  final bool canViewCost;
  final VoidCallback? onDelete;
  final VoidCallback? onPay;

  const ZakupReceiptCard({
    super.key,
    required this.receipt,
    required this.canViewCost,
    this.onDelete,
    this.onPay,
  });

  @override
  State<ZakupReceiptCard> createState() => _ZakupReceiptCardState();
}

class _ZakupReceiptCardState extends State<ZakupReceiptCard> {
  bool _expanded = false;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  (String, Color) _status(AppLocalizations l10n) {
    final r = widget.receipt;
    if (r.isPaid) return (l10n.statusPaid, AppColors.success);
    if (r.isPartial) return (l10n.statusPartial, AppColors.warning);
    return (l10n.statusUnpaid, AppColors.danger);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.receipt;
    final (statusLabel, statusColor) = _status(l10n);
    final showMoney = widget.canViewCost;
    final hasDebt = showMoney && !r.isPaid && r.outstandingAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          // Header (tap to expand)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: context.colors.brand,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.supplierName ?? l10n.noSupplierSelected,
                              style: AppTextStyles.bodyLarge().copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                l10n.itemsCountLabel(r.itemCount),
                                if (r.invoiceNumber != null &&
                                    r.invoiceNumber!.isNotEmpty)
                                  '№ ${r.invoiceNumber}',
                              ].join('  •  '),
                              style: AppTextStyles.caption().copyWith(
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showMoney)
                            Text(
                              NumberFormatter.format(r.totalAmount),
                              style: AppTextStyles.bodyLarge().copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: context.colors.text,
                              ),
                            ),
                          const SizedBox(height: 4),
                          if (showMoney)
                            _StatusChip(label: statusLabel, color: statusColor),
                        ],
                      ),
                      if (widget.onDelete != null ||
                          (widget.onPay != null && hasDebt))
                        _ActionsMenu(
                          canPay: widget.onPay != null && hasDebt,
                          canDelete: widget.onDelete != null,
                          onPay: widget.onPay,
                          onDelete: widget.onDelete,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: context.colors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmtDate(r.createdAt),
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          color: context.colors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: context.colors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded body: line items + money breakdown + actions
          if (_expanded) ...[
            Divider(height: 1, color: context.colors.borderSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + 2,
                AppSpacing.md,
                AppSpacing.lg + 2,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...r.items.map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.productName,
                              style: AppTextStyles.bodySmall().copyWith(
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            showMoney
                                ? '${_fmtNum(line.quantity)} × ${NumberFormatter.format(line.costPrice)}'
                                : '${_fmtNum(line.quantity)} ${l10n.piece}',
                            style: AppTextStyles.caption().copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          if (showMoney) ...[
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              NumberFormatter.format(line.lineTotal),
                              style: AppTextStyles.bodySmall().copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showMoney && r.paidAmount > 0 || hasDebt) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Divider(height: 1, color: context.colors.borderSoft),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (showMoney && r.paidAmount > 0)
                    _MoneyRow(
                      label: l10n.paidLabel,
                      value: NumberFormatter.format(r.paidAmount),
                      currency: l10n.currencySom,
                      color: AppColors.success,
                    ),
                  if (hasDebt)
                    _MoneyRow(
                      label: l10n.remainingDebtLabel,
                      value: NumberFormatter.format(r.outstandingAmount),
                      currency: l10n.currencySom,
                      color: AppColors.danger,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

class _ActionsMenu extends StatelessWidget {
  final bool canPay;
  final bool canDelete;
  final VoidCallback? onPay;
  final VoidCallback? onDelete;
  const _ActionsMenu({
    required this.canPay,
    required this.canDelete,
    this.onPay,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: context.colors.textMuted),
      padding: EdgeInsets.zero,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      onSelected: (v) {
        if (v == 'pay') onPay?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (canPay)
          PopupMenuItem(
            value: 'pay',
            child: Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 18,
                  color: context.colors.brand,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(l10n.payToSupplier),
              ],
            ),
          ),
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Text(
      label,
      style: AppTextStyles.caption().copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final String currency;
  final Color color;
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Text(
          '$value $currency',
          style: AppTextStyles.bodyMedium().copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
