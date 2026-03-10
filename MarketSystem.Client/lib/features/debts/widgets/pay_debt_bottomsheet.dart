import 'package:flutter/material.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/services/debt_service.dart';
import 'package:market_system_client/features/debts/widgets/payment_type_selector.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class PayDebtBottomSheet extends StatefulWidget {
  final dynamic debt;
  final String customerName;
  final VoidCallback onSuccess;

  const PayDebtBottomSheet({
    super.key,
    required this.debt,
    required this.customerName,
    required this.onSuccess,
  });

  @override
  State<PayDebtBottomSheet> createState() => _PayDebtBottomSheetState();
}

class _PayDebtBottomSheetState extends State<PayDebtBottomSheet> {
  final _amountController = TextEditingController();
  String _selectedPaymentType = 'Cash';
  bool _isLoading = false;
  String? _errorMessage;

  double get _remaining => (widget.debt['remainingDebt'] as num).toDouble();

  @override
  void initState() {
    super.initState();
    final val = _remaining;
    _amountController.text =
        val == val.truncateToDouble() ? val.toInt().toString() : val.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      setState(() => _errorMessage = l10n.enterCorrectAmount);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtService = DebtService(authProvider: authProvider);
      await debtService.payDebt(
        debtId: widget.debt['id'],
        paymentType: _selectedPaymentType,
        amount: amount,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentSuccess),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = _remaining;
    final entered =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final isOverpay = entered > remaining && entered > 0;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment_rounded,
                    color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.payDebt,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4),
                  ),
                  Text(
                    widget.customerName,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.remainingDebt,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 13)),
                Text(
                  '${NumberFormatter.format(remaining)} ${l10n.currencySom}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            onChanged: (_) => setState(() => _errorMessage = null),
            decoration: InputDecoration(
              labelText: l10n.paymentAmountLabel,
              prefixIcon:
                  const Icon(Icons.money_rounded, color: Color(0xFF3B82F6)),
              suffixText: l10n.currencySom,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
            ),
          ),
          if (isOverpay) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFF97316).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFF97316), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.payingTooMuchWarning(
                          NumberFormatter.format(entered - remaining)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFFEF4444), size: 16),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.paymentType,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          PaymentTypeSelector(
            selected: _selectedPaymentType,
            onChanged: (val) => setState(() => _selectedPaymentType = val),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      l10n.processPayment,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
