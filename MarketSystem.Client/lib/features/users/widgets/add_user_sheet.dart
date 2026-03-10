import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import '../../../data/services/users_service.dart';
import '../../../core/providers/auth_provider.dart';

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

class _AddUserSheetState extends State<AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  String _role = 'Seller';
  bool _loading = false, _obscPass = true, _obscConf = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

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
      setState(() => _loading = false);
      if (mounted) {
        Navigator.pop(context);
        _showSuccess(user);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: ' + e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showSuccess(dynamic user) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(user: user, isDark: dark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF151515) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Handle(),
          _Header(
            title: l10n.newUser,
            icon: Icons.person_add_rounded,
            onClose: () => Navigator.pop(context),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetField(
                      controller: _nameCtrl,
                      label: l10n.fullName,
                      icon: Icons.person_rounded,
                      isDark: dark,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.nameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _SheetField(
                      controller: _userCtrl,
                      label: l10n.username,
                      icon: Icons.account_circle_rounded,
                      isDark: dark,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return l10n.usernameRequired;
                        if (v.length < 3) return l10n.usernameMinLength;
                        if (v.contains(' ')) return l10n.noSpacesAllowed;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _SheetField(
                      controller: _passCtrl,
                      label: l10n.password,
                      icon: Icons.lock_rounded,
                      isDark: dark,
                      obscure: _obscPass,
                      onToggle: () => setState(() => _obscPass = !_obscPass),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return l10n.passwordRequired;
                        if (v.length < 6) return l10n.passwordMinLength;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _SheetField(
                      controller: _confCtrl,
                      label: l10n.passwordConfirm,
                      icon: Icons.lock_outline_rounded,
                      isDark: dark,
                      obscure: _obscConf,
                      onToggle: () => setState(() => _obscConf = !_obscConf),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return l10n.confirmPasswordRequired;
                        if (v != _passCtrl.text) return l10n.passwordMismatch;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _RoleSelector(
                      roles: _roles,
                      selected: _role,
                      isDark: dark,
                      onChanged: (r) => setState(() => _role = r),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l10n.generate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _SuccessSheet({required this.user, required this.isDark});

  Widget _row(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade500)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111111))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _Handle(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF059669), size: 32),
        ),
        const SizedBox(height: 16),
        Text(l10n.userCreatedSuccess,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111111))),
        const SizedBox(height: 20),
        _row('Ism', user['fullName'] ?? ''),
        _row('Username', '@' + (user['username'] ?? '')),
        _row('Rol', user['role'] ?? ''),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.giveCredentialsToUser,
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understand,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClose;
  const _Header(
      {required this.title, required this.icon, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : const Color(0xFF111111))),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close_rounded,
              color: dark ? Colors.white38 : Colors.grey.shade400),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark, obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111111)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  onPressed: onToggle)
              : null,
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      );
}

class _RoleSelector extends StatelessWidget {
  final List<String> roles;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.roles,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.role,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade500)),
        const SizedBox(height: 6),
        Row(
          children: roles.map((r) {
            final sel = selected == r;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: r != roles.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withOpacity(0.1)
                        : (isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? AppColors.primary : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text(r,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500))),
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
