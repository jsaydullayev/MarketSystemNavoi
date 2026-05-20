// Product add/edit bottom sheet — migrated to the new design system.
//
// Layout follows HTML demo page 7.5 (`#page-addproduct`):
// - Sheet handle + title + subtitle
// - "Asosiy ma'lumotlar" section with name + (kategoriya, birlik) row
// - Brand-light "Narxlar" card (tannarx, sotish narxi, minimum sotish narxi)
// - "Stok" section (hozirgi stok, minimum stok) with helper text
// - Sticky primary CTA at the bottom

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/app_extensions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/product_category_model.dart';
import '../../../../data/services/category_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

class ProductBottomSheet extends StatefulWidget {
  final dynamic product;

  const ProductBottomSheet({super.key, this.product});

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  bool _isLoading = false;
  List<ProductCategoryModel> _categories = [];
  int? _selectedCategory;

  int _selectedUnit = 1;
  final List<Map<String, dynamic>> _units = [
    {'value': 1, 'name': 'dona'},
    {'value': 2, 'name': 'kg'},
    {'value': 3, 'name': 'm'},
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _costPriceController.text = (widget.product['costPrice'] ?? 0).toString();
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text =
          (widget.product['minSalePrice'] ?? 0).toString();
      _stockController.text = (widget.product['quantity'] ?? 0).toString();
      _minThresholdController.text =
          (widget.product['minThreshold'] ?? 0).toString();
      _isTemporary = widget.product['isTemporary'] ?? false;
      _selectedCategory = widget.product['categoryId'];
      _selectedUnit = widget.product['unit'] ?? 1;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final categoryService = CategoryService(authProvider: authProvider);
      final categories = await categoryService.getAllCategories();
      if (!mounted) return;
      setState(() {
        final seen = <int>{};
        _categories = categories.where((c) => seen.add(c.id)).toList();
      });
    } catch (_) {
      // Categories optional — silent fallback to empty list is fine here.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _minSalePriceController.dispose();
    _stockController.dispose();
    _minThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final String name = _nameController.text.trim();
      final double salePrice =
          double.tryParse(_salePriceController.text.replaceAll(',', '.')) ??
              0.0;
      final double minSalePrice =
          double.tryParse(_minSalePriceController.text.replaceAll(',', '.')) ??
              0.0;
      final int minThreshold = int.tryParse(_minThresholdController.text) ?? 0;
      final bool tempStatus = _isTemporary;

      if (widget.product == null) {
        await productService.createProduct(
          name: name,
          isTemporary: tempStatus,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
        );
      } else {
        await productService.updateProduct(
          id: widget.product['id'],
          name: name,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          isTemporary: tempStatus,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final unitName = _units.firstWhere(
      (u) => u['value'] == _selectedUnit,
      orElse: () => _units.first,
    )['name'] as String;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 500 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl2)),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
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
                  16.height,
                  // Title + subtitle (centered)
                  Center(
                    child: Text(
                      _isEditing ? l10n.editProduct : l10n.addProduct,
                      style: AppTextStyles.titleLarge()
                          .copyWith(fontSize: 19),
                    ),
                  ),
                  6.height,
                  Center(
                    child: Text(
                      "Barcha maydonlarni to'ldiring. * — majburiy",
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  20.height,

                  // === Asosiy ma'lumotlar ===
                  _SectionLabel(text: l10n.productBasicInfoSection),
                  10.height,
                  _LabeledField(
                    label: l10n.productName,
                    required: true,
                    child: _buildTextField(
                      controller: _nameController,
                      hint: l10n.productNameHint,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.fillIn : null,
                    ),
                  ),
                  12.height,
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: l10n.categories,
                          required: true,
                          child: _buildCategoryDropdown(l10n),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: _LabeledField(
                          label: l10n.unit,
                          required: true,
                          child: _buildUnitDropdown(l10n),
                        ),
                      ),
                    ],
                  ),
                  18.height,

                  // === Narxlar (brand-light card) ===
                  _PriceCard(
                    title: l10n.pricesSection,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: l10n.shortCostPrice,
                              required: true,
                              compact: true,
                              child: _buildSuffixField(
                                controller: _costPriceController,
                                suffix: 'UZS',
                                isNumber: true,
                              ),
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: _LabeledField(
                              label: l10n.salePrice,
                              required: true,
                              compact: true,
                              child: _buildSuffixField(
                                controller: _salePriceController,
                                suffix: 'UZS',
                                isNumber: true,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.fillIn
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      12.height,
                      _LabeledField(
                        label: l10n.minSalePrice,
                        optional: l10n.forDiscountHint,
                        compact: true,
                        child: _buildSuffixField(
                          controller: _minSalePriceController,
                          suffix: 'UZS',
                          isNumber: true,
                        ),
                      ),
                      8.height,
                      _PriceTip(
                        text: l10n.minSalePriceTip(
                          _minSalePriceController.text.isEmpty
                              ? 'X'
                              : _minSalePriceController.text,
                        ),
                      ),
                    ],
                  ),
                  18.height,

                  // === Stok ===
                  _SectionLabel(text: l10n.stockShort),
                  10.height,
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: l10n.currentStockLabel,
                          required: !_isEditing,
                          child: _buildSuffixField(
                            controller: _stockController,
                            suffix: unitName,
                            isNumber: true,
                            // Stock is set via zakup once the product exists,
                            // so editing it here would be misleading.
                            enabled: !_isEditing,
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: _LabeledField(
                          label: l10n.minStockLabel,
                          optional: l10n.forWarningHint,
                          child: _buildSuffixField(
                            controller: _minThresholdController,
                            suffix: unitName,
                            isNumber: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  8.height,
                  Text(
                    "Stok ${_minThresholdController.text.isEmpty ? "N" : _minThresholdController.text} donadan tushganda Owner'ga xabar yuboriladi",
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 11,
                      letterSpacing: 0,
                      color: context.colors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // Temporary product toggle preserved from the legacy form
                  // (visible to power users; not in the demo but the schema
                  // still carries it).
                  16.height,
                  _TempToggle(
                    value: _isTemporary,
                    onChanged: (v) => setState(() => _isTemporary = v),
                  ),

                  24.height,
                  AppPrimaryButton(
                    label: _isEditing
                        ? l10n.save
                        : "Mahsulotni qo'shish",
                    icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
                    onPressed: _isLoading ? null : _saveProduct,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    bool isNumber = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: validator,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: _inputDecoration(hint: hint),
    );
  }

  Widget _buildSuffixField({
    required TextEditingController controller,
    required String suffix,
    bool isNumber = false,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: _inputDecoration().copyWith(
        suffixText: suffix,
        suffixStyle: AppTextStyles.caption().copyWith(
          fontSize: 11,
          letterSpacing: 0.5,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium().copyWith(
        color: context.colors.textMuted,
        fontSize: 14,
      ),
      filled: true,
      fillColor: context.colors.inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
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
        borderSide: BorderSide(color: context.colors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n) {
    final uniqueCategories = _categories
        .fold<Map<int, ProductCategoryModel>>(
          {},
          (map, c) => map..[c.id] = c,
        )
        .values
        .toList();

    final validIds = uniqueCategories.map((c) => c.id).toSet();
    final safeCategory =
        (_selectedCategory != null && validIds.contains(_selectedCategory))
            ? _selectedCategory
            : null;

    return DropdownButtonFormField<int?>(
      initialValue: safeCategory,
      isExpanded: true,
      decoration: _inputDecoration(),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: context.colors.textSecondary),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.no,
            style: AppTextStyles.bodyMedium()
                .copyWith(fontSize: 14, color: context.colors.textMuted),
          ),
        ),
        ...uniqueCategories.map(
          (c) => DropdownMenuItem(
            value: c.id,
            child: Text(
              c.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
            ),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _buildUnitDropdown(AppLocalizations l10n) {
    final validValues = _units.map((u) => u['value'] as int).toSet();
    final safeValue = validValues.contains(_selectedUnit) ? _selectedUnit : 1;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: _inputDecoration(),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: context.colors.textSecondary),
      items: _units
          .map(
            (u) => DropdownMenuItem(
              value: u['value'] as int,
              child: Text(
                u['name'] as String,
                style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedUnit = v!),
    );
  }
}

/// Uppercase section label used to title each form section.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Label + required/optional marker stacked above a child input. Demo's
/// `.form-label` look.
class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final String? optional;
  final bool compact;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
    this.optional,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  fontSize: compact ? 10 : 11,
                  letterSpacing: 0.5,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (required)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  '*',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.danger,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (optional != null)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  optional!,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: compact ? 10 : 11,
                    letterSpacing: 0,
                    color: context.colors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Brand-light card grouping pricing inputs. Demo's `.price-grid`.
class _PriceCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PriceCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandTint, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 14,
                color: context.colors.brandDark,
              ),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: context.colors.brandDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

/// Soft yellow hint shown under the "minimum sotish narxi" input.
class _PriceTip extends StatelessWidget {
  final String text;
  const _PriceTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption().copyWith(
                fontSize: 10,
                letterSpacing: 0,
                color: context.colors.text,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact toggle for the "vaqtinchalik mahsulot" flag. Brand-light pill
/// with a brand-orange-tinted switch.
class _TempToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TempToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.borderSoft, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: context.colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.temporaryProductDesc,
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.text,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeThumbColor: context.colors.brand,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
