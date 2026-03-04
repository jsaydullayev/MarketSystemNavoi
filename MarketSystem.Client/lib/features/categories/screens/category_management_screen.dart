import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/features/categories/screens/category_bottom_sheet.dart';
import 'package:market_system_client/features/categories/widgets/categories_card.dart';
import 'package:provider/provider.dart';

import '../../../data/services/category_service.dart';
import '../../../data/models/product_category_model.dart';
import '../../../core/providers/auth_provider.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: l10n.categories,
        onRefresh: _loadCategories,
      ),
      body: _buildBody(l10n, isDark, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.addCategory,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark, ThemeData theme) {
    if (_isLoading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _loadCategories, l10n: l10n);
    }

    if (_categories.isEmpty) {
      return _EmptyView(l10n: l10n, onAdd: () => _openForm());
    }

    final active = _categories.where((c) => c.isActive).toList();
    final inactive = _categories.where((c) => !c.isActive).toList();

    return LiquidPullToRefresh(
      onRefresh: _loadCategories,
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _StatsBanner(
            total: _categories.length,
            activeCount: active.length,
            inactiveCount: inactive.length,
          ),
          const SizedBox(height: 16),
          if (active.isNotEmpty) ...[
            _SectionLabel(
                label: l10n.active, count: active.length, color: Colors.green),
            const SizedBox(height: 8),
            ...active.map((c) => CategoryCard(
                  category: c,
                  l10n: l10n,
                  isDark: isDark,
                  onEdit: (_) => _openForm(category: c),
                  onDelete: (_) => _delete(c),
                )),
            if (inactive.isNotEmpty) const SizedBox(height: 12),
          ],
          if (inactive.isNotEmpty) ...[
            _SectionLabel(
                label: l10n.inactive,
                count: inactive.length,
                color: Colors.grey),
            const SizedBox(height: 8),
            ...inactive.map((c) => CategoryCard(
                  category: c,
                  l10n: l10n,
                  isDark: isDark,
                  onEdit: (_) => _openForm(category: c),
                  onDelete: (_) => _delete(c),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Stats Banner ───
class _StatsBanner extends StatelessWidget {
  final int total;
  final int activeCount;
  final int inactiveCount;

  const _StatsBanner({
    required this.total,
    required this.activeCount,
    required this.inactiveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _BannerStat(
              icon: Icons.category_outlined,
              value: '$total',
              label: 'Jami',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: _BannerStat(
              icon: Icons.check_circle_outline_rounded,
              value: '$activeCount',
              label: 'Faol',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: _BannerStat(
              icon: Icons.pause_circle_outline_rounded,
              value: '$inactiveCount',
              label: 'Nofaol',
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BannerStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}

// ─── Section Label ───
class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionLabel(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0)]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty View ───
class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _EmptyView({required this.l10n, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.category_outlined,
                  size: 52, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noData,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Birinchi kategoriyangizni qo'shing",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addCategory),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorView(
      {required this.error, required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 40),
            ),
            const SizedBox(height: 16),
            Text(error,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.loading),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
