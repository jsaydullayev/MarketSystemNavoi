import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ReportPaymentBreakdownCard extends StatelessWidget {
  final String paymentType;
  final double amount;
  final int count;
  final double totalSales;

  const ReportPaymentBreakdownCard({
    super.key,
    required this.paymentType,
    required this.amount,
    required this.count,
    required this.totalSales,
  });

  static const _config = {
    'Cash': {
      'name': 'Naqd',
      'icon': Icons.payments_outlined,
      'color': Colors.green
    },
    'Terminal': {
      'name': 'Terminal',
      'icon': Icons.credit_card_outlined,
      'color': Colors.orange
    },
    'Transfer': {
      'name': 'Hisob raqam',
      'icon': Icons.account_balance_outlined,
      'color': Colors.purple
    },
    'Click': {
      'name': 'Click',
      'icon': Icons.phone_android_outlined,
      'color': Colors.blue
    },
    'Qaytarilgan': {
      'name': 'Qaytarilgan',
      'icon': Icons.assignment_return_outlined,
      'color': Colors.red
    },
    'Refund': {
      'name': 'Qaytarilgan',
      'icon': Icons.assignment_return_outlined,
      'color': Colors.red
    },
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRefund = paymentType == 'Qaytarilgan' || paymentType == 'Refund';

    final cfg = _config[paymentType] ??
        {
          'name': paymentType,
          'icon': Icons.payment_outlined,
          'color': Colors.grey
        };
    final color = cfg['color'] as Color;
    final icon = cfg['icon'] as IconData;
    final name = cfg['name'] as String;

    // For refunds, show absolute value but keep track of negative
    final displayAmount = amount.abs();
    final pct = totalSales > 0 ? (displayAmount / totalSales * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (!isRefund)
                  Text(
                    l10n.transactionStats(count, pct),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  )
                else
                  Text(
                    count > 0 ? l10n.transactionStats(count, pct) : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                const SizedBox(height: 6),
                if (!isRefund)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalSales > 0 ? amount / totalSales : 0,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalSales > 0 ? displayAmount / totalSales : 0,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.red),
                      minHeight: 4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isRefund ? '-' : ''}${NumberFormatter.formatDecimal(displayAmount)} ${l10n.currencySom}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isRefund ? Colors.red : color,
            ),
          ),
        ],
      ),
    );
  }
}
