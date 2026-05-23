import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import 'quick_add_customer_sheet.dart';

class PaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;

  /// Fired on confirm. The third argument is the customer the sale should
  /// be attributed to — it may differ from [selectedCustomer] if the cashier
  /// created one inline from the debt row, so the caller MUST use this value
  /// (not its own snapshot) when creating the sale.
  final Function(List<Map<String, dynamic>>, bool, Map<String, dynamic>?)
      onConfirm;
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
  // Business logic preserved verbatim.
  bool _useCash = false;
  bool _useTerminal = false;
  bool _useTransfer = false;
  bool _useClick = false;
  bool _useDebt = false;

  /// Local, mutable copy of the selected customer. Starts as
  /// widget.selectedCustomer but can be replaced when the cashier creates a
  /// customer inline via the debt row. The widget field stays final.
  Map<String, dynamic>? _customer;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();
  final TextEditingController _clickController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.selectedCustomer;
  }

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  /// Open the inline "create customer" sheet. On success, adopt the new
  /// customer and turn the debt toggle on — the cashier opened this sheet
  /// precisely because they wanted a debt sale.
  Future<void> _addCustomerInline() async {
    final created = await showQuickAddCustomerSheet(context);
    if (created != null && mounted) {
      setState(() {
        _customer = created;
        _useDebt = true;
      });
    }
  }

  double get _totalPaid {
    double total = 0;
    if (_useCash) {
      total += double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0;
    }
    if (_useTerminal) {
      total +=
          double.tryParse(_terminalController.text.replaceAll(',', '.')) ?? 0;
    }
    if (_useTransfer) {
      total +=
          double.tryParse(_transferController.text.replaceAll(',', '.')) ?? 0;
    }
    if (_useClick) {
      total += double.tryParse(_clickController.text.replaceAll(',', '.')) ?? 0;
    }
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _totalPaid;
  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    if (_hasDebt) return _customer != null;
    return _totalPaid > 0 && _remainingAmount <= 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl2,
          left: AppSpacing.xl2,
          right: AppSpacing.xl2,
          top: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.paymentMethods,
                    style: AppTextStyles.titleMedium(),
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
                      NumberFormatter.formatDecimal(widget.totalAmount),
                      style: AppTextStyles.labelLarge().copyWith(
                        color: context.colors.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPaymentRow(
                context,
                l10n.cash,
                _useCash,
                (v) => setState(() => _useCash = v ?? false),
                _cashController,
                Icons.money,
                AppColors.success,
              ),
              _buildPaymentRow(
                context,
                l10n.bankCard,
                _useTerminal,
                (v) => setState(() => _useTerminal = v ?? false),
                _terminalController,
                Icons.credit_card,
                context.colors.brand,
              ),
              _buildPaymentRow(
                context,
                l10n.transfer,
                _useTransfer,
                (v) => setState(() => _useTransfer = v ?? false),
                _transferController,
                Icons.account_balance,
                AppColors.warning,
              ),
              _buildPaymentRow(
                context,
                l10n.click,
                _useClick,
                (v) => setState(() => _useClick = v ?? false),
                _clickController,
                Icons.phone_android,
                context.colors.brand,
              ),
              Divider(height: 30, color: context.colors.border),
              _buildSummary(context, l10n),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppPrimaryButton(
                      label: l10n.confirm,
                      isLoading: _isProcessing,
                      onPressed: (_isProcessing || !_canConfirm())
                          ? null
                          : _confirmAction,
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

  Widget _buildPaymentRow(
    BuildContext context,
    String title,
    bool value,
    Function(bool?) onChanged,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            title,
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: color),
          contentPadding: EdgeInsets.zero,
          activeColor: context.colors.brand,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(
              left: 40,
              bottom: AppSpacing.md,
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyLarge(),
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
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft),
      ),
      child: Column(
        children: [
          _summaryLine(
            l10n.paid,
            NumberFormatter.formatDecimal(_totalPaid),
            AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xs),
          _summaryLine(
            _hasDebt ? l10n.onDebt : l10n.remaining,
            NumberFormatter.formatDecimal(_remainingAmount),
            _remainingAmount > 0 ? AppColors.danger : AppColors.success,
          ),
          Divider(color: context.colors.border),
          // Debt toggle. When a customer is attached this is a normal
          // checkbox. When there isn't one, instead of greying the row out
          // (which used to dead-end the cashier), the subtitle becomes a
          // tappable "+ add customer" affordance that opens the inline
          // create sheet — so a debt sale can be completed without leaving
          // the payment dialog.
          if (_customer != null)
            CheckboxListTile(
              title: Text(
                l10n.takeAsDebt,
                style: AppTextStyles.bodyMedium(),
              ),
              subtitle: Text(
                _customer!['fullName']?.toString().isNotEmpty == true
                    ? _customer!['fullName'].toString()
                    : (_customer!['phone']?.toString() ?? ''),
                style: AppTextStyles.bodySmall(),
              ),
              value: _useDebt,
              onChanged: (v) => setState(() => _useDebt = v ?? false),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.brand,
            )
          else
            InkWell(
              onTap: _addCustomerInline,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: context.colors.brand,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.takeAsDebt,
                            style: AppTextStyles.bodyMedium(),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.addCustomerForDebtHint,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: context.colors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.brand,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium()),
        Text(
          value,
          style: AppTextStyles.bodyLarge().copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _confirmAction() {
    List<Map<String, dynamic>> payments = [];

    if (_useCash) {
      payments.add({
        'paymentType': 'Cash',
        'amount':
            double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0,
      });
    }
    if (_useTerminal) {
      payments.add({
        'paymentType': 'Card',
        'amount':
            double.tryParse(_terminalController.text.replaceAll(',', '.')) ?? 0,
      });
    }
    if (_useTransfer) {
      payments.add({
        'paymentType': 'Transfer',
        'amount':
            double.tryParse(_transferController.text.replaceAll(',', '.')) ?? 0,
      });
    }
    if (_useClick) {
      payments.add({
        'paymentType': 'Click',
        'amount':
            double.tryParse(_clickController.text.replaceAll(',', '.')) ?? 0,
      });
    }
    setState(() => _isProcessing = true);
    widget.onConfirm(payments, _hasDebt, _customer);
  }
}
