import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class ContinuePaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const ContinuePaymentDialog({
    super.key,
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
  });

  @override
  State<ContinuePaymentDialog> createState() => _ContinuePaymentDialogState();
}

class _ContinuePaymentDialogState extends State<ContinuePaymentDialog> {
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;
  bool _isProcessing = false;

  final _cashController = TextEditingController();
  final _terminalController = TextEditingController();
  final _transferController = TextEditingController();
  final _clickController = TextEditingController();

  double get _totalPaid {
    double total = 0;
    if (_useCash) total += double.tryParse(_cashController.text) ?? 0;
    if (_useTerminal) total += double.tryParse(_terminalController.text) ?? 0;
    if (_useTransfer) total += double.tryParse(_transferController.text) ?? 0;
    if (_useClick) total += double.tryParse(_clickController.text) ?? 0;
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;
  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    if (_hasDebt) {
      return widget.selectedCustomer != null && _totalPaid >= 0;
    } else {
      return _remainingAmount <= 0.01 ||
          (_remainingAmount > 0.01 && _totalPaid > 0);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('To\'lov usullari'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentMethod(
                  'Naqd',
                  _useCash,
                  _cashController,
                  'Naqd summa (so\'m)',
                  (v) => setState(() {
                        _useCash = v ?? false;
                        if (!_useCash) _cashController.clear();
                      })),
              _buildPaymentMethod(
                  'Plastik karta',
                  _useTerminal,
                  _terminalController,
                  'Plastik summa (so\'m)',
                  (v) => setState(() {
                        _useTerminal = v ?? false;
                        if (!_useTerminal) _terminalController.clear();
                      })),
              _buildPaymentMethod(
                  'Hisob raqam',
                  _useTransfer,
                  _transferController,
                  'Transfer summa (so\'m)',
                  (v) => setState(() {
                        _useTransfer = v ?? false;
                        if (!_useTransfer) _transferController.clear();
                      })),
              _buildPaymentMethod(
                  'Click',
                  _useClick,
                  _clickController,
                  'Click summa (so\'m)',
                  (v) => setState(() {
                        _useClick = v ?? false;
                        if (!_useClick) _clickController.clear();
                      })),

              // Qarzga olish
              CheckboxListTile(
                title: const Text('Qarzga olish'),
                value: _useDebt,
                onChanged: (value) {
                  if (widget.selectedCustomer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Qarzga olish uchun mijoz tanlang!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  setState(() => _useDebt = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 12),

              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                        'Jami:',
                        NumberFormatter.formatDecimal(widget.totalAmount),
                        null),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                        'To\'langan:',
                        NumberFormatter.formatDecimal(_totalPaid),
                        Colors.green),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                        _hasDebt ? 'Qarzga:' : 'Qolgan:',
                        NumberFormatter.formatDecimal(_remainingAmount),
                        _hasDebt ? Colors.orange : Colors.green,
                        bold: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || !_canConfirm() ? null : _onConfirm,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_hasDebt ? 'Qarzga olish' : 'Tasdiqlash'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(
    String label,
    bool value,
    TextEditingController controller,
    String hint,
    Function(bool?) onChanged,
  ) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(label),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: hint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color? color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: color != null ? TextStyle(color: color) : null),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _onConfirm() async {
    setState(() => _isProcessing = true);

    final payments = <Map<String, dynamic>>[];
    if (_useCash && _cashController.text.isNotEmpty) {
      payments.add({
        'paymentType': 'Cash',
        'amount': double.tryParse(_cashController.text) ?? 0,
      });
    }
    if (_useTerminal && _terminalController.text.isNotEmpty) {
      payments.add({
        'paymentType': 'Terminal',
        'amount': double.tryParse(_terminalController.text) ?? 0,
      });
    }
    if (_useTransfer && _transferController.text.isNotEmpty) {
      payments.add({
        'paymentType': 'Transfer',
        'amount': double.tryParse(_transferController.text) ?? 0,
      });
    }
    if (_useClick && _clickController.text.isNotEmpty) {
      payments.add({
        'paymentType': 'Click',
        'amount': double.tryParse(_clickController.text) ?? 0,
      });
    }

    try {
      widget.onConfirm(payments, _hasDebt);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }
}
