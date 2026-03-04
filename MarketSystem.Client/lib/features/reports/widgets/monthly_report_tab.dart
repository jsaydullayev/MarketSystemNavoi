import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/features/reports/widgets/date_range_picker.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/export_button.dart';
import 'package:market_system_client/features/reports/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class MonthlyReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onRangeChanged;
  final VoidCallback onExport;

  const MonthlyReportTab({
    required this.report,
    required this.startDate,
    required this.endDate,
    required this.onRangeChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    if (report == null) return const EmptyReport();
    final l10n = AppLocalizations.of(context)!;
    final totalSales = (report!['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalTx = (report!['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalPaid = (report!['totalPaidSales'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (report!['totalDebtSales'] as num?)?.toDouble() ?? 0.0;
    final avgSale = (report!['averageSale'] as num?)?.toDouble() ?? 0.0;
    final profit =
        report!['profit'] is num ? (report!['profit'] as num).toDouble() : null;
    final payments = report!['paymentBreakdown'] is List
        ? report!['paymentBreakdown'] as List
        : [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DateRangeRow(
          startDate: startDate,
          endDate: endDate,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.totalSale,
                value:
                    '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                icon: Icons.attach_money_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.saleCount,
                value: '$totalTx ${l10n.piece}',
                icon: Icons.shopping_cart_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.paid,
                value:
                    '${NumberFormatter.formatDecimal(totalPaid)} ${l10n.currencySom}',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.onDebt,
                value:
                    '${NumberFormatter.formatDecimal(totalDebt)} ${l10n.currencySom}',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: l10n.averageSale,
          value:
              '${NumberFormatter.formatDecimal(avgSale)} ${l10n.currencySom}',
          icon: Icons.calculate_outlined,
          color: Colors.purple,
          subtitle: l10n.averageTransactionValue,
        ),
        if (profit != null) ...[
          const SizedBox(height: 12),
          StatCard(
            title: l10n.netProfit,
            value:
                '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.green,
          ),
        ],
        if (payments.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionTitle(title: l10n.byPaymentType),
          const SizedBox(height: 10),
          ...payments.map((p) {
            if (p is! Map<String, dynamic>) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReportPaymentBreakdownCard(
                paymentType: p['paymentType']?.toString() ?? '',
                amount: (p['amount'] as num?)?.toDouble() ?? 0,
                count: (p['count'] as num?)?.toInt() ?? 0,
                totalSales: totalSales,
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        ExportButton(onTap: onExport),
      ],
    );
  }
}
