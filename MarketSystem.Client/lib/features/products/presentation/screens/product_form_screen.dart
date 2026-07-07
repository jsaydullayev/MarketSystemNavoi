// Product add/edit bottom sheet — migrated to the new design system.
//
// Layout follows HTML demo page 7.5 (`#page-addproduct`):
// - Sheet handle + title + subtitle
// - "Asosiy ma'lumotlar" section with name + (kategoriya, birlik) row
// - Brand-light "Narxlar" card (tannarx, sotish narxi, minimum sotish narxi)
// - "Stok" section (hozirgi stok, minimum stok) with helper text
// - Sticky primary CTA at the bottom

import 'dart:typed_data';

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
import 'widgets/product_form_image_picker.dart';

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
  final _minSalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minThresholdController = TextEditingController();

  // Deferred image: chosen locally, uploaded after the product is saved
  // (a new product has no id until then).
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _imageRemoved = false;

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text = (widget.product['minSalePrice'] ?? 0)
          .toString();
      _stockController.text = (widget.product['quantity'] ?? 0).toString();
      _originalQuantity = (widget.product['quantity'] as num?)?.toDouble() ?? 0.0;
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
      // Boshlang'ich qoldiq faqat yangi mahsulotda kiritiladi (tahrirda zakup
      // orqali). Bo'sh/no'to'g'ri bo'lsa 0.
      final double initialQuantity =
          double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0.0;
      final bool tempStatus = _isTemporary;

      String productId;
      if (widget.product == null) {
        final created = await productService.createProduct(
          name: name,
          isTemporary: tempStatus,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          quantity: initialQuantity,
          hidePriceFromSellers: _hideFromSeller,
        );
        productId = created['id'] as String;
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
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          isTemporary: tempStatus,
          hidePriceFromSellers: _hideFromSeller,
          quantity: quantityOverride,
        );
        productId = widget.product['id'] as String;
      }

      // Rasm — endi mahsulot id'si bor, kechiktirilgan yuklash/o'chirishni
      // bajaramiz. Mahsulotning o'zi saqlanib bo'lgani uchun rasm xatosi
      // FATAL emas — ogohlantiramiz-u, formani muvaffaqiyat bilan yopamiz.
      try {
        if (_pickedImageBytes != null) {
          await productService.uploadProductImage(
            productId,
            _pickedImageBytes!,
            _pickedImageName ?? 'image.jpg',
          );
        } else if (_imageRemoved && widget.product != null) {
          await productService.removeProductImage(productId);
        }
      } catch (imgErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mahsulot saqlandi, lekin rasm yuklanmadi: $imgErr'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
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
    final unitName =
        _units.firstWhere(
              (u) => u['value'] == _selectedUnit,
              orElse: () => _units.first,
            )['name']
            as String;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              top: Radius.circular(AppRadius.xl2),
            ),
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
                      style: AppTextStyles.titleLarge().copyWith(fontSize: 19),
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
                  18.height,

                  // === Mahsulot rasmi (ixtiyoriy) ===
                  const SectionLabel(text: 'Mahsulot rasmi'),
                  10.height,
                  ProductFormImagePicker(
                    pickedBytes: _pickedImageBytes,
                    existingImageUrl: widget.product?['imageUrl'] as String?,
                    removed: _imageRemoved,
                    onPicked: (bytes, name) => setState(() {
                      _pickedImageBytes = bytes;
                      _pickedImageName = name;
                      _imageRemoved = false;
                    }),
                    onRemoved: () => setState(() {
                      _pickedImageBytes = null;
                      _pickedImageName = null;
                      _imageRemoved = true;
                    }),
                  ),
                  6.height,
                  Text(
                    'Savdo ekranida mahsulotni tezroq tanib olish uchun. (ixtiyoriy, maks 5MB)',
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 11,
                      letterSpacing: 0,
                      color: context.colors.textMuted,
                    ),
                  ),
                  18.height,

                  // === Narxlar (brand-light card) ===
                  PriceCard(
                    title: l10n.pricesSection,
                    children: [
                      // Tannarx (cost) intentionally omitted: cost is set via
                      // zakup, and initial existing stock is entered without it.
                      LabeledField(
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
                      12.height,
                      LabeledField(
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
                      PriceTip(
                        text: l10n.minSalePriceTip(
                          _minSalePriceController.text.isEmpty
                              ? 'X'
                              : _minSalePriceController.text,
                        ),
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
                  18.height,

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
                  if (_isEditing && canEditStock) ...[
                    8.height,
                    Text(
                      "Hozirgi stokni qo'lda tuzatishingiz mumkin (masalan, "
                      "inventarizatsiyadan keyin). O'zgarish audit jurnaliga yoziladi.",
                      style: AppTextStyles.caption().copyWith(
                        fontSize: 11,
                        letterSpacing: 0,
                        color: context.colors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
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
                  TempToggle(
                    value: _isTemporary,
                    onChanged: (v) => setState(() => _isTemporary = v),
                  ),

                  24.height,
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
