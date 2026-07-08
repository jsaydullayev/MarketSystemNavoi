// Product add/edit bottom sheet — migrated to the new design system.
//
// Layout:
// - Sheet handle + title + subtitle
// - "Asosiy ma'lumotlar" section with name + (kategoriya, birlik) row
// - Brand-light "Narxlar" card: kelgan narxi (Owner/Admin only) + sotish narxi
//   + "narxni ko'rsatish" toggle
// - "Stok" section (hozirgi stok — Owner-editable, minimum stok) with helper text
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
import 'widgets/product_form_fields.dart';

class ProductBottomSheet extends StatefulWidget {
  final dynamic product;

  const ProductBottomSheet({super.key, this.product});

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  // Kelgan (tannarx) narx — faqat cost-ko'ruvchi (Owner/Admin) uchun ko'rinadi.
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  // Yangi mahsulot uchun narx DEFAULT yashirin (sotuvchiga ko'rinmaydi).
  // Mavjud mahsulotда initState uni saqlangan qiymatдан yuklaydi (79-qator).
  bool _hideFromSeller = true;
  bool _isLoading = false;

  // Tahrirda yuklangan boshlang'ich qoldiq. Owner stokni qo'lda o'zgartirganda
  // faqat HAQIQATAN o'zgargan bo'lsa serverga yuboramiz — aks holda eskirgan
  // forma sotuvlar o'zgartirgan qoldiqni bosib ketishi mumkin edi.
  double? _originalQuantity;
  List<ProductCategoryModel> _categories = [];
  int? _selectedCategory;

  int _selectedUnit = 1;
  final List<Map<String, dynamic>> _units = [
    {'value': 1, 'name': 'dona'},
    {'value': 2, 'name': 'kg'},
    {'value': 3, 'name': 'm'},
  ];

  bool get _isEditing => widget.product != null;

  /// Only Owner/SuperAdmin may hand-correct on-hand stock from this form (e.g.
  /// after a physical count). The backend enforces the same rule from the JWT
  /// role — this just decides whether the field is editable and whether we send
  /// the new value. Mirrors AuthProvider.can()'s Owner/SuperAdmin short-circuit.
  bool _userCanEditStock() {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    return role == 'Owner' || role == 'SuperAdmin';
  }

  /// Owner/Admin may see and set the cost (kelgan narx). The backend masks it
  /// from everyone else, so we only show/send the field for these roles —
  /// mirrors ProductsController.CanViewCost. Without this a cost-hidden user
  /// would load a masked 0 and clobber the stored cost on save.
  bool _userCanViewCost() {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    return role == 'Owner' || role == 'Admin';
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _costPriceController.text = (widget.product['costPrice'] ?? 0).toString();
      _stockController.text = (widget.product['quantity'] ?? 0).toString();
      _originalQuantity =
          (widget.product['quantity'] as num?)?.toDouble() ?? 0.0;
      _minThresholdController.text = (widget.product['minThreshold'] ?? 0)
          .toString();
      _isTemporary = widget.product['isTemporary'] ?? false;
      _hideFromSeller = widget.product['hidePriceFromSellers'] ?? false;
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
    _salePriceController.dispose();
    _costPriceController.dispose();
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
      // Kelgan (tannarx) narx — faqat cost-ko'ruvchi (Owner/Admin) kiritadi va
      // yuboradi; boshqasi uchun maydon ko'rinmaydi. minSalePrice endi formadan
      // olib tashlandi → doim 0 yuboriladi.
      final bool canViewCost = _userCanViewCost();
      final double costPrice =
          double.tryParse(_costPriceController.text.replaceAll(',', '.')) ??
          0.0;
      final int minThreshold = int.tryParse(_minThresholdController.text) ?? 0;
      // Boshlang'ich qoldiq faqat yangi mahsulotda kiritiladi (tahrirda zakup
      // orqali). Bo'sh/no'to'g'ri bo'lsa 0.
      final double initialQuantity =
          double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0.0;
      final bool tempStatus = _isTemporary;

      if (widget.product == null) {
        await productService.createProduct(
          name: name,
          isTemporary: tempStatus,
          salePrice: salePrice,
          minSalePrice: 0,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          quantity: initialQuantity,
          hidePriceFromSellers: _hideFromSeller,
          costPrice: canViewCost ? costPrice : 0,
        );
      } else {
        // Owner qoldiqni qo'lda tuzatishi mumkin. Faqat HAQIQATAN o'zgargan
        // bo'lsa yuboramiz — bo'lmasa null qoldirib, eskirgan forma sotuvlar
        // o'zgartirgan qoldiqni bosib ketmasligini kafolatlaymiz.
        double? quantityOverride;
        if (_userCanEditStock() && initialQuantity != _originalQuantity) {
          quantityOverride = initialQuantity;
        }

        await productService.updateProduct(
          id: widget.product['id'],
          name: name,
          salePrice: salePrice,
          minSalePrice: 0,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          isTemporary: tempStatus,
          hidePriceFromSellers: _hideFromSeller,
          quantity: quantityOverride,
          // Kelgan narx faqat cost-ko'ruvchi uchun yuboriladi; aks holda null →
          // server saqlangan narxni o'zgartirmaydi (masking 0'ini bosmaydi).
          costPrice: canViewCost ? costPrice : null,
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
    // Owner/SuperAdmin tahrirда hozirgi stokni qo'lda tuzatishi mumkin.
    final canEditStock = _userCanEditStock();
    // Owner/Admin kelgan (tannarx) narxni ko'radi va tahrirlaydi.
    final canViewCost = _userCanViewCost();
    final unitName =
        _units.firstWhere(
              (u) => u['value'] == _selectedUnit,
              orElse: () => _units.first,
            )['name']
            as String;

    // Match the app's other bottom sheets (pay_debt / category / withdraw):
    // a single content-sized Container that the modal already bottom-anchors
    // and centres — no outer Align/Padding needed. Default scroll physics
    // (was AlwaysScrollableScrollPhysics) is what lets showModalBottomSheet's
    // swipe-down-to-dismiss coordinate with the inner scroll; the old physics
    // always claimed the vertical drag, so the sheet neither scrolled nor
    // closed on a downward swipe. The keyboard/safe-area inset lives in the
    // sheet's own bottom padding so the CTA clears the keyboard and home bar.
    return Container(
      constraints: BoxConstraints(
        maxWidth: isWeb ? 500 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl3,
      ),
      child: SingleChildScrollView(
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
              // Title only — subtitle removed to keep the whole panel on one
              // screen without scrolling (roliksiz).
              Center(
                child: Text(
                  _isEditing ? l10n.editProduct : l10n.addProduct,
                  style: AppTextStyles.titleLarge().copyWith(fontSize: 19),
                ),
              ),
              16.height,

              // === Asosiy ma'lumotlar ===
              SectionLabel(text: l10n.productBasicInfoSection),
              10.height,
              LabeledField(
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
                    child: LabeledField(
                      label: l10n.categories,
                      required: true,
                      child: _buildCategoryDropdown(l10n),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: LabeledField(
                      label: l10n.unit,
                      required: true,
                      child: _buildUnitDropdown(l10n),
                    ),
                  ),
                ],
              ),
              14.height,

              // === Narxlar (brand-light card) ===
              PriceCard(
                title: l10n.pricesSection,
                children: [
                  // Kelgan narx (Owner/Admin) va sotish narxi yonma-yon — bir
                  // ekranga sig'ishi uchun. Cost-yashirin foydalanuvchida faqat
                  // sotish narxi to'liq kenglikda ko'rinadi (backend maskalaydi,
                  // update'da null yuborilib eski cost saqlanadi).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canViewCost) ...[
                        Expanded(
                          child: LabeledField(
                            label: 'Kelgan narxi',
                            compact: true,
                            child: _buildSuffixField(
                              controller: _costPriceController,
                              suffix: 'UZS',
                              isNumber: true,
                            ),
                          ),
                        ),
                        12.width,
                      ],
                      Expanded(
                        child: LabeledField(
                          label: l10n.salePrice,
                          required: true,
                          compact: true,
                          child: _buildSuffixField(
                            controller: _salePriceController,
                            suffix: 'UZS',
                            isNumber: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? l10n.fillIn : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  12.height,
                  // Narxni ko'rsatish/yashirish: ON = narx ko'rinadi,
                  // OFF = sotuvda sotuvchiga narx (tannarx/sotuv narxi)
                  // ko'rsatilmaydi.
                  PriceVisibilityToggle(
                    value: !_hideFromSeller,
                    onChanged: (v) => setState(() => _hideFromSeller = !v),
                  ),
                ],
              ),
              14.height,

              // === Stok ===
              SectionLabel(text: l10n.stockShort),
              10.height,
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: l10n.currentStockLabel,
                      required: !_isEditing,
                      child: _buildSuffixField(
                        controller: _stockController,
                        suffix: unitName,
                        isNumber: true,
                        // Yangi mahsulotда boshlang'ich qoldiq kiritiladi.
                        // Mavjud mahsulotда qoldiq odatда zakup orqali
                        // harakatlanadi — lekin Owner uni qo'lda tuzatishi
                        // mumkin (masalan, inventarizatsiya). Boshqalar uchun
                        // maydon o'zgartirib bo'lmaydigan holatда qoladi.
                        enabled: !_isEditing || canEditStock,
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: LabeledField(
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
              16.height,
              AppPrimaryButton(
                label: _isEditing ? l10n.save : "Mahsulotni qo'shish",
                icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
                onPressed: _isLoading ? null : _saveProduct,
                isLoading: _isLoading,
              ),
            ],
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
      style: AppTextStyles.bodyMedium().copyWith(
        fontSize: 14,
        color: context.colors.text,
      ),
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
      style: AppTextStyles.bodyMedium().copyWith(
        fontSize: 14,
        color: context.colors.text,
      ),
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
        .fold<Map<int, ProductCategoryModel>>({}, (map, c) => map..[c.id] = c)
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
      dropdownColor: context.colors.surface,
      style: AppTextStyles.bodyMedium().copyWith(
        fontSize: 14,
        color: context.colors.text,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.no,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 14,
              color: context.colors.textMuted,
            ),
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
      dropdownColor: context.colors.surface,
      style: AppTextStyles.bodyMedium().copyWith(
        fontSize: 14,
        color: context.colors.text,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
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
      onChanged: (v) {
        // Dropdown.onChanged's `v` is nullable per the framework signature;
        // ignore the null call (no items would ever produce one) rather
        // than assert with `!`.
        if (v != null) setState(() => _selectedUnit = v);
      },
    );
  }
}
