import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/number_formatter.dart';

/// Shu kuni sotilgan barcha tovarlar ro'yxati
class DailySalesDetailsScreen extends StatefulWidget {
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
  State<DailySalesDetailsScreen> createState() => _DailySalesDetailsScreenState();
}

class _DailySalesDetailsScreenState extends State<DailySalesDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final totalSales = (widget.dailyReport['totalSales'] as num).toDouble();
    final totalProfit = widget.dailyReport['profit'] != null
        ? (widget.dailyReport['profit'] as num).toDouble()
        : null;
    final totalTransactions = widget.dailyReport['totalTransactions'] as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kunlik savdo - ${DateFormat('dd.MM.yyyy').format(widget.date)}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jami savdo: ${NumberFormatter.formatDecimal(totalSales)} so\'m',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Only show profit if user is Owner
                if (totalProfit != null) ...[
                  Text(
                    'Sof foyda: ${NumberFormatter.formatDecimal(totalProfit)} so\'m',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Sotuvlar soni: $totalTransactions ta',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: widget.saleItems.isEmpty
                ? Center(
                    child: Text(
                      'Bu kunda sotuvlar yo\'q',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.saleItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.saleItems[index];
                      return _buildSaleItemCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemCard(Map<String, dynamic> item) {
    final productName = item['productName'] as String? ?? 'Noma\'lum tovar';
    final quantity = item['quantity'] as int? ?? 0;
    final costPrice = (item['costPrice'] as num?)?.toDouble() ?? 0.0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
    final totalCost = costPrice * quantity;
    final totalRevenue = salePrice * quantity;

    // Profit is now nullable (only for Owner)
    final profit = item['profit'] != null
        ? (item['profit'] as num).toDouble()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),

            // Quantity
            _buildInfoRow('Miqdor:', '$quantity dona', Icons.inventory),

            const SizedBox(height: 8),

            // Cost price
            _buildInfoRow(
              'Olingan narxi:',
              '${NumberFormatter.formatDecimal(costPrice)} so\'m',
              Icons.shopping_cart,
              color: Colors.orange,
            ),

            // Sale price
            _buildInfoRow(
              'Sotilgan narxi:',
              '${NumberFormatter.formatDecimal(salePrice)} so\'m',
              Icons.sell,
              color: Colors.blue,
            ),

            const Divider(height: 16),

            // Total cost
            _buildInfoRow(
              'Jami xarajat:',
              '${NumberFormatter.formatDecimal(totalCost)} so\'m',
              Icons.money_off,
              color: Colors.grey,
            ),

            // Total revenue
            _buildInfoRow(
              'Jami tushum:',
              '${NumberFormatter.formatDecimal(totalRevenue)} so\'m',
              Icons.attach_money,
              color: Colors.green,
            ),

            // Only show profit if user is Owner (profit is not null)
            if (profit != null) ...[
              const SizedBox(height: 8),

              // Profit (highlighted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: profit >= 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: profit >= 0 ? Colors.green[300]! : Colors.red[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          profit >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Foyda:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${NumberFormatter.formatDecimal(profit)} so\'m',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
