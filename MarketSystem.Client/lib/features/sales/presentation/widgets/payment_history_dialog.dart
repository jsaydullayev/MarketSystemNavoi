import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

// Chaqirish uchun helper
Future<void> showPaymentHistorySheet(
  BuildContext context, {
  required String customerName,
  required List<dynamic> debtorSales,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaymentHistorySheet(
      customerName: customerName,
      debtorSales: debtorSales,
    ),
  );
}

class PaymentHistorySheet extends StatelessWidget {
  final String customerName;
  final List<dynamic> debtorSales;

  const PaymentHistorySheet({
    super.key,
    required this.customerName,
    required this.debtorSales,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          "To'lov tarixi",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

            // List
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: debtorSales.length,
                itemBuilder: (context, index) {
                  final sale = debtorSales[index];
                  return _SaleHistoryCard(sale: sale, isDark: isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  final dynamic sale;
  final bool isDark;

  const _SaleHistoryCard({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final payments = sale['payments'] as List<dynamic>? ?? [];
    final saleTotal = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final salePaid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final saleRemaining = (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    final saleId = sale['id']?.toString() ?? '';
    final saleDate = sale['createdAt'];

    String formattedDate = 'Noma\'lum';
    if (saleDate != null) {
      try {
        final date = DateTime.parse(saleDate);
        formattedDate = '${date.day}.${date.month}.${date.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                '#${saleId.length >= 8 ? saleId.substring(0, 8).toUpperCase() : saleId.toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: saleRemaining > 0
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  saleRemaining > 0 ? 'Qarz bor' : "To'langan",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: saleRemaining > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$formattedDate  •  ${NumberFormatter.formatDecimal(saleTotal)} so\'m',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Jami',
                    value: '${NumberFormatter.formatDecimal(saleTotal)} so\'m',
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: "To'langan",
                    value: '${NumberFormatter.formatDecimal(salePaid)} so\'m',
                    valueColor: Colors.green,
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Qolgan qarz',
                    value:
                        '${NumberFormatter.formatDecimal(saleRemaining)} so\'m',
                    valueColor: saleRemaining > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "To'lovlar (${payments.length})",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...payments
                  .map<Widget>((p) => _PaymentTile(payment: p, isDark: isDark)),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "To'lovlar yo'q",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final dynamic payment;
  final bool isDark;

  const _PaymentTile({required this.payment, required this.isDark});

  static IconData _icon(String type) {
    final t = type.toLowerCase();
    if (t == 'cash') return Icons.payments_outlined;
    if (t == 'terminal') return Icons.credit_card_outlined;
    if (t == 'transfer') return Icons.account_balance_outlined;
    if (t == 'click') return Icons.phone_android_outlined;
    return Icons.payment_outlined;
  }

  static String _label(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Naqd';
      case 'terminal':
        return 'Plastik karta';
      case 'transfer':
        return 'Hisob raqam';
      case 'click':
        return 'Click';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentType = payment['paymentType']?.toString() ?? '';
    final paymentDate = payment['createdAt'];

    String formattedDate = '';
    if (paymentDate != null) {
      try {
        final date = DateTime.parse(paymentDate);
        formattedDate =
            '${date.day}.${date.month}.${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(_icon(paymentType), size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(paymentType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (formattedDate.isNotEmpty)
                  Text(formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            '${NumberFormatter.formatDecimal(amount)} so\'m',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
