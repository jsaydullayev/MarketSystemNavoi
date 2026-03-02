import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class DebtorPaymentDialog extends StatefulWidget {
  final dynamic debtor;
  final List<dynamic> debtSales;
  final VoidCallback onPaymentSuccess;

  const DebtorPaymentDialog({
    super.key,
    required this.debtor,
    required this.debtSales,
    required this.onPaymentSuccess,
  });

  @override
  State<DebtorPaymentDialog> createState() => _DebtorPaymentDialogState();
}

class _DebtorPaymentDialogState extends State<DebtorPaymentDialog> {
  late TextEditingController _amountController;
  bool _selectedCash = false;
  bool _selectedTerminal = false;
  bool _selectedTransfer = false;
  bool _selectedClick = false;

  @override
  void initState() {
    super.initState();
    final remainingDebt =
        (widget.debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    _amountController = TextEditingController(text: remainingDebt.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.debtor['customerName'] ?? 'Mijozsiz';
    final remainingDebt =
        (widget.debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;

    return AlertDialog(
      title: Text('To\'lash: $customerName'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Qarz miqdori
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Qarz:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    NumberFormatter.formatDecimal(remainingDebt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // To'lov miqdori
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'To\'lov miqdori',
                prefixText: 'so\'m ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // To'lov usuli
            const Text('To\'lov usuli:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPaymentOption('Naqd', _selectedCash, (v) {
              setState(() {
                _selectedCash = v ?? false;
                if (_selectedCash) {
                  _selectedTerminal =
                      _selectedTransfer = _selectedClick = false;
                }
              });
            }),
            _buildPaymentOption('Plastik karta', _selectedTerminal, (v) {
              setState(() {
                _selectedTerminal = v ?? false;
                if (_selectedTerminal) {
                  _selectedCash = _selectedTransfer = _selectedClick = false;
                }
              });
            }),
            _buildPaymentOption('Hisob raqam', _selectedTransfer, (v) {
              setState(() {
                _selectedTransfer = v ?? false;
                if (_selectedTransfer) {
                  _selectedCash = _selectedTerminal = _selectedClick = false;
                }
              });
            }),
            _buildPaymentOption('Click', _selectedClick, (v) {
              setState(() {
                _selectedClick = v ?? false;
                if (_selectedClick) {
                  _selectedCash = _selectedTerminal = _selectedTransfer = false;
                }
              });
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('To\'lash'),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
      String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _onConfirm() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'g\'ri miqdor kiriting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String paymentType = '';
    if (_selectedCash)
      paymentType = 'Cash';
    else if (_selectedTerminal)
      paymentType = 'Terminal';
    else if (_selectedTransfer)
      paymentType = 'Transfer';
    else if (_selectedClick)
      paymentType = 'Click';
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, to\'lov usulini tanlang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final customerId = widget.debtor['customerId'];
      final debtorSales = widget.debtSales
          .where((sale) => sale['customerId'] == customerId)
          .toList();

      if (debtorSales.isEmpty) throw Exception('Qarz savdolari topilmadi');

      final saleId = debtorSales[0]['id'];
      await salesService.addPayment(
        saleId: saleId,
        paymentType: paymentType,
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ To\'lov muvaffaqiyatli amalga oshirildi: ${NumberFormatter.formatDecimal(amount)}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPaymentSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
