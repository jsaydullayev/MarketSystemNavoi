import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/profit_model.dart';

class SaleGridItem extends StatelessWidget {
  final DailySalesListItemModel sale;
  final VoidCallback onTap;

  const SaleGridItem({super.key, required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(sale.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withOpacity(0.15), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('HH:mm').format(sale.createdAt),
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                _formatAmount(sale.totalAmount),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 6),
            _buildStatusBadge(sale.status, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.bold, color: color)),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 100).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'debt':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
