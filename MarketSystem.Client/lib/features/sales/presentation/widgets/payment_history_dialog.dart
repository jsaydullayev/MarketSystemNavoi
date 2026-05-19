import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

// Chaqirish uchun helper
Future<void> showPaymentHistorySheet(
  BuildContext context, {
  required String customerName,
  required List<dynamic> debtorSales,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaymentHistorySheet(
      customerName: customerName,
      debtorSales: debtorSales,
    ),
  );
}

class PaymentHistorySheet extends StatelessWidget {
  final String customerName;
  final List<dynamic> debtorSales;

  const PaymentHistorySheet({
    super.key,
    required this.customerName,
    required this.debtorSales,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.lg, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl2, AppSpacing.lg, AppSpacing.xl2, AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: AppTextStyles.titleMedium()
                              .copyWith(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: AppTextStyles.titleMedium().copyWith(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          l10n.paymentHistory,
                          style: AppTextStyles.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: AppColors.borderSoft),

            // List
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg,
                    AppSpacing.xl, AppSpacing.xl3),
                itemCount: debtorSales.length,
                itemBuilder: (context, index) {
                  final sale = debtorSales[index];
                  return _SaleHistoryCard(sale: sale);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  final dynamic sale;

  const _SaleHistoryCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payments = sale['payments'] as List<dynamic>? ?? [];
    final saleTotal = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final salePaid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final saleRemaining = (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    final saleId = sale['id']?.toString() ?? '';
    final saleDate = sale['createdAt'];

    String formattedDate = l10n.unknown;
    if (saleDate != null) {
      try {
        final date = DateTime.parse(saleDate);
        formattedDate = '${date.day}.${date.month}.${date.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          title: Row(
            children: [
              Text(
                '#${saleId.length >= 8 ? saleId.substring(0, 8).toUpperCase() : saleId.toUpperCase()}',
                style: AppTextStyles.labelLarge().copyWith(fontSize: 14),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: saleRemaining > 0
                      ? AppColors.dangerLight
                      : AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  saleRemaining > 0 ? l10n.hasDebt : l10n.paid,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    color: saleRemaining > 0
                        ? AppColors.danger
                        : AppColors.success,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$formattedDate  •  ${NumberFormatter.formatDecimal(saleTotal)} ${l10n.currencySom}',
              style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
            ),
          ),
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: l10n.total,
                    value:
                        '${NumberFormatter.formatDecimal(saleTotal)} ${l10n.currencySom}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(
                    label: l10n.paid,
                    value:
                        '${NumberFormatter.formatDecimal(salePaid)} ${l10n.currencySom}',
                    valueColor: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(
                    label: l10n.remainingDebt,
                    value:
                        '${NumberFormatter.formatDecimal(saleRemaining)} ${l10n.currencySom}',
                    valueColor: saleRemaining > 0
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ],
              ),
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.payments} (${payments.length})',
                  style: AppTextStyles.labelLarge().copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...payments.map<Widget>((p) => _PaymentTile(payment: p)),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(
                  l10n.noPayments,
                  style: AppTextStyles.bodySmall(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall().copyWith(fontSize: 13)),
        Text(
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final dynamic payment;

  const _PaymentTile({required this.payment});

  static IconData _icon(String type) {
    final t = type.toLowerCase();
    if (t == 'cash') return Icons.payments_outlined;
    if (t == 'terminal') return Icons.credit_card_outlined;
    if (t == 'transfer') return Icons.account_balance_outlined;
    if (t == 'click') return Icons.phone_android_outlined;
    return Icons.payment_outlined;
  }

  static String _label(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'cash':
        return l10n.cash;
      case 'terminal':
        return l10n.bankCard;
      case 'transfer':
        return l10n.accountNumber;
      case 'click':
        return l10n.click;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentType = payment['paymentType']?.toString() ?? '';
    final paymentDate = payment['createdAt'];

    String formattedDate = '';
    if (paymentDate != null) {
      try {
        final date = DateTime.parse(paymentDate);
        formattedDate =
            '${date.day}.${date.month}.${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_icon(paymentType), size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(paymentType, l10n),
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (formattedDate.isNotEmpty)
                  Text(formattedDate,
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${NumberFormatter.formatDecimal(amount)} ${l10n.currencySom}',
            style: AppTextStyles.labelLarge().copyWith(
              fontSize: 14,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
