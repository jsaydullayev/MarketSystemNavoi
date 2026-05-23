import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/error_parser.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/services/debt_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
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
  double get _entered =>
      double.tryParse(_amountController.text.replaceAll(',', '.').replaceAll(' ', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    final val = _remaining;
    _amountController.text =
        val == val.truncateToDouble() ? val.toInt().toString() : val.toString();
    _amountController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickAmount(double delta) {
    final next = (_entered + delta).clamp(0, double.infinity);
    _setAmount(next.toDouble());
  }

  void _setAmount(double value) {
    final str = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    _amountController.text = str;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);

    final amount = _entered;
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
            backgroundColor: AppColors.success,
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
    final l10n = AppLocalizations.of(context)!;
    final remaining = _remaining;
    final entered = _entered;
    final isOverpay = entered > remaining && entered > 0;
    final newBalance = (remaining - entered).clamp(0, double.infinity).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.xl,
        AppSpacing.xl2,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl3,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            _CustomerRow(name: widget.customerName),
            const SizedBox(height: AppSpacing.lg),
            _BalanceCard(remaining: remaining, dueLabel: l10n.remainingDebt),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "MIJOZ QANCHA TO'LAYDI?",
              style: AppTextStyles.caption().copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PayAmountInput(
              controller: _amountController,
              currencyLabel: l10n.currencySom,
            ),
            if (isOverpay) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  border:
                      Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.payingTooMuchWarning(
                            NumberFormatter.format(entered - remaining)),
                        style: AppTextStyles.bodySmall()
                            .copyWith(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.danger, size: 16),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _QuickAmountButtons(
              remaining: remaining,
              onAdd: _applyQuickAmount,
              onSet: _setAmount,
              onClear: () => _amountController.text = '0',
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "TO'LOV USULI",
              style: AppTextStyles.caption().copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PaymentTypeSelector(
              selected: _selectedPaymentType,
              onChanged: (val) => setState(() => _selectedPaymentType = val),
            ),
            const SizedBox(height: AppSpacing.xl),
            _NewBalanceCard(
              newBalance: newBalance,
              customerName: widget.customerName,
              currencyLabel: l10n.currencySom,
            ),
            const SizedBox(height: AppSpacing.xl2),
            AppPrimaryButton(
              label: _isLoading
                  ? l10n.processPayment
                  : '${l10n.processPayment} · ${NumberFormatter.format(entered)} ${l10n.currencySom}',
              onPressed: _isLoading ? null : _submit,
              icon: Icons.check_rounded,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final color = CustomerAvatarPalette.pick(name);
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.borderSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.labelLarge().copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.labelLarge(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber gradient balance card showing current debt + how much is due.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.remaining, required this.dueLabel});
  final double remaining;
  final String dueLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _Row(label: l10n.totalDebt, value: NumberFormatter.format(remaining), currency: l10n.currencySom),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),
          _Row(
            label: dueLabel,
            value: NumberFormatter.format(remaining),
            currency: l10n.currencySom,
            isBig: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.currency,
    this.isBig = false,
  });
  final String label;
  final String value;
  final String currency;
  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isBig ? 14 : 13,
          ),
        ),
        Text(
          '$value $currency',
          style: (isBig
                  ? AppTextStyles.titleLarge()
                  : AppTextStyles.bodyMedium())
              .copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _PayAmountInput extends StatelessWidget {
  const _PayAmountInput(
      {required this.controller, required this.currencyLabel});
  final TextEditingController controller;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.brand.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TO'LANADI",
            style: AppTextStyles.caption().copyWith(
              color: context.colors.brandDark,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppTextStyles.displayMedium().copyWith(
                    color: context.colors.brandDark,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  currencyLabel,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.brandDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButtons extends StatelessWidget {
  const _QuickAmountButtons({
    required this.remaining,
    required this.onAdd,
    required this.onSet,
    required this.onClear,
  });

  final double remaining;
  final ValueChanged<double> onAdd;
  final ValueChanged<double> onSet;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _QuickButton(label: '+10K', onTap: () => onAdd(10000)),
        _QuickButton(label: '+50K', onTap: () => onAdd(50000)),
        _QuickButton(label: '+100K', onTap: () => onAdd(100000)),
        _QuickButton(label: 'Yarim', onTap: () => onSet(remaining / 2)),
        _QuickButton(label: 'Hammasi', onTap: () => onSet(remaining)),
        _QuickButton(label: 'Tozalash', onTap: onClear, isDanger: true),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final fg = isDanger ? AppColors.danger : context.colors.text;
    final bg = isDanger ? AppColors.dangerLight : context.colors.inputFill;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _NewBalanceCard extends StatelessWidget {
  const _NewBalanceCard({
    required this.newBalance,
    required this.customerName,
    required this.currencyLabel,
  });
  final double newBalance;
  final String customerName;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QABUL QILGANDAN KEYIN',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.success,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${NumberFormatter.format(newBalance)} $currencyLabel',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColors.success,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            newBalance > 0
                ? '${l10n.remaining} · $customerName'
                : "Qarz to'liq yopiladi",
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColors.success.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
