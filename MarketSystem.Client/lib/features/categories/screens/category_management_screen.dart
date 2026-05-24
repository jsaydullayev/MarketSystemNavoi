// lib/features/categories/screens/category_management_screen.dart
//
// Categories list screen, mapped to demo `id="page-prod-cats"` (7.4 Kategoriya):
// - Header: title + "X ta" badge in the AppBar trailing slot
// - Info line: "ℹ Tartibni o'zgartirish uchun ⋮⋮ tugmasidan ushlab torting."
// - Category rows via [CategoryCard] — drag handle + emoji tile + name/count + ⋯ menu
// - Bottom "+ Yangi kategoriya qo'shish" dashed-border CTA (brand-light bg)
//
// Business logic preserved:
// - `CategoryService.getAllCategories / createCategory / updateCategory / deleteCategory`
//   wiring is unchanged.
// - Active / inactive split preserved (inactive bucket shown after active).
// - Pull-to-refresh, snackbars, and the add/edit/delete callbacks all preserved.
// - Role gating sits in the service (403 surfaced as a snackbar).

import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/categories/screens/category_bottom_sheet.dart';
import 'package:market_system_client/features/categories/widgets/categories_card.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/product_category_model.dart';
import '../../../data/services/category_service.dart';
import '../../../l10n/app_localizations.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<ProductCategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final list = await CategoryService(authProvider: auth).getAllCategories();
      if (mounted) {
        setState(() {
          _categories = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openForm({ProductCategoryModel? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryBottomSheet(category: category),
    ).then((v) {
      if (v == true) _loadCategories();
    });
  }

  Future<void> _delete(ProductCategoryModel category) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await CategoryService(authProvider: auth).deleteCategory(category.id);
      _loadCategories();
      _snack(l10n.deleteSuccess, isError: false);
    } catch (e) {
      _snack(e.toString(), isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadCategories,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(
          title: l10n.categories,
          onRefresh: _loadCategories,
          extraActions: [
            if (_categories.isNotEmpty) _CountBadge(count: _categories.length),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
        body: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error case final err?) {
      return _ErrorView(error: err, onRetry: _loadCategories, l10n: l10n);
    }

    if (_categories.isEmpty) {
      return _EmptyView(l10n: l10n, onAdd: () => _openForm());
    }

    final active = _categories.where((c) => c.isActive).toList();
    final inactive = _categories.where((c) => !c.isActive).toList();

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: context.colors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl4,
        ),
        children: [
          const _ReorderHint(),
          const SizedBox(height: AppSpacing.lg),
          ...active.map(
            (c) => CategoryCard(
              category: c,
              l10n: l10n,
              isDark: false,
              onEdit: (_) => _openForm(category: c),
              onDelete: (_) => _delete(c),
            ),
          ),
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.inactive.toUpperCase(),
              style: AppTextStyles.caption().copyWith(
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...inactive.map(
              (c) => CategoryCard(
                category: c,
                l10n: l10n,
                isDark: false,
                onEdit: (_) => _openForm(category: c),
                onDelete: (_) => _delete(c),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _AddCategoryButton(
            label: '+ ${l10n.addCategory}',
            onTap: () => _openForm(),
          ),
        ],
      ),
    );
  }
}

/// Small "X ta" badge shown in the app bar trailing area, mirroring
/// the demo's `<span class="badge">5 ta</span>`.
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          '$count ta',
          style: AppTextStyles.caption().copyWith(
            color: context.colors.brandDark,
            letterSpacing: 0,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// "ℹ Tartibni o'zgartirish uchun ⋮⋮ tugmasidan ushlab torting." info line.
class _ReorderHint extends StatelessWidget {
  const _ReorderHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: context.colors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Text(
            "Tartibni o'zgartirish uchun ⋮⋮ tugmasidan ushlab torting.",
            style: AppTextStyles.caption().copyWith(
              color: context.colors.textMuted,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// "+ Yangi kategoriya qo'shish" dashed-border button — brand-light bg,
/// brand text. Tap opens the create-category bottom sheet.
class _AddCategoryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddCategoryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: context.colors.brand,
          radius: AppRadius.lg - 2,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelLarge().copyWith(
              color: context.colors.brand,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-rect dashed border painted on top of the brand-light fill.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _EmptyView({required this.l10n, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl3),
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 52,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              l10n.noData,
              style: AppTextStyles.titleMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.addFirstCategory,
              style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addCategory),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl3,
                  vertical: AppSpacing.lg,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              error,
              style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.loading),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl3,
                  vertical: AppSpacing.lg,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
