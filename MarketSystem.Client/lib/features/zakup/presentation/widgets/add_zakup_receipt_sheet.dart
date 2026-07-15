import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../data/services/zakup_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../design/widgets/app_text_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../suppliers/domain/entities/supplier_entity.dart';
import 'zakup_supplier_picker.dart';

/// One product line in the receipt basket (mutable — qty/cost can be edited).
class ReceiptLine {
  final String productId;
  final String productName;
  double quantity;
  double costPrice;

  ReceiptLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
  });

  double get total => quantity * costPrice;
}

/// Multi-item goods-receipt (priyomka) sheet: pick a supplier (optional), add
/// several product lines to a basket, enter the paid amount, and submit the
/// whole delivery as one receipt.
class AddZakupReceiptSheet extends StatefulWidget {
  final List<dynamic> products;

  const AddZakupReceiptSheet({super.key, required this.products});

  /// Returns `true` via [Navigator.pop] when a receipt was created. Shown as a
  /// centered dialog (not a bottom sheet).
  static Future<bool?> show(
    BuildContext context, {
    required List<dynamic> products,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: AddZakupReceiptSheet(products: products),
      ),
    );
  }

  @override
  State<AddZakupReceiptSheet> createState() => _AddZakupReceiptSheetState();
}

enum _View { basket, pickProduct, lineInput }

class _AddZakupReceiptSheetState extends State<AddZakupReceiptSheet> {
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  // Empty by default so the "0" hint shows as a placeholder — typing a number
  // never leaves a leading zero (e.g. "0500"). Empty parses as 0 paid.
  final _paidCtrl = TextEditingController();

  final List<ReceiptLine> _basket = [];
  List<dynamic> _filtered = [];
  SupplierEntity? _supplier;

  _View _view = _View.basket;
  dynamic _pendingProduct; // product chosen in pickProduct, awaiting qty/cost
  int? _editingIndex; // basket index being edited (null = new line)
  bool _submitting = false;

  // Inline validation errors shown INSIDE the card at the relevant section
  // (not a SnackBar, which renders behind the centered dialog).
  String? _lineError; // shown in the line-input view (qty/cost)
  String? _submitError; // shown in the basket view near "Qabul qilish"

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
    _searchCtrl.addListener(_filterProducts);
    _qtyCtrl.addListener(() => setState(() => _lineError = null));
    _costCtrl.addListener(() => setState(() => _lineError = null));
    _paidCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _invoiceCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  // ── derived ───────────────────────────────────────────────────────────────
  double get _grandTotal => _basket.fold(0.0, (s, l) => s + l.total);
  double get _paid =>
      double.tryParse(_paidCtrl.text.trim().replaceAll(',', '.')) ?? 0;
  double get _remaining => (_grandTotal - _paid).clamp(0, double.infinity);
  double get _lineTotal {
    final q = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final c = double.tryParse(_costCtrl.text.replaceAll(',', '.')) ?? 0;
    return q * c;
  }

  String _statusKey() {
    if (_paid <= 0) return 'unpaid';
    if (_paid >= _grandTotal && _grandTotal > 0) return 'paid';
    return 'partial';
  }

  // ── actions ───────────────────────────────────────────────────────────────
  void _filterProducts() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.products
          : widget.products
                .where((p) => (p['name'] ?? '').toLowerCase().contains(q))
                .toList();
    });
  }

  void _startAddLine() {
    setState(() {
      _searchCtrl.clear();
      _filtered = widget.products;
      _view = _View.pickProduct;
    });
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _pendingProduct = product;
      _editingIndex = null;
      _qtyCtrl.text = '';
      _costCtrl.text = (product['costPrice'] != null &&
              (product['costPrice'] as num) > 0)
          ? (product['costPrice'] as num).toString()
          : '';
      _view = _View.lineInput;
    });
  }

  void _editLine(int index) {
    final line = _basket[index];
    setState(() {
      _pendingProduct = {'id': line.productId, 'name': line.productName};
      _editingIndex = index;
      _qtyCtrl.text = _fmtNum(line.quantity);
      _costCtrl.text = _fmtNum(line.costPrice);
      _view = _View.lineInput;
    });
  }

  void _commitLine() {
    final l10n = AppLocalizations.of(context)!;
    final qty = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.'));
    final cost = double.tryParse(_costCtrl.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0 || cost == null || cost < 0) {
      setState(() => _lineError = l10n.fillAmountAndPrice);
      return;
    }
    setState(() {
      if (_editingIndex != null) {
        _basket[_editingIndex!]
          ..quantity = qty
          ..costPrice = cost;
      } else {
        _basket.add(
          ReceiptLine(
            productId: _pendingProduct['id'].toString(),
            productName: _pendingProduct['name']?.toString() ?? '',
            quantity: qty,
            costPrice: cost,
          ),
        );
      }
      _pendingProduct = null;
      _editingIndex = null;
      _lineError = null;
      _submitError = null;
      _view = _View.basket;
    });
  }

  Future<void> _pickSupplier() async {
    final picked = await ZakupSupplierPicker.show(context, selected: _supplier);
    if (!mounted || picked == null) return; // dismissed / torn down
    setState(() => _supplier = picked.clearsSelection ? null : picked.supplier);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_basket.isEmpty) {
      setState(() => _submitError = l10n.basketEmpty);
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await ZakupService(authProvider: auth).createReceipt(
        supplierId: _supplier?.id,
        invoiceNumber: _invoiceCtrl.text.trim(),
        paidAmount: _paid,
        items: _basket
            .map(
              (l) => {
                'productId': l.productId,
                'quantity': l.quantity,
                'costPrice': l.costPrice,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = '${l10n.errorOccurred}: $e';
      });
    }
  }

  static String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: Container(
        height: size.height * 0.82,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (_view) {
          _View.basket => _buildBasket(),
          _View.pickProduct => _buildProductPicker(),
          _View.lineInput => _buildLineInput(),
        },
      ),
    );
  }

  // ── basket view: two panels inside one card ──────────────────────────────
  Widget _buildBasket() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const _Handle(),
        _Header(title: l10n.newReceipt, onClose: () => Navigator.pop(context)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl2,
                    0,
                    AppSpacing.xl2,
                    AppSpacing.xl2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _panel1(l10n, bounded: true)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: _panel2(l10n, bounded: true)),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl2,
                  0,
                  AppSpacing.xl2,
                  AppSpacing.xl2,
                ),
                child: Column(
                  children: [
                    _panel1(l10n, bounded: false),
                    const SizedBox(height: AppSpacing.lg),
                    _panel2(l10n, bounded: false),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _panelBox({required Widget child}) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.colors.border),
    ),
    child: child,
  );

  // Panel 1 — yetkazib beruvchi + nakladnoy + savat + mahsulot qo'shish.
  Widget _panel1(AppLocalizations l10n, {required bool bounded}) {
    final basket = _basket.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
            child: Center(
              child: Text(
                l10n.basketEmpty,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ),
          )
        : ListView(
            shrinkWrap: !bounded,
            physics: bounded
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: _basket
                .asMap()
                .entries
                .map(
                  (e) => _BasketRow(
                    line: e.value,
                    onEdit: () => _editLine(e.key),
                    onRemove: () => setState(() => _basket.removeAt(e.key)),
                  ),
                )
                .toList(),
          );

    return _panelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _SupplierField(supplier: _supplier, onTap: _pickSupplier),
          const SizedBox(height: AppSpacing.lg),
          AppTextInput(
            label: l10n.invoiceNumberLabel,
            hint: l10n.invoiceNumberHint,
            controller: _invoiceCtrl,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.basketTitle.toUpperCase(),
                style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
              ),
              Text(
                l10n.itemsCountLabel(_basket.length),
                style: AppTextStyles.caption().copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (bounded) Expanded(child: basket) else basket,
          const SizedBox(height: AppSpacing.md),
          _AddItemButton(label: l10n.addProductToBasket, onTap: _startAddLine),
        ],
      ),
    );
  }

  // Panel 2 — jami summa (tepada) + to'lov bloki (pastda) + qabul qilish.
  Widget _panel2(AppLocalizations l10n, {required bool bounded}) {
    return _panelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            l10n.grandTotalLabel.toUpperCase(),
            style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${NumberFormatter.format(_grandTotal)} ${l10n.currencySom}',
              style: AppTextStyles.titleLarge().copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: context.colors.brand,
              ),
            ),
          ),
          if (bounded)
            const Spacer()
          else
            const SizedBox(height: AppSpacing.xl2),
          _PaymentSection(
            paidCtrl: _paidCtrl,
            grandTotal: _grandTotal,
            remaining: _remaining,
            statusKey: _statusKey(),
            onMarkPaid: () => _paidCtrl.text = _fmtNum(_grandTotal),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineError(message: _submitError!),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: l10n.receiveGoods,
            icon: Icons.download_rounded,
            isLoading: _submitting,
            onPressed: _basket.isNotEmpty && !_submitting ? _submit : null,
          ),
        ],
      ),
    );
  }

  // ── product picker view ───────────────────────────────────────────────────
  Widget _buildProductPicker() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const _Handle(),
        _Header(
          title: l10n.selectProduct,
          onBack: () => setState(() => _view = _View.basket),
          onClose: () => Navigator.pop(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2,
            0,
            AppSpacing.xl2,
            AppSpacing.lg,
          ),
          child: AppTextInput(
            hint: l10n.searchProduct,
            controller: _searchCtrl,
            prefixIcon: Icons.search_rounded,
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.productNotFound,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl2,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
                    return _ProductPickRow(
                      name: p['name']?.toString() ?? l10n.unknown,
                      subtitle:
                          '${_fmtNum(qty)} ${l10n.piece}',
                      onTap: () => _selectProduct(p),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── line input view ───────────────────────────────────────────────────────
  Widget _buildLineInput() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Handle(),
        _Header(
          title: _pendingProduct?['name']?.toString() ?? l10n.zakup,
          onBack: () => setState(() => _view = _View.basket),
          onClose: () => Navigator.pop(context),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl2,
              AppSpacing.xs,
              AppSpacing.xl2,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextInput(
                        label: l10n.number,
                        hint: '0',
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [NoLeadingZeroFormatter()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextInput(
                        label: l10n.costPriceField,
                        hint: '0',
                        controller: _costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [NoLeadingZeroFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: context.colors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JAMI',
                        style: AppTextStyles.caption().copyWith(
                          color: context.colors.brandDark,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${NumberFormatter.format(_lineTotal)} ${l10n.currencySom}',
                        style: AppTextStyles.titleMedium().copyWith(
                          color: context.colors.brandDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lineError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineError(message: _lineError!),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2,
            AppSpacing.lg,
            AppSpacing.xl2,
            AppSpacing.xl3,
          ),
          child: AppPrimaryButton(
            label: _editingIndex != null ? l10n.save : l10n.addProductToBasket,
            icon: Icons.add_rounded,
            onPressed: _commitLine,
          ),
        ),
      ],
    );
  }
}

// ── small sub-widgets ───────────────────────────────────────────────────────

/// Inline error banner shown inside the card at the section that failed —
/// replaces SnackBars, which render behind the centered dialog.
class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  const _Header({required this.title, required this.onClose, this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl2,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.xl,
    ),
    child: Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close_rounded, color: context.colors.textMuted),
        ),
      ],
    ),
  );
}

class _SupplierField extends StatelessWidget {
  final SupplierEntity? supplier;
  final VoidCallback onTap;
  const _SupplierField({required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectSupplierOptional.toUpperCase(),
            style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg + 2,
            ),
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    supplier?.name ?? l10n.noSupplierSelected,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontSize: 15,
                      color: supplier == null
                          ? context.colors.textMuted
                          : context.colors.text,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  color: context.colors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketRow extends StatelessWidget {
  final ReceiptLine line;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _BasketRow({
    required this.line,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_AddZakupReceiptSheetState._fmtNum(line.quantity)} × '
                  '${NumberFormatter.format(line.costPrice)} = '
                  '${NumberFormatter.format(line.total)} ${l10n.currencySom}',
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_rounded, size: 18, color: context.colors.brand),
          ),
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddItemButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.colors.brand.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 20, color: context.colors.brand),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelLarge().copyWith(
              color: context.colors.brandDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentSection extends StatelessWidget {
  final TextEditingController paidCtrl;
  final double grandTotal;
  final double remaining;
  final String statusKey;
  final VoidCallback onMarkPaid;

  const _PaymentSection({
    required this.paidCtrl,
    required this.grandTotal,
    required this.remaining,
    required this.statusKey,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (statusKey) {
      'paid' => (l10n.statusPaid, AppColors.success),
      'partial' => (l10n.statusPartial, AppColors.warning),
      _ => (l10n.statusUnpaid, AppColors.danger),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.paymentStatusLabel.toUpperCase(),
              style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall().copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextInput(
                label: l10n.paidLabel,
                hint: '0',
                controller: paidCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [NoLeadingZeroFormatter()],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: OutlinedButton(
                onPressed: onMarkPaid,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.brand),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                ),
                child: Text(
                  l10n.markFullyPaid,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (remaining > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.remainingDebtLabel,
                style: AppTextStyles.bodySmall().copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                '${NumberFormatter.format(remaining)} ${l10n.currencySom}',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProductPickRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  const _ProductPickRow({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: context.colors.brand,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
        ],
      ),
    ),
  );
}
