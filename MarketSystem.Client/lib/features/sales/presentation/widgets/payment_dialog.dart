import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
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
  // Business logic preserved verbatim.
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

  @override
  void dispose() {
    _cashController.dispose();
    _terminalController.dispose();
    _transferController.dispose();
    _clickController.dispose();
    super.dispose();
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
    if (_hasDebt) return widget.selectedCustomer != null;
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
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
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      NumberFormatter.formatDecimal(widget.totalAmount),
                      style: AppTextStyles.labelLarge().copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPaymentRow(
                l10n.cash,
                _useCash,
                (v) => setState(() => _useCash = v!),
                _cashController,
                Icons.money,
                AppColors.success,
              ),
              _buildPaymentRow(
                l10n.bankCard,
                _useTerminal,
                (v) => setState(() => _useTerminal = v!),
                _terminalController,
                Icons.credit_card,
                AppColors.brand,
              ),
              _buildPaymentRow(
                l10n.transfer,
                _useTransfer,
                (v) => setState(() => _useTransfer = v!),
                _transferController,
                Icons.account_balance,
                AppColors.warning,
              ),
              _buildPaymentRow(
                l10n.click,
                _useClick,
                (v) => setState(() => _useClick = v!),
                _clickController,
                Icons.phone_android,
                AppColors.brand,
              ),
              const Divider(height: 30, color: AppColors.border),
              _buildSummary(l10n),
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
          activeColor: AppColors.brand,
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
                  color: AppColors.textMuted,
                ),
                suffixText: l10n.currencySom,
                suffixStyle: AppTextStyles.bodySmall(),
                filled: true,
                fillColor: AppColors.inputFill,
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
                  borderSide: const BorderSide(
                    color: AppColors.brand,
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

  Widget _buildSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
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
          const Divider(color: AppColors.border),
          CheckboxListTile(
            title: Text(
              l10n.takeAsDebt,
              style: AppTextStyles.bodyMedium(),
            ),
            subtitle: Text(
              widget.selectedCustomer?['fullName'] ?? l10n.selectCustomer,
              style: AppTextStyles.bodySmall(),
            ),
            value: _useDebt,
            onChanged: widget.selectedCustomer == null
                ? null
                : (v) => setState(() => _useDebt = v!),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.brand,
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
    widget.onConfirm(payments, _hasDebt);
  }
}
