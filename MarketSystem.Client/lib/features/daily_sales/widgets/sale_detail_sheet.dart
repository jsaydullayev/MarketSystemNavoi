import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10)),
              ),
              _buildHeader(context, theme, isDark),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoTile(Icons.person_outline, "Mijoz",
                          sale.customerName ?? "Nomsiz mijoz", theme),
                      _buildInfoTile(
                          Icons.account_balance_wallet_outlined,
                          "To'lov turi",
                          _getPaymentText(sale.paymentType),
                          theme),
                      const SizedBox(height: 20),
                      Text("Mahsulotlar",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...items.map(
                          (item) => _buildProductItem(item, theme, isDark)),
                      const SizedBox(height: 24),
                      _buildTotalsCard(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Savdo tafsiloti",
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

  Widget _buildProductItem(dynamic item, ThemeData theme, bool isDark) {
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
                Text(item['productName'] ?? "Noma'lum",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${item['quantity']} x ${item['unitPrice']}",
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text("${item['totalPrice']} so'm",
              style: TextStyle(
                  color: theme.primaryColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _totalRow("Jami summa", "${sale.totalAmount} so'm", Colors.white),
          if (isOwner && sale.profit != null) ...[
            const Divider(color: Colors.white24, height: 20),
            _totalRow("Foyda", "+${sale.profit} so'm", Colors.greenAccent),
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

  String _getPaymentText(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Naqd';
      case 'card':
        return 'Karta / Terminal';
      default:
        return type;
    }
  }
}
