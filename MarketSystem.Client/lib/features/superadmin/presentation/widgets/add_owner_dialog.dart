import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Payload returned by [AddOwnerDialog]. Mirrors the backend `CreateOwnerDto`.
class AddOwnerResult {
  AddOwnerResult({
    required this.fullName,
    required this.username,
    required this.password,
    required this.marketName,
    this.phone,
    this.subdomain,
  });
  final String fullName;
  final String username;
  final String password;
  final String marketName;
  final String? phone;
  final String? subdomain;
}

/// SuperAdmin-only form to provision a new Owner without an in-queue
/// registration request. Phone is optional — the SuperAdmin already has the
/// contact channel when they're using this flow.
class AddOwnerDialog extends StatefulWidget {
  const AddOwnerDialog({super.key});

  @override
  State<AddOwnerDialog> createState() => _AddOwnerDialogState();
}

class _AddOwnerDialogState extends State<AddOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _subdomainController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _marketNameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AddOwnerResult(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        marketName: _marketNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        subdomain: _subdomainController.text.trim().isEmpty
            ? null
            : _subdomainController.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.superAdminAddOwnerTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 2) return l10n.enterFullName;
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.superAdminPhoneOptional,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: '+998 90 123 45 67',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  decoration: InputDecoration(
                    labelText: l10n.username,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return l10n.enterUsername;
                    if (t.length < 3) return l10n.usernameMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.enterPassword;
                    if (v.length < 8) return l10n.superAdminPasswordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _marketNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.marketName,
                    prefixIcon: const Icon(Icons.store_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return l10n.enterMarketName;
                    if (t.length < 3) return l10n.marketNameTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subdomainController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.superAdminSubdomainOptional,
                    prefixIcon: const Icon(Icons.language_outlined),
                    helperText: l10n.superAdminSubdomainHint,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(l10n.superAdminAddOwner),
        ),
      ],
    );
  }
}
