import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final categories =
          await CategoryService(authProvider: authProvider).getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openCategoryForm({ProductCategoryModel? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryBottomSheet(category: category),
    ).then((value) {
      if (value == true) _loadCategories();
    });
  }

  Future<void> _deleteCategory(ProductCategoryModel category) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await CategoryService(authProvider: authProvider)
          .deleteCategory(category.id);
      _loadCategories();
      _showSnackBar(l10n.deleteSuccess, Colors.green);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(l10n.categories,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.primaryColor),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading && _categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorView(l10n)
                  : _categories.isEmpty
                      ? _buildEmptyView(l10n, theme.primaryColor)
                      : LiquidPullToRefresh(
                          onRefresh: _loadCategories,
                          color: theme.primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) => CategoryCard(
                              category: _categories[index],
                              l10n: l10n,
                              isDark: isDark,
                              onEdit: (c) => _openCategoryForm(category: c),
                              onDelete: (c) => _deleteCategory(c),
                            ),
                          ),
                        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyView(AppLocalizations l10n, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.category_outlined, size: 80, color: color.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(l10n.noData,
            style: const TextStyle(fontSize: 18, color: Colors.grey)),
      ],
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(onPressed: _loadCategories, child: Text(l10n.loading)),
        ],
      ),
    );
  }
}
