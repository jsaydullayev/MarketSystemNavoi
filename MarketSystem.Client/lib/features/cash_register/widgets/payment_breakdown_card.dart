import 'package:flutter/material.dart';
import 'package:market_system_client/data/models/cash_register_model.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class PaymentBreakdownCard extends StatelessWidget {
  final TodaySalesSummaryModel todaySales;

  const PaymentBreakdownCard({super.key, required this.todaySales});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2A) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.todaysIncomes,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todaySales.cashPaid > 0)
            _PaymentRow(
              icon: Icons.payments_outlined,
              label: l10n.cashMoney,
              amount: todaySales.cashPaid,
              color: Colors.green,
            ),
          if (todaySales.cardPaid > 0)
            _PaymentRow(
              icon: Icons.credit_card_outlined,
              label: l10n.bankCard,
              amount: todaySales.cardPaid,
              color: Colors.blue,
            ),
          if (todaySales.clickPaid > 0)
            _PaymentRow(
              icon: Icons.phone_android_outlined,
              label: l10n.click,
              amount: todaySales.clickPaid,
              color: Colors.purple,
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _PaymentRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ${l10n.currencySom}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
