import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class PaymentHistoryDialog extends StatelessWidget {
  final String customerName;
  final List<dynamic> debtorSales;

  const PaymentHistoryDialog({
    super.key,
    required this.customerName,
    required this.debtorSales,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('To\'lov tarixi: $customerName'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: ListView.builder(
          itemCount: debtorSales.length,
          itemBuilder: (context, index) {
            final sale = debtorSales[index];
            final payments = sale['payments'] as List<dynamic>? ?? [];
            final saleTotal = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
            final salePaid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
            final saleRemaining =
                (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
            final saleDate = sale['createdAt'];

            String formattedDate = 'Noma\'lum';
            if (saleDate != null) {
              try {
                final date = DateTime.parse(saleDate);
                formattedDate = '${date.day}.${date.month}.${date.year}';
              } catch (e) {
                formattedDate = saleDate.toString();
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text('Savdo #${sale['id'].toString().substring(0, 8)}'),
                subtitle: Text(
                    '$formattedDate • Jami: ${NumberFormatter.formatDecimal(saleTotal)}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Savdo summary
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                  'Jami summa:',
                                  NumberFormatter.formatDecimal(saleTotal),
                                  null),
                              const SizedBox(height: 4),
                              _buildSummaryRow(
                                  'To\'langan:',
                                  NumberFormatter.formatDecimal(salePaid),
                                  Colors.green),
                              const SizedBox(height: 4),
                              _buildSummaryRow(
                                  'Qolgan qarz:',
                                  NumberFormatter.formatDecimal(saleRemaining),
                                  Colors.red),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // To'lovlar ro'yxati
                        if (payments.isEmpty)
                          const Text('To\'lovlar yo\'q',
                              style: TextStyle(color: Colors.grey))
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To\'lovlar:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ...payments.map<Widget>(
                                  (payment) => _PaymentTile(payment: payment)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: valueColor != null ? TextStyle(color: valueColor) : null),
        Text(value,
            style: valueColor != null
                ? TextStyle(color: valueColor, fontWeight: FontWeight.w600)
                : null),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final dynamic payment;

  const _PaymentTile({required this.payment});

  IconData _getPaymentIcon(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'cash' || t.contains('naqd')) return Icons.money;
    if (t == 'terminal' || t.contains('plastik') || t.contains('karta'))
      return Icons.credit_card;
    if (t == 'transfer' || t.contains('hisob')) return Icons.account_balance;
    if (t == 'click') return Icons.touch_app;
    return Icons.payment;
  }

  String _getPaymentTypeDisplay(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'cash' || t.contains('naqd')) return 'Naqd';
    if (t == 'terminal' || t.contains('plastik') || t.contains('karta'))
      return 'Plastik karta';
    if (t == 'transfer' || t.contains('hisob')) return 'Hisob raqam';
    if (t == 'click') return 'Click';
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentType = payment['paymentType']?.toString() ?? 'Noma\'lum';
    final paymentDate = payment['createdAt'];

    String formattedDate = '';
    if (paymentDate != null) {
      try {
        final date = DateTime.parse(paymentDate);
        formattedDate =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      child: ListTile(
        leading: Icon(_getPaymentIcon(paymentType), color: Colors.green),
        title: Text(
          NumberFormatter.formatDecimal(amount),
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
        ),
        subtitle: Text(
          '${_getPaymentTypeDisplay(paymentType)}${formattedDate.isNotEmpty ? ' • $formattedDate' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
