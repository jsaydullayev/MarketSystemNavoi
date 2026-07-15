import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../data/services/customer_service.dart';
import 'sale_customer_sheet.dart';

class PaymentDialog extends StatefulWidget {
  final String saleId;
  final double totalAmount;
  final Map<String, dynamic>? selectedCustomer;

  /// Fired on confirm. The third argument is the customer the sale should
  /// be attributed to — it may differ from [selectedCustomer] if the cashier
  /// created one inline from the debt row, so the caller MUST use this value
  /// (not its own snapshot) when creating the sale. The fourth argument is the
  /// applied chegirma (skidka) amount — 0 when none — which the caller must
  /// send to the backend (setSaleDiscount) AFTER items and BEFORE payments so
  /// the payments settle the discounted total.
  final Function(
    List<Map<String, dynamic>>,
    bool,
    Map<String, dynamic>?,
    double,
  )
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

  /// Chegirma (skidka) yoqilganmi. Yoqilganda summasi _discountController'dan
  /// olinadi va to'lanadigan hisobdan (widget.totalAmount) ayriladi.
  bool _useDiscount = false;

  /// Local, mutable copy of the selected customer. Starts as
  /// widget.selectedCustomer but can be replaced when the cashier creates a
  /// customer inline via the debt row. The widget field stays final.
  Map<String, dynamic>? _customer;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _transferController = TextEditingController();
  final TextEditingController _clickController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

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
    _discountController.dispose();
    super.dispose();
  }

  /// Open the customer picker: a list of existing customers to choose from,
  /// with a "+" in its top-right to add a new one. Picking a customer attaches
  /// it and turns the debt toggle on — the cashier opened this precisely
  /// because they want a debt sale.
  Future<void> _selectCustomer() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    List<dynamic> customers;
    try {
      customers = await CustomerService(authProvider: auth).getAllCustomers();
    } catch (_) {
      customers = [];
    }
    if (!mounted) return;
    showCustomerSelectionSheet(
      context,
      customers: customers,
      selectedId: _customer?['id']?.toString(),
      onSelected: (c) {
        setState(() {
          _customer = c;
          _useDebt = true;
        });
      },
    );
  }

  /// Chegirma (skidka) summasi. O'chirilgan bo'lsa 0. Jami summadan (cart)
  /// oshmaydi — ortiqcha kiritilsa jami summagacha qisqartiriladi, shunda
  /// to'lanadigan hisob hech qachon manfiy bo'lmaydi.
  double get _discount {
    if (!_useDiscount) return 0;
    final v = _parseField(_discountController.text);
    if (v > widget.totalAmount) return widget.totalAmount;
    return v;
  }

  /// Chegirmadan keyingi to'lanadigan hisob (bill). Barcha to'lov/qarz
  /// hisob-kitobi shu summaga nisbatan olib boriladi, spiskadagi tovar
  /// narxlariga esa tegilmaydi.
  double get _effectiveTotal {
    final net = widget.totalAmount - _discount;
    return net < 0 ? 0 : net;
  }

  /// "Hammasi" — pour the whole (discounted) bill into one payment method and
  /// clear the others, so the cashier can settle in a single tap.
  void _fillAll(TextEditingController target) {
    // Maydonlardagi ko'rinish bilan bir xil bo'lishi uchun xonalarga ajratamiz.
    final full = ThousandsSeparatorFormatter.group(_plain(_effectiveTotal));
    setState(() {
      _cashController.text = identical(target, _cashController) ? full : '';
      _terminalController.text =
          identical(target, _terminalController) ? full : '';
      _transferController.text =
          identical(target, _transferController) ? full : '';
      _clickController.text = identical(target, _clickController) ? full : '';
    });
  }

  static String _plain(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  /// AUDIT-3 — sum the individual payment-method amounts. Each field is
  /// parsed defensively: `tryParse` falls back to 0 on garbage input,
  /// non-finite values (NaN, +/-Infinity from a paste of "1e9999") fold
  /// to 0 as well so they can't poison the total or the can-confirm
  /// check below.
  double get _totalPaid {
    double total = 0;
    if (_useCash) total += _parseField(_cashController.text);
    if (_useTerminal) total += _parseField(_terminalController.text);
    if (_useTransfer) total += _parseField(_transferController.text);
    if (_useClick) total += _parseField(_clickController.text);
    return total;
  }

  /// Parse a single payment field. Out-of-range and non-finite inputs
  /// resolve to 0 so the confirm guard treats them as "not paid yet"
  /// instead of letting an `Infinity` slip through to the backend.
  double _parseField(String raw) {
    // Maydonlar xonalarga ajratilgan holda ko'rsatiladi ("140 000") — raqamga
    // aylantirishdan oldin guruh bo'shliqlarini olib tashlaymiz.
    final v = double.tryParse(ThousandsSeparatorFormatter.unformat(raw)) ?? 0;
    if (!v.isFinite || v < 0) return 0;
    return v;
  }

  // Qolgan summa chegirilgan hisobga nisbatan hisoblanadi (spiska summasiga
  // emas), shunda to'lovlar aynan chegirmadan keyingi hisobni yopadi.
  double get _remainingAmount => _effectiveTotal - _totalPaid;
  bool get _hasDebt => _useDebt && _remainingAmount > 0.01;

  bool _canConfirm() {
    // AUDIT-3 — explicit finite check belt-and-braces: if a future
    // refactor of _totalPaid ever surfaces a non-finite value, refuse
    // to enable the confirm button instead of crashing the backend.
    if (!_totalPaid.isFinite || _totalPaid < 0) return false;
    // Chegirilgan hisobdan ortiq to'lov qabul qilinmaydi — backend baribir
    // "qoldiq summadan oshib ketdi" deb rad etadi, shuning uchun tugmani
    // shu yerdayoq bloklaymiz.
    if (_totalPaid > _effectiveTotal + 0.01) return false;
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
            top: Radius.circular(AppRadius.xl2),
          ),
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
                  Text(l10n.paymentMethods, style: AppTextStyles.titleMedium()),
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
              _buildDiscountPanel(context, l10n),
              const SizedBox(height: AppSpacing.lg),
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
            padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsSeparatorFormatter()],
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
                const SizedBox(width: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => _fillAll(controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.brand,
                    side: BorderSide(color: context.colors.brand),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.payFullAmount,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: context.colors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Part 2 — "Skidka bo'limi". On/off toggle; yoqilganda chegirma summasi
  /// kiritiladi. Spiskadagi tovar narxlariga tegmaydi — faqat to'lanadigan
  /// hisobni kamaytiradi (breakdown pastdagi xulosada ko'rinadi).
  Widget _buildDiscountPanel(BuildContext context, AppLocalizations l10n) {
    final active = _useDiscount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: active
              ? AppColors.warning.withValues(alpha: 0.5)
              : context.colors.borderSoft,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Chegirma (skidka)',
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _useDiscount,
                activeThumbColor: AppColors.warning,
                onChanged: (v) => setState(() {
                  _useDiscount = v;
                  if (!v) _discountController.clear();
                }),
              ),
            ],
          ),
          if (_useDiscount) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsSeparatorFormatter()],
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyLarge(),
              decoration: InputDecoration(
                hintText: 'Chegirma summasi',
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
                  borderSide: const BorderSide(
                    color: AppColors.warning,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, AppLocalizations l10n) {
    final hasDiscount = _discount > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft),
      ),
      child: Column(
        children: [
          // Chegirma qo'llanganda: spiska summasi → chegirma → to'lanadigan
          // hisob (net). Chegirma yo'q bo'lsa bu qatorlar ko'rsatilmaydi.
          if (hasDiscount) ...[
            _summaryLine(
              'Spiska summasi',
              NumberFormatter.formatDecimal(widget.totalAmount),
              context.colors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            _summaryLine(
              'Chegirma',
              '− ${NumberFormatter.formatDecimal(_discount)}',
              AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.xs),
            _summaryLine(
              'To\'lanadigan hisob',
              NumberFormatter.formatDecimal(_effectiveTotal),
              context.colors.brand,
            ),
            Divider(color: context.colors.border),
          ],
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
              title: Text(l10n.takeAsDebt, style: AppTextStyles.bodyMedium()),
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
              onTap: _selectCustomer,
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
                            l10n.selectCustomer,
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

    // _parseField guruh bo'shliqlarini tozalaydi — maydonda "140 000" yozilgan
    // bo'lsa ham backend'ga 140000 ketadi.
    if (_useCash) {
      payments.add({
        'paymentType': 'Cash',
        'amount': _parseField(_cashController.text),
      });
    }
    if (_useTerminal) {
      payments.add({
        'paymentType': 'Card',
        'amount': _parseField(_terminalController.text),
      });
    }
    if (_useTransfer) {
      payments.add({
        'paymentType': 'Transfer',
        'amount': _parseField(_transferController.text),
      });
    }
    if (_useClick) {
      payments.add({
        'paymentType': 'Click',
        'amount': _parseField(_clickController.text),
      });
    }
    setState(() => _isProcessing = true);
    widget.onConfirm(payments, _hasDebt, _customer, _discount);
  }
}
