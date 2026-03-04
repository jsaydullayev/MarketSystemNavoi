import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/features/reports/widgets/date_picker_row.dart';
import 'package:market_system_client/features/reports/widgets/empty_report.dart';
import 'package:market_system_client/features/reports/widgets/export_button.dart';
import 'package:market_system_client/features/reports/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/reports/widgets/section_title.dart';
import 'package:market_system_client/features/reports/widgets/stat_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class DailyReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final DateTime selectedDate;
  final bool isLoadingDetails;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onViewDetails;
  final VoidCallback onExport;

  const DailyReportTab({
    required this.report,
    required this.selectedDate,
    required this.isLoadingDetails,
    required this.onDateChanged,
    required this.onViewDetails,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (report == null) {
      return const EmptyReport();
    }

    final totalSales = (report!['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalTx = (report!['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalPaid = (report!['totalPaidSales'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (report!['totalDebtSales'] as num?)?.toDouble() ?? 0.0;
    final profit =
        report!['profit'] is num ? (report!['profit'] as num).toDouble() : null;
    final payments = report!['paymentBreakdown'] is List
        ? report!['paymentBreakdown'] as List
        : [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DatePickerRow(selectedDate: selectedDate, onChanged: onDateChanged),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.dailySales,
                value:
                    '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                icon: Icons.trending_up_rounded,
                color: Colors.green,
                subtitle: l10n.salesCount(totalTx),
                isClickable: true,
                isLoading: isLoadingDetails,
                onTap: onViewDetails,
              ),
            ),
            if (profit != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: l10n.netProfit,
                  value:
                      '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
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
