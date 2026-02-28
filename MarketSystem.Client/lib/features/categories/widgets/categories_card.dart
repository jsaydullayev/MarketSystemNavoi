import 'package:flutter/material.dart';
import 'package:market_system_client/data/models/product_category_model.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class CategoryCard extends StatelessWidget {
  final ProductCategoryModel category;
  final AppLocalizations l10n;
  final bool isDark;
  final Function(ProductCategoryModel) onEdit;
  final Function(ProductCategoryModel) onDelete;

  const CategoryCard({
    required this.category,
    required this.l10n,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('cat_${category.id}'),
        background:
            _buildSwipeBg(Colors.blue, Icons.edit, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBg(
            Colors.redAccent, Icons.delete, Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit(category);
            return false;
          } else {
            return await _showConfirmDialog(context);
          }
        },
        onDismissed: (dir) => onDelete(category),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (category.isActive ? Colors.green : Colors.grey)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.isActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_filled_rounded,
                color: category.isActive ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(category.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${l10n.products}: ${category.productCount}',
                style: TextStyle(color: Colors.grey[600])),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBg(Color color, IconData icon, Alignment align) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      alignment: align,
      child: Icon(icon, color: Colors.white),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.confirmDelete),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.no)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.yes,
                      style: const TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }
}
