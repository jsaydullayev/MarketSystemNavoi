import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/registration_request.dart';

/// Payload returned by the approve dialog. The console screen uses it to
/// build the backend payload.
class ApproveResult {
  ApproveResult({
    required this.username,
    required this.password,
    required this.marketName,
    this.subdomain,
  });
  final String username;
  final String password;
  final String marketName;
  final String? subdomain;
}

class ApproveRequestDialog extends StatefulWidget {
  const ApproveRequestDialog({super.key, required this.request});
  final RegistrationRequest request;

  @override
  State<ApproveRequestDialog> createState() => _ApproveRequestDialogState();
}

class _ApproveRequestDialogState extends State<ApproveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _subdomainController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _marketNameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Server-side ApproveAsync enforces username ≥3 / password ≥8 / non-empty
    // market name + per-market unique. We pre-validate the obvious cases here
    // so the operator gets immediate feedback without a round trip.
    Navigator.pop(
      context,
      ApproveResult(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        marketName: _marketNameController.text.trim(),
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
      title: Text(l10n.superAdminApproveTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Echo the applicant so the operator can sanity-check before
                // creating an Owner — eliminates the "I approved the wrong row"
                // mistake when the queue is long.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.request.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(widget.request.phone,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
          icon: const Icon(Icons.check),
          label: Text(l10n.superAdminApprove),
        ),
      ],
    );
  }
}
