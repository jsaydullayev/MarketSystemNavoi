import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../bloc/zakup_bloc.dart';
import '../bloc/events/zakup_event.dart';

/// "Add zakup" (stock receive) modal bottom sheet — 2-step flow.
///
/// Step 0: pick a product from a searchable list.
/// Step 1: enter quantity + cost price, see live total, submit.
///
/// Demo reference: `id="page-prod-receive"` (7.3 Stok kiritish). Step 1 in
/// particular mirrors the per-product `.receive-item` card with its
/// SONI / TANNARX / JAMI grid and dark-navy total summary card.
class AddZakupSheet extends StatefulWidget {
  final List<dynamic> products;

  const AddZakupSheet({super.key, required this.products});

  static void show(BuildContext context, {required List<dynamic> products}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ZakupBloc>(),
        child: AddZakupSheet(products: products),
      ),
    );
  }

  @override
  State<AddZakupSheet> createState() => _AddZakupSheetState();
}

class _AddZakupSheetState extends State<AddZakupSheet> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  List<dynamic> _filtered = [];
  dynamic _selectedProduct;

  // Step: 0 = product select, 1 = qty+price
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
    _searchController.addListener(_filter);
    _qtyController.addListener(_recomputeTotal);
    _priceController.addListener(_recomputeTotal);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.products
          : widget.products
                .where((p) => (p['name'] ?? '').toLowerCase().contains(q))
                .toList();
    });
  }

  void _recomputeTotal() {
    // Trigger a rebuild so the JAMI / total card recalculates live.
    setState(() {});
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _selectedProduct = product;
      _step = 1;
    });
  }

  double get _liveTotal {
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    return qty * price;
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final l10n = AppLocalizations.of(context)!;

    if (qty == null || qty <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAmountAndPrice),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          margin: const EdgeInsets.all(AppSpacing.xl),
        ),
      );
      return;
    }

    context.read<ZakupBloc>().add(
      CreateZakupEvent(
        productId: _selectedProduct['id'],
        quantity: qty.toDouble(),
        costPrice: price,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl2),
          ),
        ),
        child: _step == 0 ? _buildProductStep() : _buildPriceStep(),
      ),
    );
  }

  // ── Step 0: product picker ──────────────────────────────────────────────
  Widget _buildProductStep() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const _Handle(),
        _SheetHeader(
          title: l10n.selectProduct,
          onClose: () => Navigator.pop(context),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2,
            0,
            AppSpacing.xl2,
            AppSpacing.lg,
          ),
          child: AppTextInput(
            hint: l10n.searchProduct,
            controller: _searchController,
            prefixIcon: Icons.search_rounded,
          ),
        ),

        // Product list
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
                    final qtyStr = qty == qty.truncateToDouble()
                        ? qty.toInt().toString()
                        : qty.toString();

                    return GestureDetector(
                      onTap: () => _selectProduct(p),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
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
                                    p['name'] ?? l10n.unknown,
                                    style: AppTextStyles.bodyMedium().copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$qtyStr ${l10n.piece}  •  ${NumberFormatter.format(p['salePrice'] ?? 0)} ${l10n.currencySom}',
                                    style: AppTextStyles.bodySmall().copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.colors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Step 1: qty + cost price → live total, submit ───────────────────────
  Widget _buildPriceStep() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Handle(),
        _SheetHeader(
          title: l10n.zakup,
          onClose: () => Navigator.pop(context),
          onBack: () => setState(() => _step = 0),
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
                Text(
                  l10n.zakup.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: AppSpacing.md),

                // Per-product "receive-item" card: emoji tile + product name,
                // then SONI / TANNARX / JAMI grid below.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.colors.brandLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: context.colors.brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              _selectedProduct['name'] ?? '',
                              style: AppTextStyles.bodyLarge().copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Grid: SONI + TANNARX + JAMI
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextInput(
                              label: l10n.number,
                              hint: '0',
                              controller: _qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextInput(
                              label: l10n.costPriceField,
                              hint: '0',
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _JamiTile(total: _liveTotal)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl2),

                // Dark navy total card
                _TotalCard(
                  itemsLabel: '1 ${l10n.piece}',
                  total: _liveTotal,
                  currency: l10n.currencySom,
                ),
              ],
            ),
          ),
        ),

        // Footer buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2,
            AppSpacing.lg,
            AppSpacing.xl2,
            AppSpacing.xl3 + AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: l10n.add,
                  icon: Icons.download_rounded,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  const _SheetHeader({required this.title, required this.onClose, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(title, style: AppTextStyles.titleMedium()),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _JamiTile extends StatelessWidget {
  final double total;

  const _JamiTile({required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JAMI',
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 46,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormatter.format(total),
              style: AppTextStyles.bodyLarge().copyWith(
                color: context.colors.brandDark,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark navy summary card at the bottom of the demo's stock-receive screen.
/// Shows a small inventory readout and a big "Jami summa" line.
class _TotalCard extends StatelessWidget {
  final String itemsLabel;
  final double total;
  final String currency;

  const _TotalCard({
    required this.itemsLabel,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mahsulotlar',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              Text(
                itemsLabel,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Jami summa',
                style: AppTextStyles.bodyLarge().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${NumberFormatter.format(total)} $currency',
                style: AppTextStyles.titleLarge().copyWith(
                  color: context.colors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
