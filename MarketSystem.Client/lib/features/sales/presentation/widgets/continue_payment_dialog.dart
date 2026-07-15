import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/input_formatters.dart';
import 'package:provider/provider.dart';

import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import 'quick_add_customer_sheet.dart';

/// Modal bottom sheet for capturing payment on a "continue sale" flow.
///
/// Visually aligned with the already-migrated `PaymentDialog` and the
/// demo's `#page-pos-pay`: payment-method selector cards, optional amount
/// inputs with brand-orange focus, a debt toggle, a totals summary, and
/// `AppPrimaryButton` + `AppSecondaryButton` actions.
///
/// Business logic preserved verbatim: per-method controllers, parse-with-
/// comma fallback, debt requires a selected customer, confirm only when
/// the remaining balance reconciles.
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

  /// Local, mutable customer. Starts as widget.selectedCustomer but can be
  /// replaced when the cashier creates one inline from the debt toggle.
  Map<String, dynamic>? _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.selectedCustomer;
  }

  /// Create a customer inline, then attach it to this (already-existing)
  /// sale on the server so the debt the backend creates from the unpaid
  /// remainder lands on the right customer.
  Future<void> _addCustomerInline() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final created = await showQuickAddCustomerSheet(context);
    if (created == null || !mounted) return;

    final id = created['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await SalesService(
        authProvider: auth,
      ).updateSaleCustomer(saleId: widget.saleId, customerId: id);
      if (!mounted) return;
      setState(() {
        _customer = created;
        _useDebt = true;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

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
    if (_hasDebt) return _customer != null;
    return _remaining <= 0.01 || _totalPaid > 0;
  }

  void _onConfirm() {
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
    } catch (e, st) {
      debugPrint('ContinuePaymentSheet._confirm error: $e\n$st');
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl3,
        0,
        AppSpacing.xl3,
        AppSpacing.xl3 + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle.
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl2,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title with brand-tinted icon and total chip.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.brandLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: context.colors.brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Text(
                      l10n.paymentMethods,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '${NumberFormatter.formatDecimal(widget.totalAmount)} ${l10n.currencySom}',
                    style: AppTextStyles.labelLarge().copyWith(
                      color: context.colors.brand,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Payment-method selector cards.
            _PaymentMethodRow(
              label: l10n.cash,
              icon: Icons.payments_outlined,
              isActive: _useCash,
              controller: _cashCtrl,
              onToggle: (v) => setState(() {
                _useCash = v;
                if (!v) _cashCtrl.clear();
              }),
              onChanged: () => setState(() {}),
            ),
            _PaymentMethodRow(
              label: l10n.bankCard,
              icon: Icons.credit_card_outlined,
              isActive: _useTerminal,
              controller: _terminalCtrl,
              onToggle: (v) => setState(() {
                _useTerminal = v;
                if (!v) _terminalCtrl.clear();
              }),
              onChanged: () => setState(() {}),
            ),
            _PaymentMethodRow(
              label: l10n.transfer,
              icon: Icons.account_balance_outlined,
              isActive: _useTransfer,
              controller: _transferCtrl,
              onToggle: (v) => setState(() {
                _useTransfer = v;
                if (!v) _transferCtrl.clear();
              }),
              onChanged: () => setState(() {}),
            ),
            _PaymentMethodRow(
              label: l10n.click,
              icon: Icons.phone_android_outlined,
              isActive: _useClick,
              controller: _clickCtrl,
              onToggle: (v) => setState(() {
                _useClick = v;
                if (!v) _clickCtrl.clear();
              }),
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Debt toggle. With a customer attached this just flips the
            // toggle. Without one, instead of dead-ending with a warning
            // snack, tapping opens the inline "create customer" sheet so
            // the debt sale can be completed without leaving this sheet.
            GestureDetector(
              onTap: () {
                if (_customer == null) {
                  _addCustomerInline();
                  return;
                }
                setState(() => _useDebt = !_useDebt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: _useDebt
                      ? context.colors.brandLight
                      : context.colors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  border: Border.all(
                    color: _useDebt ? context.colors.brand : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _customer == null
                          ? Icons.person_add_alt_1_rounded
                          : Icons.money_off_rounded,
                      size: 20,
                      color: _useDebt
                          ? context.colors.brand
                          : context.colors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.takeAsDebt,
                            style: AppTextStyles.bodyMedium().copyWith(
                              fontWeight: FontWeight.w700,
                              color: _useDebt
                                  ? context.colors.brand
                                  : context.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _customer == null
                                ? l10n.addCustomerForDebtHint
                                : (_customer!['fullName']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? _customer!['fullName'].toString()
                                      : _customer!['phone']?.toString() ?? ''),
                            style: AppTextStyles.bodySmall().copyWith(
                              color: _customer == null
                                  ? context.colors.brand
                                  : context.colors.textSecondary,
                              fontWeight: _customer == null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_customer == null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.brand,
                      )
                    else
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _useDebt
                              ? context.colors.brand
                              : context.colors.border,
                          shape: BoxShape.circle,
                        ),
                        child: _useDebt
                            ? const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Totals summary.
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.borderSoft),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: l10n.total,
                    value:
                        '${NumberFormatter.formatDecimal(widget.totalAmount)} ${l10n.currencySom}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummaryRow(
                    label: l10n.paid,
                    value:
                        '${NumberFormatter.formatDecimal(_totalPaid)} ${l10n.currencySom}',
                    valueColor: AppColors.success,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Divider(height: 1, color: context.colors.border),
                  ),
                  _SummaryRow(
                    label: _hasDebt ? l10n.onDebt : l10n.remaining,
                    value:
                        '${NumberFormatter.formatDecimal(_remaining)} ${l10n.currencySom}',
                    valueColor: _hasDebt
                        ? context.colors.brand
                        : (_remaining <= 0
                              ? AppColors.success
                              : AppColors.danger),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Footer buttons — cancel + confirm.
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    label: _hasDebt ? l10n.takeAsDebt : l10n.confirm,
                    isLoading: _isProcessing,
                    onPressed: (_isProcessing || !_canConfirm)
                        ? null
                        : _onConfirm,
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

/// Single payment-method row — toggle card + optional amount input.
/// Active state uses brand-orange tints; inactive shows neutral grey.
class _PaymentMethodRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;

  const _PaymentMethodRow({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onToggle(!isActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? context.colors.brandLight
                    : context.colors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
                border: Border.all(
                  color: isActive ? context.colors.brand : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive
                        ? context.colors.brand
                        : context.colors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? context.colors.brand
                            : context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.colors.brand
                          : context.colors.border,
                      shape: BoxShape.circle,
                    ),
                    child: isActive
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: const [NoLeadingZeroFormatter()],
                autofocus: true,
                style: AppTextStyles.bodyLarge().copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: l10n.enterAmount,
                  hintStyle: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.textMuted,
                  ),
                  suffixText: l10n.currencySom,
                  suffixStyle: AppTextStyles.bodySmall(),
                  filled: true,
                  fillColor: context.colors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    borderSide: BorderSide(
                      color: context.colors.brand,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
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
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            color: context.colors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.labelLarge().copyWith(
                  fontSize: 15,
                  color: valueColor ?? context.colors.text,
                )
              : AppTextStyles.bodySmall().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? context.colors.text,
                ),
        ),
      ],
    );
  }
}

/// Convenience launcher — mirrors the public function from the original
/// file so existing call sites in `ContinueSaleScreen` don't have to change.
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
