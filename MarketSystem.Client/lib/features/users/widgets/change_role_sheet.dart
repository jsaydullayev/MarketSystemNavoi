// lib/features/users/widgets/change_role_sheet.dart
//
// Owner-only "Rolni o'zgartirish" bottom sheet: the shared [RoleSelector]
// (Seller / Admin) preselected with the employee's current role, a warning
// note spelling out the side effects (logout + custom permissions reset), and
// a Save button that stays disabled until a different role is picked.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/users_service.dart';
import 'role_selector.dart';

class ChangeRoleSheet extends StatefulWidget {
  const ChangeRoleSheet({super.key, required this.user});

  final Map<String, dynamic> user;

  /// Opens the sheet. Resolves to the updated user on success, or null when
  /// the Owner closes it without changing the role.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Map<String, dynamic> user,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeRoleSheet(user: user),
    );
  }

  @override
  State<ChangeRoleSheet> createState() => _ChangeRoleSheetState();
}

class _ChangeRoleSheetState extends State<ChangeRoleSheet> {
  // Only the employee roles are assignable — Owner is never offered here.
  static const _roles = ['Seller', 'Admin'];

  late final String _currentRole;
  late String _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Match the picker's casing so the current role's card is preselected.
    final role = (widget.user['role'] ?? '').toString().toLowerCase();
    _currentRole = role == 'admin' ? 'Admin' : 'Seller';
    _selected = _currentRole;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final updated = await UsersService(authProvider: auth).changeRole(
        id: widget.user['id'].toString(),
        role: _selected,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        updated is Map ? Map<String, dynamic>.from(updated) : null,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $msg'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = (widget.user['fullName'] ?? '').toString();
    final username = (widget.user['username'] ?? '').toString();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.lg,
        AppSpacing.xl2,
        AppSpacing.xl4,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.changeRole, style: AppTextStyles.titleMedium()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$fullName · @$username',
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 13,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            RoleSelector(
              roles: _roles,
              selected: _selected,
              onChanged: (r) {
                if (!_loading) setState(() => _selected = r);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _WarningNote(text: l10n.changeRoleWarning),
            const SizedBox(height: AppSpacing.xl2),
            AppPrimaryButton(
              label: l10n.save,
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading || _selected == _currentRole
                  ? null
                  : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: l10n.cancel,
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber note listing what a role change does to the employee.
class _WarningNote extends StatelessWidget {
  const _WarningNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.warning,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
