import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ContinuePaymentSheet extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const ContinuePaymentSheet({
    super.key,
    required this.saleId,
    required this.totalAmount,
    required this.selectedCustomer,
    required this.onConfirm,
  });

  @override
  State<ContinuePaymentSheet> createState() => _ContinuePaymentSheetState();
}

class _ContinuePaymentSheetState extends State<ContinuePaymentSheet> {
  final _cashCtrl = TextEditingController();
  final _terminalCtrl = TextEditingController();
  final _transferCtrl = TextEditingController();
  final _clickCtrl = TextEditingController();

  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;
  bool _isProcessing = false;

  static const _paymentOptions = [
    _PaymentOption(
        key: 'cash',
        label: 'Naqd',
        icon: Icons.payments_outlined,
        color: Colors.green),
    _PaymentOption(
        key: 'terminal',
        label: 'Karta',
        icon: Icons.credit_card_outlined,
        color: Colors.blue),
    _PaymentOption(
        key: 'transfer',
        label: 'Hisob',
        icon: Icons.account_balance_outlined,
        color: Colors.purple),
    _PaymentOption(
        key: 'click',
        label: 'Click',
        icon: Icons.phone_android_outlined,
        color: Colors.orange),
  ];

  @override
  void dispose() {
    _cashCtrl.dispose();
    _terminalCtrl.dispose();
    _transferCtrl.dispose();
    _clickCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  double get _totalPaid {
    double t = 0;
    if (_useCash) t += _parse(_cashCtrl);
    if (_useTerminal) t += _parse(_terminalCtrl);
    if (_useTransfer) t += _parse(_transferCtrl);
    if (_useClick) t += _parse(_clickCtrl);
    return t;
  }

  double get _remaining => widget.totalAmount - _totalPaid;
  bool get _hasDebt => _useDebt && _remaining > 0.01;

  bool get _canConfirm {
    if (_hasDebt) return widget.selectedCustomer != null;
    return _remaining <= 0.01 || _totalPaid > 0;
  }

  bool _isActive(String key) {
    switch (key) {
      case 'cash':
        return _useCash;
      case 'terminal':
        return _useTerminal;
      case 'transfer':
        return _useTransfer;
      case 'click':
        return _useClick;
      default:
        return false;
    }
  }

  void _toggle(String key, bool val) {
    setState(() {
      switch (key) {
        case 'cash':
          _useCash = val;
          if (!val) _cashCtrl.clear();
          break;
        case 'terminal':
          _useTerminal = val;
          if (!val) _terminalCtrl.clear();
          break;
        case 'transfer':
          _useTransfer = val;
          if (!val) _transferCtrl.clear();
          break;
        case 'click':
          _useClick = val;
          if (!val) _clickCtrl.clear();
          break;
      }
    });
  }

  TextEditingController _ctrl(String key) {
    switch (key) {
      case 'cash':
        return _cashCtrl;
      case 'terminal':
        return _terminalCtrl;
      case 'transfer':
        return _transferCtrl;
      case 'click':
        return _clickCtrl;
      default:
        return _cashCtrl;
    }
  }

  void _onConfirm() async {
    setState(() => _isProcessing = true);
    final payments = <Map<String, dynamic>>[];

    void addIfActive(bool active, String type, TextEditingController ctrl) {
      if (active && ctrl.text.isNotEmpty) {
        payments.add({'paymentType': type, 'amount': _parse(ctrl)});
      }
    }

    addIfActive(_useCash, 'Cash', _cashCtrl);
    addIfActive(_useTerminal, 'Terminal', _terminalCtrl);
    addIfActive(_useTransfer, 'Transfer', _transferCtrl);
    addIfActive(_useClick, 'Click', _clickCtrl);

    try {
      widget.onConfirm(payments, _hasDebt);
    } catch (_) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
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

            // Sarlavha
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_outlined,
                      color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.paymentMethods,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      "${l10n.total}: ${NumberFormatter.formatDecimal(widget.totalAmount)} ${l10n.currencySom}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // To'lov usullari
            ..._paymentOptions.map((opt) => _PaymentMethodRow(
                  option: opt,
                  isActive: _isActive(opt.key),
                  controller: _ctrl(opt.key),
                  isDark: isDark,
                  onToggle: (val) => _toggle(opt.key, val),
                  onChanged: () => setState(() {}),
                )),

            // Qarzga olish
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                if (widget.selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.selectCustomerForDebtWarning),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                setState(() => _useDebt = !_useDebt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _useDebt
                      ? Colors.orange.withOpacity(0.1)
                      : isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _useDebt
                        ? Colors.orange.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.money_off_rounded,
                        size: 20,
                        color: _useDebt ? Colors.orange : Colors.grey[500]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.takeAsDebt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _useDebt ? Colors.orange : Colors.grey[600],
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _useDebt
                            ? Colors.orange
                            : Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _useDebt ? Icons.check_rounded : null,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                      label: l10n.total,
                      value:
                          "${NumberFormatter.formatDecimal(widget.totalAmount)} ${l10n.currencySom}"),
                  const SizedBox(height: 8),
                  _SummaryRow(
                      label: l10n.paid,
                      value:
                          "${NumberFormatter.formatDecimal(_totalPaid)} ${l10n.currencySom}",
                      valueColor: Colors.green),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(
                    label: _hasDebt ? l10n.onDebt : l10n.remaining,
                    value:
                        "${NumberFormatter.formatDecimal(_remaining)} ${l10n.currencySom}",
                    valueColor: _hasDebt
                        ? Colors.orange
                        : (_remaining <= 0 ? Colors.green : Colors.red),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tugmalar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
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
                    onPressed:
                        (_isProcessing || !_canConfirm) ? null : _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hasDebt ? Colors.orange : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _hasDebt ? l10n.takeAsDebt : l10n.confirm,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final _PaymentOption option;
  final bool isActive;
  final TextEditingController controller;
  final bool isDark;
  final Function(bool) onToggle;
  final VoidCallback onChanged;

  const _PaymentMethodRow({
    required this.option,
    required this.isActive,
    required this.controller,
    required this.isDark,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onToggle(!isActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? option.color.withOpacity(0.08)
                    : isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? option.color.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(option.icon,
                      size: 20,
                      color: isActive ? option.color : Colors.grey[500]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? option.color : Colors.grey[600],
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? option.color
                          : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: isActive
                        ? const Icon(Icons.check_rounded,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: l10n.enterQuantityHint,
                  suffixText: l10n.currencySom,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: option.color, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _PaymentOption(
      {required this.key,
      required this.label,
      required this.icon,
      required this.color});
}

Future<void> showContinuePaymentSheet(
  BuildContext context, {
  required String saleId,
  required double totalAmount,
  required Map<String, dynamic>? selectedCustomer,
  required Function(List<Map<String, dynamic>>, bool) onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ContinuePaymentSheet(
      saleId: saleId,
      totalAmount: totalAmount,
      selectedCustomer: selectedCustomer,
      onConfirm: onConfirm,
    ),
  );
}
