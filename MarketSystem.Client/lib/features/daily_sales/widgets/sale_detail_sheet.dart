import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class SaleDetailSheet extends StatelessWidget {
  final dynamic sale;
  final Map<String, dynamic> saleDetails;
  final bool isOwner;

  const SaleDetailSheet({
    super.key,
    required this.sale,
    required this.saleDetails,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = saleDetails['saleItems'] as List<dynamic>? ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← content baqadar
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          _buildHeader(context, theme, isDark, l10n),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // max 60%
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile(Icons.person_outline, l10n.customer,
                      sale.customerName ?? l10n.anonymousCustomer, theme),
                  _buildInfoTile(
                      Icons.account_balance_wallet_outlined,
                      l10n.paymentType,
                      _getPaymentText(sale.paymentType, l10n),
                      theme),
                  const SizedBox(height: 20),
                  Text(l10n.products,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...items.map(
                      (item) => _buildProductItem(item, theme, isDark, l10n)),
                  const SizedBox(height: 24),
                  _buildTotalsCard(theme, l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark,
      AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.saleDetail,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
                backgroundColor: theme.dividerColor.withOpacity(0.1)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      dynamic item, ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? l10n.unknown,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${item['quantity']} x ${item['unitPrice']}",
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text("${item['totalPrice']} ${l10n.currencySom}",
              style: TextStyle(
                  color: theme.primaryColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _totalRow(l10n.totalSum, "${sale.totalAmount} ${l10n.currencySom}",
              Colors.white),
          if (isOwner && sale.profit != null) ...[
            const Divider(color: Colors.white24, height: 20),
            _totalRow(l10n.profit, "+${sale.profit} ${l10n.currencySom}",
                Colors.greenAccent),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  String _getPaymentText(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'cash':
        return l10n.cash;
      case 'card':
        return '${l10n.card} / ${l10n.terminal}';
      default:
        return type;
    }
  }
}
