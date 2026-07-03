// Admin Product form вЂ” migrated to the new design system.
//
// Layout follows HTML demo page 7.5 (`#page-addproduct`):
// - Hero icon tile + title strip
// - "Asosiy ma'lumotlar" AppCard (name + category + unit)
// - Brand-light "рџ’° Narxlar" card (sotish narxi + min. sotish narxi)
// - "Stok" AppCard (min. threshold + temporary toggle)
// - Sticky AppPrimaryButton "Saqlash" at the bottom
//
// Business rules preserved:
// - When editing, name and quantity are not changed (admin can only adjust
//   prices, threshold, category, temporary flag).
// - When creating, only sale/min-sale prices and min-threshold are sent (no
//   cost price / quantity вЂ” those come from Zakup).

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:provider/provider.dart';

import '../../../data/services/product_service.dart';
import '../../../data/services/category_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'admin_product_form_dropdowns.dart';
import 'admin_product_form_sections.dart';
import 'widgets/admin_product_image_section.dart';

class AdminProductFormScreen extends StatefulWidget {
  final dynamic product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _minSalePriceController = TextEditingController();
  final _minThresholdController = TextEditingController();

  bool _isTemporary = false;
  bool _hideFromSeller = false;
  bool _isLoading = false;
  List<dynamic> _categories = [];
  dynamic _selectedCategory;
  bool _isLoadingCategories = true;

  int _selectedUnit = 1;
  final List<Map<String, dynamic>> _units = const [
    {'value': 1, 'name': 'dona', 'icon': Icons.inventory_2_outlined},
    {'value': 2, 'name': 'kg', 'icon': Icons.scale},
    {'value': 3, 'name': 'm', 'icon': Icons.straighten},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
    _loadCategories();
  }

  void _loadInitialValues() {
    if (widget.product != null) {
      _nameController.text = widget.product['name'] ?? '';
      _salePriceController.text = (widget.product['salePrice'] ?? 0).toString();
      _minSalePriceController.text = (widget.product['minSalePrice'] ?? 0)
          .toString();
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
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _minSalePriceController.dispose();
    _minThresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // AUDIT-1 вЂ” defence-in-depth tryParse. The Form validators already
    // refuse empty / non-numeric input, but a future refactor that
    // forgets one of the three checks would let a raw double.parse /
    // int.parse throw a FormatException here, popping the form back to
    // the user with no submission attempt. Re-parsing with tryParse +
    // explicit bail-out keeps the failure mode "stay on screen with
    // validation errors" instead of "snackbar with raw exception text".
    final salePrice = double.tryParse(
      _salePriceController.text.replaceAll(',', '.'),
    );
    final minSalePrice = double.tryParse(
      _minSalePriceController.text.replaceAll(',', '.'),
    );
    final minThreshold = int.tryParse(_minThresholdController.text);
    if (salePrice == null || minSalePrice == null || minThreshold == null) {
      // The validator should have caught this; if we somehow got here,
      // re-trigger validation so the user sees field-level errors.
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      if (widget.product == null) {
        // Create new product вЂ” Admin cannot set costPrice or quantity.
        await productService.createProduct(
          name: _nameController.text.trim(),
          isTemporary: _isTemporary,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
          hidePriceFromSellers: _hideFromSeller,
        );
      } else {
        // Update existing product вЂ” Admin can update prices, threshold,
        // category, temporary flag. Name & unit remain fixed.
        await productService.updateProduct(
          id: widget.product['id'],
          name: widget.product['name'],
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: widget.product['unit'] ?? _selectedUnit,
          isTemporary: _isTemporary,
          hidePriceFromSellers: _hideFromSeller,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.colors.text,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          isEditing ? l10n.adminEditProductTitle : l10n.adminNewProductTitle,
          style: AppTextStyles.titleMedium().copyWith(
            fontWeight: FontWeight.w800,
            color: context.colors.text,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl4,
          ),
          children: [
            // Hero strip
            HeroStrip(isEditing: isEditing, l10n: l10n),
            const SizedBox(height: AppSpacing.xl),

            // === Asosiy ma'lumotlar ===
            const SectionLabel(text: "Asosiy ma'lumotlar"),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextInput(
                    label: l10n.productName,
                    controller: _nameController,
                    enabled: !isEditing,
                    hint: 'Masalan: Coca-Cola 1.5L',
                    validator: (value) {
                      if (isEditing) return null;
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FieldLabel(text: l10n.category),
                  const SizedBox(height: AppSpacing.sm),
                  _isLoadingCategories
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.brand,
                            ),
                          ),
                        )
                      : CategoryDropdown(
                          value: _selectedCategory,
                          categories: _categories,
                          l10n: l10n,
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                  const SizedBox(height: AppSpacing.xl),
                  FieldLabel(text: l10n.measureUnit),
                  const SizedBox(height: AppSpacing.sm),
                  UnitDropdown(
                    value: _selectedUnit,
                    units: _units,
                    enabled: !isEditing,
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnit = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Mahsulot rasmi (faqat tahrirlashda — rasm biriktirish uchun
            // mahsulot allaqachon mavjud bo'lishi kerak) ===
            if (isEditing) ...[
              const SectionLabel(text: 'Mahsulot rasmi'),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AdminProductImageSection(
                  productId: widget.product['id'].toString(),
                  initialImageUrl: widget.product['imageUrl'] as String?,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // === рџ’° Narxlar (brand-light) ===
            PriceCard(
              title: l10n.priceManagement,
              children: [
                AppTextInput(
                  label: l10n.salePriceField,
                  controller: _salePriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterSalePrice;
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) {
                      return l10n.enterValidPrice;
                    }
                    if (parsed <= 0) {
                      return l10n.pricePositive;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextInput(
                  label: l10n.minSalePriceField,
                  controller: _minSalePriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterMinSalePrice;
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) {
                      return l10n.enterValidPrice;
                    }
                    if (parsed < 0) {
                      return l10n.priceNonNegative;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                PriceTip(
                  text:
                      "Sotuvchi mijozga ${_minSalePriceController.text.isEmpty ? "X" : _minSalePriceController.text} UZS gacha tushira oladi.",
                ),
                const SizedBox(height: AppSpacing.lg),
                // Narxni ko'rsatish/yashirish: ON = narx ko'rinadi, OFF = sotuvda
                // sotuvchiga narx (tannarx/sotuv narxi) ko'rsatilmaydi.
                TempToggle(
                  value: !_hideFromSeller,
                  icon: Icons.visibility_outlined,
                  title: l10n.showPriceTitle,
                  subtitle: l10n.showPriceDescription,
                  onChanged: (v) => setState(() => _hideFromSeller = !v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Stok ===
            const SectionLabel(text: 'Stok'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextInput(
                    label: l10n.minThresholdField,
                    controller: _minThresholdController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterMinThreshold;
                      }
                      // AUDIT-1 вЂ” call tryParse once and reuse. The old
                      // tryParse-then-parse pattern would have crashed if
                      // the input changed between the two calls (e.g. a
                      // very fast paste-and-clear race).
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return l10n.enterValidNumber;
                      }
                      if (parsed < 0) {
                        return l10n.numberNonNegative;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  QuantityNotice(
                    isEditing: isEditing,
                    product: widget.product,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TempToggle(
                    value: _isTemporary,
                    title: l10n.temporaryProductTitle,
                    subtitle: l10n.temporaryProductDescription,
                    onChanged: (v) => setState(() => _isTemporary = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Save CTA
            AppPrimaryButton(
              label: isEditing ? l10n.save : "Mahsulotni qo'shish",
              icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _isLoading ? null : _save,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
