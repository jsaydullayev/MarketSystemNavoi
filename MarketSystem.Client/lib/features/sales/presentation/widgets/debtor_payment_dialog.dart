import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

// Chaqirish uchun helper funksiya
Future<void> showDebtorPaymentSheet(
  BuildContext context, {
  required dynamic debtor,
  required List<dynamic> debtSales,
  required VoidCallback onPaymentSuccess,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DebtorPaymentSheet(
      debtor: debtor,
      debtSales: debtSales,
      onPaymentSuccess: onPaymentSuccess,
    ),
  );
}

class DebtorPaymentSheet extends StatefulWidget {
  final dynamic debtor;
  final List<dynamic> debtSales;
  final VoidCallback onPaymentSuccess;

  const DebtorPaymentSheet({
    super.key,
    required this.debtor,
    required this.debtSales,
    required this.onPaymentSuccess,
  });

  @override
  State<DebtorPaymentSheet> createState() => _DebtorPaymentSheetState();
}

class _DebtorPaymentSheetState extends State<DebtorPaymentSheet> {
  late TextEditingController _amountController;
  String? _selectedPaymentType;
  bool _isLoading = false;

  static const _paymentTypes = [
    _PaymentOption(
        type: 'Cash',
        label: 'Naqd',
        icon: Icons.payments_outlined,
        color: Colors.green),
    _PaymentOption(
        type: 'Terminal',
        label: 'Karta',
        icon: Icons.credit_card_outlined,
        color: Colors.blue),
    _PaymentOption(
        type: 'Transfer',
        label: 'Hisob',
        icon: Icons.account_balance_outlined,
        color: Colors.purple),
    _PaymentOption(
        type: 'Click',
        label: 'Click',
        icon: Icons.phone_android_outlined,
        color: Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    final remainingDebt =
        (widget.debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    _amountController =
        TextEditingController(text: remainingDebt.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final l10n = AppLocalizations.of(context)!;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.').trim()) ??
            0;

    if (amount <= 0) {
      _showSnack(l10n.enterValidAmount, isError: true);
      return;
    }
    if (_selectedPaymentType == null) {
      _showSnack(l10n.selectPaymentMethod, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final customerId = widget.debtor['customerId'];

      final debtorSales = widget.debtSales
          .where((sale) => sale['customerId'] == customerId)
          .toList();

      if (debtorSales.isEmpty) throw Exception(l10n.noDebtSalesFound);

      await salesService.addPayment(
        saleId: debtorSales[0]['id'],
        paymentType: _selectedPaymentType!,
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          "${l10n.paymentSuccess}: ${NumberFormatter.formatDecimal(amount)} ${l10n.currencySom}",
          isError: false,
        );
        widget.onPaymentSuccess();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnack('${l10n.error}: $e', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final customerName = widget.debtor['customerName'] ?? l10n.noCustomer;
    final remainingDebt =
        (widget.debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Mijoz info row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    Text(l10n.payDebt,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              // Qarz miqdori
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.debt,
                        style: TextStyle(
                            fontSize: 10, color: Colors.red.withOpacity(0.7))),
                    Text(
                      '${NumberFormatter.formatDecimal(remainingDebt)} ${l10n.currencySom}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Miqdor input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: l10n.paymentAmount,
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              suffixText: l10n.currencySom,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // To'lov usuli
          Text(
            l10n.paymentMethod,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _paymentTypes.map((opt) {
              final isSelected = _selectedPaymentType == opt.type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentType = opt.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? opt.color.withOpacity(0.12)
                            : isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? opt.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(opt.icon,
                              size: 22,
                              color: isSelected ? opt.color : Colors.grey[500]),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? opt.color : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Tugmalar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(l10n.cancel,
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.pay,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  const _PaymentOption(
      {required this.type,
      required this.label,
      required this.icon,
      required this.color});
}
