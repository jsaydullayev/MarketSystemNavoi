// lib/features/users/widgets/add_user_sheet.dart
//
// Add-staff bottom sheet, mapped to demo `id="page-staff-add"`:
// - ISM-FAMILIYA + USERNAME + parol + tasdiqlash inputs (uppercase labels)
// - 2-card role picker (Admin / Seller) — semantic role colours
// - Brand-light info card explaining SMS handoff
// - Primary "Saqlash" + secondary "Bekor qilish" buttons
//
// Business logic preserved: same validators, same `UsersService.createUser`
// call, same success/error snackbars, same role gating from AuthProvider.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/services/users_service.dart';

class AddUserSheet extends StatefulWidget {
  const AddUserSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddUserSheet(),
    );
  }

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

// Role chip colors mirror the staff list/detail so the picker chip reads
// consistently across the feature. Defined here so the role picker doesn't
// have to import the card widget.
const _adminBg = Color(0xFFF3E8FF);
const _adminFg = Color(0xFF7C3AED);
const _sellerBg = Color(0xFFECFDF5);
const _sellerFg = Color(0xFF047857);

class _AddUserSheetState extends State<AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  String _role = 'Seller';
  bool _loading = false;
  bool _obscPass = true;
  bool _obscConf = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  // Role gating: Owner can create any role, Admin can create Admin/Seller,
  // everyone else only Seller. Preserved from the legacy widget.
  List<String> get _roles {
    final r = Provider.of<AuthProvider>(context, listen: false).user?['role'];
    if (r == 'Owner') return ['Seller', 'Admin', 'Owner'];
    if (r == 'Admin') return ['Seller', 'Admin'];
    return ['Seller'];
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = await UsersService(authProvider: auth).createUser(
        fullName: _nameCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      _showSuccess(user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.error}: $e'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  void _showSuccess(dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Required so the sheet can grow past 50% of the screen — without this
      // the success card's 3 info rows + warning panel + button overflow
      // the default half-screen height, producing the yellow-striped
      // "BOTTOM OVERFLOWED BY 56 PIXELS" indicator we saw on the Users
      // page in 2026-05-19.
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            _Header(
              title: l10n.newUser,
              icon: Icons.person_add_rounded,
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl2,
                  AppSpacing.xs,
                  AppSpacing.xl2,
                  0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetField(
                        controller: _nameCtrl,
                        label: l10n.fullName,
                        icon: Icons.person_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.nameRequired
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SheetField(
                        controller: _userCtrl,
                        label: l10n.username,
                        icon: Icons.account_circle_rounded,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.usernameRequired;
                          }
                          if (v.length < 3) return l10n.usernameMinLength;
                          if (v.contains(' ')) return l10n.noSpacesAllowed;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SheetField(
                        controller: _passCtrl,
                        label: l10n.password,
                        icon: Icons.lock_rounded,
                        obscure: _obscPass,
                        onToggle: () => setState(() => _obscPass = !_obscPass),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (v.length < 6) return l10n.passwordMinLength;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SheetField(
                        controller: _confCtrl,
                        label: l10n.passwordConfirm,
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscConf,
                        onToggle: () => setState(() => _obscConf = !_obscConf),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.confirmPasswordRequired;
                          }
                          if (v != _passCtrl.text) return l10n.passwordMismatch;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _RoleSelector(
                        roles: _roles,
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _CredentialsInfo(),
                      const SizedBox(height: AppSpacing.xl3),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                0,
                AppSpacing.xl2,
                AppSpacing.xl4 - 4,
              ),
              child: Column(
                children: [
                  AppPrimaryButton(
                    label: l10n.save,
                    icon: Icons.check_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialsInfo extends StatelessWidget {
  const _CredentialsInfo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.brandDark,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.giveCredentialsToUser,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColors.brandDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({required this.user});
  final dynamic user;

  Widget _row(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
        ),
        child: Row(children: [
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // On wide screens (tablet / web) clamp the sheet to a comfortable card
    // width so the rows don't sprawl across the entire window. On phones
    // the maxWidth is wider than the viewport so the layout is unchanged.
    final mediaQ = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQ.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          // Cap the sheet height to ~90% of the screen and let the body
          // scroll. Combined with `isScrollControlled: true` on the
          // showModalBottomSheet call, this stops the success card from
          // overflowing on shorter viewports.
          maxHeight: mediaQ.size.height * 0.9,
          maxWidth: 520,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl2,
            AppSpacing.lg,
            AppSpacing.xl2,
            AppSpacing.xl4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Handle(),
              const SizedBox(height: AppSpacing.xl2),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.userCreatedSuccess,
                style: AppTextStyles.titleMedium(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl2),
              _row(l10n.fullName, user['fullName'] ?? ''),
              _row(l10n.username, '@${user['username'] ?? ''}'),
              _row(l10n.role, user['role'] ?? ''),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.giveCredentialsToUser,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                label: l10n.understand,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xs,
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.icon,
    required this.onClose,
  });
  final String title;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.brand, size: 20),
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(title, style: AppTextStyles.titleMedium()),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textMuted,
          ),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            filled: true,
            fillColor: AppColors.inputFill,
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
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// 2-card (Admin + Seller, plus Owner if role-gated) role picker matching the
/// demo `.role-picker` block: each card is colour-tinted with the role's
/// semantic palette and shows an icon + role name.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  final List<String> roles;
  final String selected;
  final ValueChanged<String> onChanged;

  ({Color bg, Color fg, IconData icon, String desc}) _roleSpec(
    AppLocalizations l10n,
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (
          bg: AppColors.brandLight,
          fg: AppColors.brandDark,
          icon: Icons.workspace_premium_rounded,
          desc: l10n.roleOwnerDesc,
        );
      case 'admin':
        return (
          bg: _adminBg,
          fg: _adminFg,
          icon: Icons.admin_panel_settings_rounded,
          desc: l10n.roleAdminDesc,
        );
      case 'seller':
      default:
        return (
          bg: _sellerBg,
          fg: _sellerFg,
          icon: Icons.storefront_rounded,
          desc: l10n.roleSellerDesc,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.role.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: roles.map((r) {
            final sel = selected == r;
            final spec = _roleSpec(l10n, r);
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: r != roles.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? spec.bg : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: sel ? spec.fg : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        spec.icon,
                        color: sel ? spec.fg : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        r,
                        style: AppTextStyles.bodyMedium().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: sel ? spec.fg : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.desc,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall().copyWith(
                          fontSize: 10,
                          color: sel
                              ? spec.fg.withValues(alpha: 0.8)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
