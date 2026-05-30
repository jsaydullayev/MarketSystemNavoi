// Manually create an owner+market without a backing registration request —
// migrated to the new design system. Used when the SuperAdmin onboards a
// tenant out-of-band (phone, walk-in). Returns a [CreatedOwnerResult] so the
// console can show the credentials hand-off dialog right after.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/validators/password_validator.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/superadmin_service.dart';

class CreatedOwnerResult {
  CreatedOwnerResult({
    required this.username,
    required this.password,
    required this.marketName,
  });
  final String username;
  final String password;
  final String marketName;
}

class CreateOwnerDialog extends StatefulWidget {
  const CreateOwnerDialog({super.key});

  @override
  State<CreateOwnerDialog> createState() => _CreateOwnerDialogState();
}

class _CreateOwnerDialogState extends State<CreateOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _marketName = TextEditingController();
  final _subdomain = TextEditingController();
  String _language = 'uz';
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  // Live availability state per field — mirrors the Approve dialog so the
  // SuperAdmin gets immediate feedback instead of round-tripping the form.
  Timer? _userTimer, _marketTimer, _subdomainTimer;
  static const _debounce = Duration(milliseconds: 400);
  _Check _userState = _Check.idle;
  _Check _marketState = _Check.idle;
  _Check _subdomainState = _Check.idle;
  String? _suggestedSubdomain;

  late final SuperAdminService _service;

  @override
  void initState() {
    super.initState();
    _service = SuperAdminService(context.read<AuthProvider>().httpService);
    _username.addListener(_onUsernameChanged);
    _marketName.addListener(_onMarketChanged);
    _subdomain.addListener(_onSubdomainChanged);
  }

  @override
  void dispose() {
    _userTimer?.cancel();
    _marketTimer?.cancel();
    _subdomainTimer?.cancel();
    _fullName.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _marketName.dispose();
    _subdomain.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final v = _username.text.trim();
    _userTimer?.cancel();
    if (v.length < 3) {
      setState(() {
        _userState = _Check.idle;
        if (_subdomain.text.trim().isEmpty) _suggestedSubdomain = null;
      });
      return;
    }
    setState(() => _userState = _Check.checking);
    _userTimer = Timer(_debounce, () => _check(usernameQ: v));
  }

  void _onMarketChanged() {
    final v = _marketName.text.trim();
    _marketTimer?.cancel();
    if (v.length < 3) {
      setState(() => _marketState = _Check.idle);
      return;
    }
    setState(() => _marketState = _Check.checking);
    _marketTimer = Timer(_debounce, () => _check(marketQ: v));
  }

  void _onSubdomainChanged() {
    final v = _subdomain.text.trim().toLowerCase();
    _subdomainTimer?.cancel();
    if (v.isEmpty) {
      setState(() => _subdomainState = _Check.idle);
      final u = _username.text.trim();
      if (u.length >= 3) {
        _subdomainTimer = Timer(_debounce, () => _check(usernameQ: u));
      }
      return;
    }
    setState(() => _subdomainState = _Check.checking);
    _subdomainTimer = Timer(_debounce, () => _check(subdomainQ: v));
  }

  Future<void> _check({
    String? usernameQ,
    String? marketQ,
    String? subdomainQ,
  }) async {
    final res = await _service.checkAvailability(
      username: usernameQ,
      marketName: marketQ,
      subdomain: subdomainQ,
    );
    if (!mounted) return;
    final stillCurrent =
        (usernameQ == null || _username.text.trim() == usernameQ) &&
        (marketQ == null || _marketName.text.trim() == marketQ) &&
        (subdomainQ == null ||
            _subdomain.text.trim().toLowerCase() == subdomainQ);
    if (!stillCurrent) return;
    // Snapshot before the guard so flow analysis can promote it.
    final d = res.data;
    if (res.status != SuperAdminOpStatus.success || d == null) return;
    setState(() {
      if (usernameQ != null && d['usernameAvailable'] is bool) {
        _userState = (d['usernameAvailable'] as bool)
            ? _Check.free
            : _Check.taken;
      }
      if (marketQ != null && d['marketNameAvailable'] is bool) {
        _marketState = (d['marketNameAvailable'] as bool)
            ? _Check.free
            : _Check.taken;
      }
      if (subdomainQ != null && d['subdomainAvailable'] is bool) {
        _subdomainState = (d['subdomainAvailable'] as bool)
            ? _Check.free
            : _Check.taken;
      }
      if (d['suggestedSubdomain'] is String) {
        _suggestedSubdomain = d['suggestedSubdomain'] as String;
      }
    });
  }

  void _generatePassword() {
    final r = Random.secure();
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#\$%&*';
    const all = upper + lower + digits + symbols;
    final pw = StringBuffer()
      ..write(upper[r.nextInt(upper.length)])
      ..write(lower[r.nextInt(lower.length)])
      ..write(digits[r.nextInt(digits.length)])
      ..write(symbols[r.nextInt(symbols.length)]);
    for (var i = 0; i < 8; i++) {
      pw.write(all[r.nextInt(all.length)]);
    }
    setState(() {
      _password.text = pw.toString();
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userState == _Check.taken ||
        _marketState == _Check.taken ||
        _subdomainState == _Check.taken) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final res = await _service.createOwner(
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      marketName: _marketName.text.trim(),
      subdomain: _subdomain.text.trim().isEmpty
          ? null
          : _subdomain.text.trim().toLowerCase(),
      language: _language,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(
        CreatedOwnerResult(
          username: _username.text.trim(),
          password: _password.text,
          marketName: _marketName.text.trim(),
        ),
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = res.message ?? l10n.createOwnerFailed);
    }
  }

  Widget? _suffix(_Check s) {
    switch (s) {
      case _Check.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _Check.free:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case _Check.taken:
        return const Icon(Icons.error_outline, color: AppColors.danger);
      case _Check.idle:
        return null;
    }
  }

  InputDecoration _decoration(
    BuildContext context, {
    required IconData prefix,
    required String hint,
    Widget? suffixIcon,
    String? errorText,
    String? helper,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium().copyWith(
        color: context.colors.textMuted,
        fontSize: 15,
      ),
      prefixIcon: Icon(prefix, size: 20, color: context.colors.textSecondary),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: AppTextStyles.bodySmall(),
      errorText: errorText,
      helperText: helper,
      helperStyle: AppTextStyles.bodySmall().copyWith(fontSize: 12),
      filled: true,
      fillColor: context.colors.inputFill,
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
        borderSide: BorderSide(color: context.colors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typedSubdomain = _subdomain.text.trim().toLowerCase();
    final previewSubdomain = typedSubdomain.isNotEmpty
        ? typedSubdomain
        : _suggestedSubdomain;
    final disabled =
        _submitting ||
        _userState == _Check.taken ||
        _marketState == _Check.taken ||
        _subdomainState == _Check.taken;

    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.colors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.person_add_outlined,
                          color: context.colors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          l10n.addNewOwner,
                          style: AppTextStyles.titleMedium(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: context.colors.textSecondary,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.createOwnerSubtitle,
                    style: AppTextStyles.bodySmall(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_errorMessage case final msg?) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        msg,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _Section(l10n.ownerSection),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _fullName,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      context,
                      prefix: Icons.person_outline,
                      hint: l10n.fullNameRequired,
                    ),
                    validator: (v) => (v ?? '').trim().length < 2
                        ? l10n.nameRequiredShort
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phone,
                          style: AppTextStyles.bodyMedium().copyWith(
                            fontSize: 15,
                          ),
                          keyboardType: TextInputType.phone,
                          decoration: _decoration(
                            context,
                            prefix: Icons.phone_outlined,
                            hint: l10n.phoneHintExample,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return l10n.phoneRequiredShort;
                            if (s.replaceAll(RegExp(r'\D'), '').length < 9) {
                              return l10n.phoneFormatInvalid;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _languageDropdown(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _username,
                          style: AppTextStyles.bodyMedium().copyWith(
                            fontSize: 15,
                          ),
                          decoration: _decoration(
                            context,
                            prefix: Icons.alternate_email,
                            hint: l10n.usernameRequiredShort,
                            suffixIcon: _suffix(_userState),
                            errorText: _userState == _Check.taken
                                ? l10n.usernameTaken(_username.text.trim())
                                : null,
                            helper: l10n.minCharsShort,
                          ),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? l10n.minThreeCharsShort
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.bodyMedium().copyWith(
                            fontSize: 15,
                          ),
                          decoration: _decoration(
                            context,
                            prefix: Icons.lock_outline,
                            hint: l10n.passwordRequiredShort,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: context.colors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  tooltip: l10n.show,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.casino_outlined,
                                    color: context.colors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: _generatePassword,
                                  tooltip: l10n.generatePassword,
                                ),
                              ],
                            ),
                            helper: l10n.minEightCharsHelper,
                          ),
                          // G2 — was length-only; now enforces the full
                          // StrongPassword policy (8+ chars AND ≥1 letter
                          // AND ≥1 digit) so a SuperAdmin-minted Owner
                          // password can't be silently rejected by the
                          // backend on the next save.
                          validator: (v) =>
                              PasswordValidator.validateNew(v, context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(l10n.shopSection),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _marketName,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      context,
                      prefix: Icons.storefront_outlined,
                      hint: l10n.shopNameRequired,
                      suffixIcon: _suffix(_marketState),
                      errorText: _marketState == _Check.taken
                          ? l10n.marketNameTaken(_marketName.text.trim())
                          : null,
                    ),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? l10n.minThreeCharsShort
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  TextFormField(
                    controller: _subdomain,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      context,
                      prefix: Icons.language_outlined,
                      hint: l10n.subdomainOptionalShort,
                      suffixText: '.strotech.uz',
                      suffixIcon: _suffix(_subdomainState),
                      errorText: _subdomainState == _Check.taken
                          ? l10n.subdomainTaken(typedSubdomain)
                          : null,
                    ),
                  ),
                  if (previewSubdomain != null && previewSubdomain.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 13,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            typedSubdomain.isEmpty
                                ? l10n.autoLabel
                                : l10n.urlLabel,
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '$previewSubdomain.strotech.uz',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: AppTextStyles.bodySmall().copyWith(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: context.colors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: l10n.cancel,
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l10n.create,
                          icon: Icons.check,
                          isLoading: _submitting,
                          onPressed: disabled ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _language,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.translate_rounded,
          size: 20,
          color: context.colors.textSecondary,
        ),
        filled: true,
        fillColor: context.colors.inputFill,
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
          borderSide: BorderSide(color: context.colors.brand, width: 1.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'uz', child: Text("O'zbek")),
        DropdownMenuItem(value: 'ru', child: Text('Русский')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _language = v);
      },
    );
  }
}

enum _Check { idle, checking, free, taken }

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: AppTextStyles.caption().copyWith(
      color: context.colors.textSecondary,
    ),
  );
}
