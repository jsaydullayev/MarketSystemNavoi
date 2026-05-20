// lib/features/categories/screens/category_bottom_sheet.dart
//
// Add / edit category bottom sheet, mirroring the demo's add/edit category
// modal (see `id="page-prod-cats"` interactions):
// - Sheet handle bar (40x4)
// - Title: "Yangi kategoriya" / "Kategoriyani tahrirlash"
// - Emoji picker grid (common category emojis, tap-to-select)
// - KATEGORIYA NOMI input (uppercase label via AppTextInput)
// - TAVSIF (optional) input
// - Faol/Nofaol toggle — only shown when editing
// - AppPrimaryButton "Saqlash"
//
// Business logic preserved:
// - `_save()` still calls `CategoryService.createCategory` /
//   `CategoryService.updateCategory` with the same params.
// - Validation: name required (trimmed-empty -> l10n.fillIn).
// - Error snackbars unchanged.
// - `_isActive` only mutable in edit-mode; defaults to true on create.
// - Selected emoji is purely visual (not persisted) until the model gains
//   an icon field server-side.

// `Characters` (grapheme-aware string handling) is re-exported by
// flutter/material, so no separate `package:characters` import is needed.
import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/product_category_model.dart';
import '../../../data/services/category_service.dart';
import '../../../l10n/app_localizations.dart';

class CategoryBottomSheet extends StatefulWidget {
  final ProductCategoryModel? category;

  const CategoryBottomSheet({super.key, this.category});

  @override
  State<CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<CategoryBottomSheet> {
  // Default suggestion grid — common Uzbek-market categories. The user can
  // type any other emoji (or any unicode glyph) in the custom-emoji input
  // below the grid; that value becomes the 17th slot and is auto-selected.
  static const List<String> _defaultEmojis = [
    '📦', '🥤', '🥖', '🚬', '🧴', '🍎', '🥩', '🥛',
    '🍬', '🍞', '🧃', '🍫', '🥚', '🧀', '🧂', '🛒',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customEmojiCtrl = TextEditingController();
  String _selectedEmoji = '📦';

  /// User-typed emoji that's not in the [_defaultEmojis] grid. When set, it
  /// is rendered as an extra tile in the picker so the user can confirm
  /// their custom choice visually.
  String? _customEmoji;

  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.category!.name;
      _descCtrl.text = widget.category!.description ?? '';
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customEmojiCtrl.dispose();
    super.dispose();
  }

  /// Apply the user's custom-emoji input. Strips whitespace and only keeps
  /// the first user-perceived character so a long paste collapses to a
  /// single glyph. Empty input clears the custom slot.
  void _applyCustomEmoji() {
    final raw = _customEmojiCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _customEmoji = null;
        // Fall back to the default if we were on the custom slot.
        if (!_defaultEmojis.contains(_selectedEmoji)) {
          _selectedEmoji = '📦';
        }
      });
      return;
    }
    // Take the first run of code units that doesn't fragment a surrogate
    // pair — typical emoji are 2 UTF-16 code units; flags/ZWJ sequences
    // can be longer but we accept whatever the user pasted as-is.
    final glyph = raw.characters.isNotEmpty ? raw.characters.first : raw;
    setState(() {
      _customEmoji = glyph;
      _selectedEmoji = glyph;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final service = CategoryService(authProvider: auth);

      if (!_isEditing) {
        await service.createCategory(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        );
      } else {
        await service.updateCategory(
          id: widget.category!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          isActive: _isActive,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg - 2),
          ),
          margin: const EdgeInsets.all(AppSpacing.xl),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl3,
        0,
        AppSpacing.xl3,
        AppSpacing.xl3 + bottomPadding,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle bar (40x4)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xl2,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? l10n.editCategory : l10n.addCategory,
                          style: AppTextStyles.titleMedium(),
                        ),
                        Text(
                          _isEditing
                              ? widget.category!.name
                              : l10n.newCategory,
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl3),

              // Emoji picker
              Text(
                'EMOJI',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _EmojiPicker(
                // Default grid + the user-typed custom slot (when set).
                // The custom slot lives at the end so the default order is
                // preserved.
                options: [
                  ..._defaultEmojis,
                  if (_customEmoji != null) _customEmoji!,
                ],
                selected: _selectedEmoji,
                onSelect: (e) => setState(() => _selectedEmoji = e),
              ),
              const SizedBox(height: AppSpacing.md),
              // Custom-emoji input — paste / type any glyph and tap "Add" to
              // promote it to a 17th tile in the grid above. Useful when
              // the user wants something outside the curated default list.
              _CustomEmojiField(
                controller: _customEmojiCtrl,
                onApply: _applyCustomEmoji,
                hint: l10n.customEmojiHint,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name input
              AppTextInput(
                controller: _nameCtrl,
                label: l10n.categoryName,
                hint: l10n.categoryName,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fillIn : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description (optional)
              AppTextInput(
                controller: _descCtrl,
                label: l10n.description,
                hint: l10n.description,
              ),

              // Active / inactive toggle — edit only
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.lg),
                _ActiveToggle(
                  isActive: _isActive,
                  label: l10n.isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],

              const SizedBox(height: AppSpacing.xl3),

              // Saqlash
              AppPrimaryButton(
                label: l10n.save,
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline "type your own emoji" field. Hands off to [onApply] when the user
/// taps the Add button or submits — the parent collapses whatever glyph
/// they typed into one tile and selects it.
class _CustomEmojiField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final String hint;

  const _CustomEmojiField({
    required this.controller,
    required this.onApply,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            // No keyboardType override — on mobile this lets the OS emoji
            // keyboard or the long-press emoji input naturally surface.
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall().copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md + 2,
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
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => onApply(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Grid of selectable emojis. Selected one gets a brand-tinted background.
class _EmojiPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _EmojiPicker({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: options.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.brandLight : AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              border: Border.all(
                color: isSelected ? AppColors.brand : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }
}

/// Tap-to-toggle active/inactive control matching the demo's pill switch.
class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final String label;
  final ValueChanged<bool> onChanged;

  const _ActiveToggle({
    required this.isActive,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + 2,
          vertical: AppSpacing.lg + 1,
        ),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.successLight : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isActive
                ? AppColors.success.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_outline_rounded,
              color: isActive ? AppColors.success : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isActive ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    isActive ? AppColors.success : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isActive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
