import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class PaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;
  final VoidCallback? onCancel;

  const PaymentDialog({
    super.key,
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<PaymentDialog> createState() => PaymentDialogState();
}

class PaymentDialogState extends State<PaymentDialog> {
  // Sherigingning o'sha mantiqlari (o'zgarmadi)
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();
  final TextEditingController _clickController = TextEditingController();

  bool _isProcessing = false;

  double get _totalPaid {
    double total = 0;
    if (_useCash)
      total += double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0;
    if (_useTerminal)
      total +=
          double.tryParse(_terminalController.text.replaceAll(',', '.')) ?? 0;
    if (_useTransfer)
      total +=
          double.tryParse(_transferController.text.replaceAll(',', '.')) ?? 0;
    if (_useClick)
      total += double.tryParse(_clickController.text.replaceAll(',', '.')) ?? 0;
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;
  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  // Tasdiqlash tugmasi mantiqi (o'zgarmadi)
  bool _canConfirm() {
    if (_hasDebt) return widget.selectedCustomer != null;
    return _totalPaid > 0 && _remainingAmount <= 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 15,
        ),
        decoration: BoxDecoration(
          color: AppColors.getCard(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.paymentMethods,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        NumberFormatter.formatDecimal(widget.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildPaymentRow(
                  l10n.cash,
                  _useCash,
                  (v) => setState(() => _useCash = v!),
                  _cashController,
                  Icons.money,
                  Colors.green),
              _buildPaymentRow(
                  l10n.bankCard,
                  _useTerminal,
                  (v) => setState(() => _useTerminal = v!),
                  _terminalController,
                  Icons.credit_card,
                  Colors.blue),
              _buildPaymentRow(
                  l10n.transfer,
                  _useTransfer,
                  (v) => setState(() => _useTransfer = v!),
                  _transferController,
                  Icons.account_balance,
                  Colors.orange),
              _buildPaymentRow(
                  l10n.click,
                  _useClick,
                  (v) => setState(() => _useClick = v!),
                  _clickController,
                  Icons.phone_android,
                  Colors.deepPurple),
              const Divider(height: 30),
              _buildSummary(l10n),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: (_isProcessing || !_canConfirm())
                          ? null
                          : _confirmAction,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String title, bool value, Function(bool?) onChanged,
      TextEditingController controller, IconData icon, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        CheckboxListTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: color),
          contentPadding: EdgeInsets.zero,
          activeColor: color,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 10),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.enterAmount,
                suffixText: l10n.currencySom,
                filled: true,
                fillColor: color.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _summaryLine(l10n.paid, NumberFormatter.formatDecimal(_totalPaid),
              Colors.green),
          const SizedBox(height: 5),
          _summaryLine(
              _hasDebt ? l10n.onDebt : l10n.remaining,
              NumberFormatter.formatDecimal(_remainingAmount),
              _remainingAmount > 0 ? Colors.red : Colors.green),
          const Divider(),
          CheckboxListTile(
            title: Text(l10n.takeAsDebt, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
                widget.selectedCustomer?['fullName'] ?? l10n.selectCustomer,
                style: const TextStyle(fontSize: 12)),
            value: _useDebt,
            onChanged: widget.selectedCustomer == null
                ? null
                : (v) => setState(() => _useDebt = v!),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))
    ]);
  }

  void _confirmAction() {
    final l10n = AppLocalizations.of(context)!;
    List<Map<String, dynamic>> payments = [];
    if (_useCash)
      payments.add({
        'paymentType': l10n.cash,
        'amount':
            double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0
      });
    if (_useTerminal)
      payments.add({
        'paymentType': l10n.card,
        'amount':
            double.tryParse(_terminalController.text.replaceAll(',', '.')) ?? 0
      });
    if (_useTransfer)
      payments.add({
        'paymentType': l10n.transfer,
        'amount':
            double.tryParse(_transferController.text.replaceAll(',', '.')) ?? 0
      });
    if (_useClick)
      payments.add({
        'paymentType': l10n.click,
        'amount':
            double.tryParse(_clickController.text.replaceAll(',', '.')) ?? 0
      });

    setState(() => _isProcessing = true);
    widget.onConfirm(payments, _hasDebt);
  }
}
