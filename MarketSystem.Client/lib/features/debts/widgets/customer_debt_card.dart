import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class CustomerDebtCard extends StatelessWidget {
  final String customerName;
  final List<dynamic> customerDebts;
  final double totalDebt;
  final double remainingDebt;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const CustomerDebtCard({
    required this.customerName,
    required this.customerDebts,
    required this.totalDebt,
    required this.remainingDebt,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDebt = remainingDebt > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDebt
              ? const Color(0xFFEF4444).withOpacity(0.15)
              : const Color(0xFF10B981).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  customerName: customerName,
                  debtCount: customerDebts.length,
                  hasDebt: hasDebt,
                ),
                const SizedBox(height: 14),
                _DebtAmountRow(
                  totalDebt: totalDebt,
                  remainingDebt: remainingDebt,
                ),
                if (hasDebt) ...[
                  const SizedBox(height: 14),
                  _PayButton(onTap: onPay),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtAmountRow extends StatelessWidget {
  final double totalDebt;
  final double remainingDebt;

  const _DebtAmountRow({required this.totalDebt, required this.remainingDebt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountItem(
              label: l10n.totalDebt,
              amount: totalDebt,
              color: const Color(0xFF64748B),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.withOpacity(0.2)),
          Expanded(
            child: _AmountItem(
              label: l10n.remaining,
              amount: remainingDebt,
              color: const Color(0xFFEF4444),
              isBold: true,
              align: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String customerName;
  final int debtCount;
  final bool hasDebt;

  const _CardHeader({
    required this.customerName,
    required this.debtCount,
    required this.hasDebt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF3B82F6), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            customerName,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: hasDebt
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.debtCount(debtCount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  hasDebt ? const Color(0xFFEF4444) : const Color(0xFF059669),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final CrossAxisAlignment align;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 3),
        Text(
          '${NumberFormatter.format(amount)} ${l10n.currencySom}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.payment_rounded, size: 18),
        label: Text(
          l10n.pay,
          style:
              const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
