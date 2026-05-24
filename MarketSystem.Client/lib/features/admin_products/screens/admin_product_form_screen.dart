// Admin Product form — migrated to the new design system.
//
// Layout follows HTML demo page 7.5 (`#page-addproduct`):
// - Hero icon tile + title strip
// - "Asosiy ma'lumotlar" AppCard (name + category + unit)
// - Brand-light "💰 Narxlar" card (sotish narxi + min. sotish narxi)
// - "Stok" AppCard (min. threshold + temporary toggle)
// - Sticky AppPrimaryButton "Saqlash" at the bottom
//
// Business rules preserved:
// - When editing, name and quantity are not changed (admin can only adjust
//   prices, threshold, category, temporary flag).
// - When creating, only sale/min-sale prices and min-threshold are sent (no
//   cost price / quantity — those come from Zakup).

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

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productService = ProductService(authProvider: authProvider);

      final salePrice = double.parse(
        _salePriceController.text.replaceAll(',', '.'),
      );
      final minSalePrice = double.parse(
        _minSalePriceController.text.replaceAll(',', '.'),
      );
      final minThreshold = int.parse(_minThresholdController.text);

      if (widget.product == null) {
        // Create new product — Admin cannot set costPrice or quantity.
        await productService.createProduct(
          name: _nameController.text.trim(),
          isTemporary: _isTemporary,
          salePrice: salePrice,
          minSalePrice: minSalePrice,
          minThreshold: minThreshold,
          categoryId: _selectedCategory,
          unit: _selectedUnit,
        );
      } else {
        // Update existing product — Admin can update prices, threshold,
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
            _HeroStrip(isEditing: isEditing, l10n: l10n),
            const SizedBox(height: AppSpacing.xl),

            // === Asosiy ma'lumotlar ===
            const _SectionLabel(text: "Asosiy ma'lumotlar"),
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
                  _Label(text: l10n.category),
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
                      : _CategoryDropdown(
                          value: _selectedCategory,
                          categories: _categories,
                          l10n: l10n,
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                  const SizedBox(height: AppSpacing.xl),
                  _Label(text: l10n.measureUnit),
                  const SizedBox(height: AppSpacing.sm),
                  _UnitDropdown(
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

            // === 💰 Narxlar (brand-light) ===
            _PriceCard(
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
                _PriceTip(
                  text:
                      "Sotuvchi mijozga ${_minSalePriceController.text.isEmpty ? "X" : _minSalePriceController.text} UZS gacha tushira oladi.",
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Stok ===
            const _SectionLabel(text: 'Stok'),
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
                      if (int.tryParse(value) == null) {
                        return l10n.enterValidNumber;
                      }
                      if (int.parse(value) < 0) {
                        return l10n.numberNonNegative;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _QuantityNotice(
                    isEditing: isEditing,
                    product: widget.product,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TempToggle(
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

/// Top-of-form hero with the brand icon tile + helper sub-label.
class _HeroStrip extends StatelessWidget {
  final bool isEditing;
  final AppLocalizations l10n;
  const _HeroStrip({required this.isEditing, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandTint, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brand,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? l10n.adminEditProductTitle
                      : l10n.adminNewProductTitle,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.brandDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.adminCanEditPriceAndSettings,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.brandDark,
                    fontSize: 11,
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

/// Small label rendered above each non-AppTextInput control.
class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        fontSize: 11,
        letterSpacing: 0.8,
        color: context.colors.textSecondary,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final dynamic value;
  final List<dynamic> categories;
  final AppLocalizations l10n;
  final ValueChanged<dynamic> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<dynamic>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: _dropdownDecoration(context, hint: l10n.selectCategory),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.categoryNotSelected,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        ...categories.map<DropdownMenuItem<dynamic>>((category) {
          return DropdownMenuItem<dynamic>(
            value: category['id'],
            child: Text(
              category['name'] ?? '',
              style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final int value;
  final List<Map<String, dynamic>> units;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.colors.textSecondary,
      ),
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
      decoration: _dropdownDecoration(context),
      items: units.map<DropdownMenuItem<int>>((unit) {
        return DropdownMenuItem<int>(
          value: unit['value'] as int,
          child: Row(
            children: [
              Icon(
                unit['icon'] as IconData,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                unit['name'] as String,
                style: AppTextStyles.bodyMedium().copyWith(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

InputDecoration _dropdownDecoration(BuildContext context, {String? hint}) {
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
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg + 2,
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
  );
}

/// Brand-light card grouping price inputs. Demo's `.price-grid`.
class _PriceCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PriceCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                size: 16,
                color: context.colors.brandDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: context.colors.brandDark,
                  fontWeight: FontWeight.w800,
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption().copyWith(
                fontSize: 11,
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

class _QuantityNotice extends StatelessWidget {
  final bool isEditing;
  final dynamic product;
  final AppLocalizations l10n;
  const _QuantityNotice({
    required this.isEditing,
    required this.product,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isEditing
                  ? l10n.productQuantityImmutable(
                      (product['quantity'] as num?)?.toDouble() ?? 0.0,
                    )
                  : l10n.productCreatedWithZeroInfo,
              style: AppTextStyles.caption().copyWith(
                fontSize: 11,
                letterSpacing: 0,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempToggle extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _TempToggle({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
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
