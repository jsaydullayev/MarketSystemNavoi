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
    super.key,
    required this.category,
    required this.l10n,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  Color _cardColor() {
    const colors = [
      Color(0xFF3B82F6), // blue
      Color(0xFF8B5CF6), // purple
      Color(0xFF10B981), // teal
      Color(0xFFF59E0B), // amber
      Color(0xFFEF4444), // red
      Color(0xFF06B6D4), // cyan
      Color(0xFFF97316), // orange
      Color(0xFF6366F1), // indigo
    ];
    final code = category.name.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _cardColor();
    final isActive = category.isActive;
    final initial =
        category.name.isNotEmpty ? category.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('cat_${category.id}'),
        background: _SwipeBg(
          color: Colors.blue,
          icon: Icons.edit_rounded,
          label: l10n.edit,
          align: Alignment.centerLeft,
        ),
        secondaryBackground: _SwipeBg(
          color: Colors.red,
          icon: Icons.delete_rounded,
          label: l10n.delete,
          align: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit(category);
            return false;
          } else {
            final ok = await _showDeleteDialog(context);
            if (ok) onDelete(category);
            return false;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : color.withOpacity(0.12),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: color.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar — renkli initial
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          // Mahsulotlar soni
                          _Badge(
                            label: '${category.productCount} ${l10n.products}',
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          // Status
                          _StatusBadge(isActive: isActive, l10n: l10n),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tugmalar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: () => onEdit(category),
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      onTap: () async {
                        final ok = await _showDeleteDialog(context);
                        if (ok) onDelete(category);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _DeleteDialog(
            name: category.name,
            l10n: l10n,
          ),
        ) ??
        false;
  }
}

// ─── Swipe Background ───
class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment align;

  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: align,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Icon Button ───
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

// ─── Badge ───
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Status Badge ───
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final AppLocalizations l10n;

  const _StatusBadge({required this.isActive, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? l10n.active : l10n.inactive,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete Dialog ───
class _DeleteDialog extends StatelessWidget {
  final String name;
  final AppLocalizations l10n;

  const _DeleteDialog({required this.name, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.confirmDelete,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"$name"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      l10n.no,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      l10n.delete,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
