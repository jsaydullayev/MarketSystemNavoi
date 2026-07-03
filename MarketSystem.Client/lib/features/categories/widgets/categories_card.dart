// lib/features/categories/widgets/categories_card.dart
//
// Category row card matching demo `id="page-prod-cats"` (.cat-row):
// - Drag handle (`⋮⋮`) on the left for reorder UX
// - 40x40 emoji tile (gray-50 bg, 10px radius) with category initial / emoji
// - Info column: name (13px / 700) + "X ta mahsulot" count (11px muted)
// - Trailing `⋯` menu button (32x32) — opens a popup with Edit / Delete
//
// Business logic preserved:
// - `onEdit(category)` / `onDelete(category)` callbacks unchanged
// - Delete confirmation dialog unchanged
// - Swipe-to-edit / swipe-to-delete still wired via Dismissible
// - Status (active / inactive) still surfaced as a small text chip
//
// Light-mode only — dark-mode branches dropped per migration brief.

import 'package:flutter/material.dart';
import 'package:market_system_client/data/models/product_category_model.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class CategoryCard extends StatelessWidget {
  final ProductCategoryModel category;
  final AppLocalizations l10n;
  // Preserved for backwards compatibility with the screen call-site.
  // Migrated UI is light-only and ignores this flag.
  final bool isDark;
  final Function(ProductCategoryModel) onEdit;
  final Function(ProductCategoryModel) onDelete;
  // RBAC: categories.manage bo'lmasa, tahrirlash/o'chirish (menyu + swipe)
  // ko'rsatilmaydi. Standart true — eski chaqiruvlar buzilmaydi.
  final bool canManage;

  const CategoryCard({
    super.key,
    required this.category,
    required this.l10n,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.canManage = true,
  });

  // Fallback emoji guessed from the category name — used only for legacy
  // rows that have no saved `icon`. Matches the demo's 40x40 gray tile.
  String _emojiFor(String name) {
    if (name.isEmpty) return '📦';
    final lower = name.toLowerCase();
    if (lower.contains('suv') || lower.contains('ichim')) return '🥤';
    if (lower.contains('oziq') || lower.contains('non')) return '🥖';
    if (lower.contains('tamak') || lower.contains('sigaret')) return '🚬';
    if (lower.contains('kimyo') || lower.contains('maishiy')) return '🧴';
    if (lower.contains('meva') || lower.contains('sabzavot')) return '🍎';
    if (lower.contains('go\'sht') || lower.contains('gosht')) return '🥩';
    if (lower.contains('sut') || lower.contains('tvorog')) return '🥛';
    if (lower.contains('shirin') || lower.contains('konfet')) return '🍬';
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive;
    // Prefer the user-picked icon; fall back to a name guess for legacy rows.
    final categoryIcon = category.icon;
    final emoji = (categoryIcon != null && categoryIcon.isNotEmpty)
        ? categoryIcon
        : _emojiFor(category.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: Key('cat_${category.id}'),
        background: _SwipeBg(
          color: context.colors.brand,
          icon: Icons.edit_rounded,
          align: Alignment.centerLeft,
        ),
        secondaryBackground: const _SwipeBg(
          color: AppColors.danger,
          icon: Icons.delete_rounded,
          align: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (!canManage) return false;
          if (direction == DismissDirection.startToEnd) {
            onEdit(category);
            return false;
          }
          final ok = await _showDeleteDialog(context);
          if (ok) onDelete(category);
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg - 2),
            border: Border.all(color: context.colors.border, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Drag handle (⋮⋮) — informational; actual reorder hook is TBD.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 20,
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // 40x40 emoji tile (gray bg, 10px radius)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Info column: name + product count + (optional) status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.bodySmall().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${category.productCount} ${l10n.products.toLowerCase()}',
                          style: AppTextStyles.caption().copyWith(
                            fontSize: 11,
                            color: context.colors.textMuted,
                            letterSpacing: 0,
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '• ${l10n.inactive}',
                            style: AppTextStyles.caption().copyWith(
                              fontSize: 11,
                              color: context.colors.textMuted,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 32x32 ⋯ menu button — faqat boshqaruv ruxsati bilan ko'rinadi.
              if (canManage)
                _MenuButton(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit(category);
                    } else if (value == 'delete') {
                      final ok = await _showDeleteDialog(context);
                      if (ok) onDelete(category);
                    }
                  },
                  l10n: l10n,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _DeleteDialog(name: category.name, l10n: l10n),
        ) ??
        false;
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment align;

  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
      ),
      alignment: align,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final AppLocalizations l10n;

  const _MenuButton({required this.onSelected, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        tooltip: '',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: context.colors.textMuted,
        ),
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          side: BorderSide(color: context.colors.border),
        ),
        onSelected: onSelected,
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(l10n.edit, style: AppTextStyles.bodyMedium()),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.delete,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColors.danger,
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

class _DeleteDialog extends StatelessWidget {
  final String name;
  final AppLocalizations l10n;

  const _DeleteDialog({required this.name, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
      ),
      backgroundColor: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl2 - 2),
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.confirmDelete,
              style: AppTextStyles.titleMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '"$name"',
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg + 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      ),
                      side: BorderSide(color: context.colors.border),
                    ),
                    child: Text(
                      l10n.no,
                      style: AppTextStyles.labelLarge().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg + 1,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      ),
                    ),
                    child: Text(
                      l10n.delete,
                      style: AppTextStyles.labelLarge().copyWith(
                        color: Colors.white,
                      ),
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
