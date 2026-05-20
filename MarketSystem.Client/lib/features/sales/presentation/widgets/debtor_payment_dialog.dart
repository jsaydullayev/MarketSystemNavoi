// Bottom-sheet for accepting a debt payment from a debtor. Mirrors the
// "8.4 Qarz to'lov qabul qilish" page in the HTML demo: customer info row,
// amber-gradient balance card, TO'LANADI input, quick amounts, payment-type
// selector and a green "QABUL QILGANDAN KEYIN" preview, ending with
// AppPrimary + AppSecondary buttons.
//
// Public API (`showDebtorPaymentSheet` helper and `DebtorPaymentSheet` widget)
// is preserved so other screens that already call into this file keep working.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Helper that opens the sheet. Kept top-level so existing call sites that
/// used the legacy free function continue to compile unchanged.
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
  late final TextEditingController _amountController;
  // Cash is pre-selected so a tap on "Tasdiqlash" works in one go, matching
  // the demo. The user can still switch to Karta. Keeping it nullable would
  // force the cashier to make two taps every time.
  String _selectedPaymentType = 'Cash';
  bool _isLoading = false;

  double get _remainingDebt =>
      (widget.debtor['remainingDebt'] as num?)?.toDouble() ?? 0.0;

  double get _entered =>
      double.tryParse(
        _amountController.text.replaceAll(',', '.').replaceAll(' ', ''),
      ) ??
      0;

  @override
  void initState() {
    super.initState();
    final v = _remainingDebt;
    _amountController = TextEditingController(
      text: v == v.truncateToDouble() ? v.toInt().toString() : v.toString(),
    );
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickAdd(double delta) {
    final next = (_entered + delta).clamp(0, double.infinity);
    _setAmount(next.toDouble());
  }

  void _setAmount(double value) {
    final str = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    _amountController.text = str;
  }

  Future<void> _onConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final amount = _entered;
    if (amount <= 0) {
      _showSnack(messenger, l10n.enterValidAmount, isError: true);
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

      if (debtorSales.isEmpty) {
        throw Exception(l10n.noDebtSalesFound);
      }

      await salesService.addPayment(
        saleId: debtorSales[0]['id'],
        paymentType: _selectedPaymentType,
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          messenger,
          '${l10n.paymentSuccess}: ${NumberFormatter.formatDecimal(amount)} ${l10n.currencySom}',
          isError: false,
        );
        widget.onPaymentSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(messenger, '${l10n.error}: $e', isError: true);
      }
    }
  }

  void _showSnack(ScaffoldMessengerState messenger, String msg,
      {required bool isError}) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final remaining = _remainingDebt;
    final entered = _entered;
    final newBalance =
        (remaining - entered).clamp(0, double.infinity).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        0,
        AppSpacing.xl2,
        AppSpacing.xl3 + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                    top: AppSpacing.lg, bottom: AppSpacing.xl2),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            _CustomerRow(debtor: widget.debtor),
            const SizedBox(height: AppSpacing.lg),

            _BalanceCard(remaining: remaining),
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
            const SizedBox(height: AppSpacing.lg),

            _QuickAmounts(
              remaining: remaining,
              onAdd: _applyQuickAdd,
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

            _PayMethodGrid(
              selected: _selectedPaymentType,
              onChanged: (v) => setState(() => _selectedPaymentType = v),
            ),
            const SizedBox(height: AppSpacing.xl),

            _NewBalanceCard(
              newBalance: newBalance,
              customerName:
                  widget.debtor['customerName'] ?? l10n.noCustomer,
              currencyLabel: l10n.currencySom,
            ),
            const SizedBox(height: AppSpacing.xl2),

            AppPrimaryButton(
              label: l10n.pay,
              onPressed: _isLoading ? null : _onConfirm,
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
  const _CustomerRow({required this.debtor});
  final dynamic debtor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customerName = (debtor['customerName'] as String?) ?? l10n.noCustomer;
    final phone = debtor['customerPhone'] as String?;
    final initial = customerName.isNotEmpty
        ? customerName.characters.first.toUpperCase()
        : '?';
    final avatarColor = CustomerAvatarPalette.pick(customerName);

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
            decoration:
                BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.labelLarge().copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: AppTextStyles.labelLarge(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber gradient balance card (matches "8.4" balance-card pattern).
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.remaining});
  final double remaining;

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
          _BalanceRow(
              label: l10n.totalDebt,
              value: NumberFormatter.format(remaining),
              currency: l10n.currencySom),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),
          _BalanceRow(
            label: l10n.remainingDebt,
            value: NumberFormatter.format(remaining),
            currency: l10n.currencySom,
            isBig: true,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
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
        border:
            Border.all(color: context.colors.brand.withValues(alpha: 0.3)),
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

class _QuickAmounts extends StatelessWidget {
  const _QuickAmounts({
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

/// Two-column pay-method grid (Naqd / Karta) — Naqd is selected by default,
/// the legacy four-method list (Transfer / Click) was dropped to match the
/// demo. Backend still accepts only the two canonical values: 'Cash' and
/// 'Terminal'.
class _PayMethodGrid extends StatelessWidget {
  const _PayMethodGrid({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methods = <_PayMethod>[
      _PayMethod(value: 'Cash', label: l10n.cash, icon: Icons.payments_rounded),
      _PayMethod(
          value: 'Terminal',
          label: l10n.card,
          icon: Icons.credit_card_rounded),
    ];
    return Row(
      children: [
        for (var i = 0; i < methods.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(methods[i].value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg + 2),
                decoration: BoxDecoration(
                  color: selected == methods[i].value
                      ? context.colors.brand
                      : context.colors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      methods[i].icon,
                      size: 22,
                      color: selected == methods[i].value
                          ? Colors.white
                          : context.colors.brand,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      methods[i].label,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected == methods[i].value
                            ? Colors.white
                            : context.colors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PayMethod {
  final String value;
  final String label;
  final IconData icon;
  const _PayMethod(
      {required this.value, required this.label, required this.icon});
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
