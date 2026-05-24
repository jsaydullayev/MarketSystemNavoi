import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/features/reports/widgets/empty_items.dart';
import 'package:market_system_client/features/reports/widgets/sale_item_card.dart';
import 'package:market_system_client/features/reports/widgets/summary_banner.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Drill-down list opened from the Daily tab "Sotuvlar tafsiloti" tap.
///
/// Reuses the migrated `DailySummaryBanner` for the dark navy hero and
/// the migrated `SaleItemCard` rows so the visual stays consistent with
/// the Reports hub.
class DailySalesDetailsScreen extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> dailyReport;
  final List<Map<String, dynamic>> saleItems;

  const DailySalesDetailsScreen({
    super.key,
    required this.date,
    required this.dailyReport,
    required this.saleItems,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final totalSales = (dailyReport['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = dailyReport['profit'] is num
        ? (dailyReport['profit'] as num).toDouble()
        : null;
    final totalTx = (dailyReport['totalTransactions'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: CommonAppBar(
        title: '${l10n.dailySales} — ${DateFormat('dd.MM.yyyy').format(date)}',
      ),
      body: Column(
        children: [
          DailySummaryBanner(
            totalSales: totalSales,
            totalProfit: totalProfit,
            totalTx: totalTx,
            isDark: false,
          ),
          Expanded(
            child: saleItems.isEmpty
                ? const EmptyItems(isDark: false)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xl4,
                    ),
                    itemCount: saleItems.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
                      child: SaleItemCard(item: saleItems[i], isDark: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
