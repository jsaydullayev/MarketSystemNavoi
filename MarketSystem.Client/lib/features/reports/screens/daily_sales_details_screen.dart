import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../../../core/utils/number_formatter.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final totalSales = (dailyReport['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = dailyReport['profit'] is num
        ? (dailyReport['profit'] as num).toDouble()
        : null;
    final totalTx = (dailyReport['totalTransactions'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: '${l10n.dailySales} — ${DateFormat('dd.MM.yyyy').format(date)}',
      ),
      body: Column(
        children: [
          _DailySummaryBanner(
            totalSales: totalSales,
            totalProfit: totalProfit,
            totalTx: totalTx,
            isDark: isDark,
          ),
          Expanded(
            child: saleItems.isEmpty
                ? _EmptyItems(isDark: isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: saleItems.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SaleItemCard(item: saleItems[i], isDark: isDark),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryBanner extends StatelessWidget {
  final double totalSales;
  final double? totalProfit;
  final int totalTx;
  final bool isDark;

  const _DailySummaryBanner({
    required this.totalSales,
    required this.totalProfit,
    required this.totalTx,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF3B82F6).withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalSales,
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormatter.formatDecimal(totalSales)} ${l10n.currencySom}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.salesCount(totalTx),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (totalProfit != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.netProfit,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormatter.formatDecimal(totalProfit!)} ${l10n.currencySom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SaleItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;

  const _SaleItemCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = item['productName'] as String? ?? l10n.unknownProduct;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final revenue = (item['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final profit =
        item['profit'] is num ? (item['profit'] as num).toDouble() : null;

    final qtyStr = qty % 1 == 0
        ? '${qty.toInt()} ${l10n.piece}'
        : '${qty.toStringAsFixed(1)} ${l10n.piece}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.withOpacity(0.12),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormatter.formatDecimal(revenue)} ${l10n.currencySom}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 5),
                    Text(
                      qtyStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profit != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: profit >= 0
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: profit >= 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        profit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: profit >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.netProfit,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${NumberFormatter.formatDecimal(profit)} ${l10n.currencySom}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  final bool isDark;

  const _EmptyItems({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSalesToday,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
