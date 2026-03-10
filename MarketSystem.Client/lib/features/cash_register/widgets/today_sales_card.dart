import 'package:flutter/material.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/data/models/cash_register_model.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class TodaySalesCard extends StatelessWidget {
  final TodaySalesSummaryModel todaySales;

  const TodaySalesCard({super.key, required this.todaySales});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A1E) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.25),
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
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.today_outlined,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.todaysSales,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SalesRow(
            label: l10n.saleCount,
            value: l10n.itemsCount(todaySales.totalSales),
          ),
          const SizedBox(height: 10),
          _SalesRow(
            label: l10n.totalSum,
            value:
                '${todaySales.totalAmount.toStringAsFixed(0)} ${l10n.currencySom}',
          ),
          const SizedBox(height: 10),
          _SalesRow(
            label: l10n.paid,
            value:
                '${todaySales.totalPaid.toStringAsFixed(0)} ${l10n.currencySom}',
            valueColor: Colors.green,
          ),
          if (todaySales.debtAmount > 0) ...[
            const SizedBox(height: 10),
            _SalesRow(
              label: l10n.onDebt,
              value:
                  '${todaySales.debtAmount.toStringAsFixed(0)} ${l10n.currencySom}',
              valueColor: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SalesRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
