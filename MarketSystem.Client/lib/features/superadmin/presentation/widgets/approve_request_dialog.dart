// Approve-registration dialog — migrated to the new design system. All
// live-validation logic (debounced availability checks, suggested
// subdomain) is preserved from the original.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/superadmin_service.dart';
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

/// State of a single live-validation field. `idle` = nothing typed yet,
/// `checking` = debounce or request in flight, `free` / `taken` = settled.
enum _CheckState { idle, checking, free, taken }

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

  // Debounce timer per field — restart it on every keystroke so the API
  // only fires when the operator pauses typing.
  Timer? _usernameTimer;
  Timer? _marketTimer;
  Timer? _subdomainTimer;
  static const _debounce = Duration(milliseconds: 400);

  _CheckState _usernameState = _CheckState.idle;
  _CheckState _marketState = _CheckState.idle;
  _CheckState _subdomainState = _CheckState.idle;

  // Server-supplied preview when the user hasn't typed a subdomain yet.
  String? _suggestedSubdomain;

  late final SuperAdminService _service;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _service = SuperAdminService(auth.httpService);

    _usernameController.addListener(_onUsernameChanged);
    _marketNameController.addListener(_onMarketChanged);
    _subdomainController.addListener(_onSubdomainChanged);
  }

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _marketTimer?.cancel();
    _subdomainTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _marketNameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final value = _usernameController.text.trim();
    _usernameTimer?.cancel();
    if (value.length < 3) {
      setState(() {
        _usernameState = _CheckState.idle;
        // Clear the suggestion too — it depends on the username.
        if (_subdomainController.text.trim().isEmpty) {
          _suggestedSubdomain = null;
        }
      });
      return;
    }
    setState(() => _usernameState = _CheckState.checking);
    _usernameTimer =
        Timer(_debounce, () => _checkAvailability(usernameQuery: value));
  }

  void _onMarketChanged() {
    final value = _marketNameController.text.trim();
    _marketTimer?.cancel();
    if (value.length < 3) {
      setState(() => _marketState = _CheckState.idle);
      return;
    }
    setState(() => _marketState = _CheckState.checking);
    _marketTimer =
        Timer(_debounce, () => _checkAvailability(marketQuery: value));
  }

  void _onSubdomainChanged() {
    final value = _subdomainController.text.trim().toLowerCase();
    _subdomainTimer?.cancel();
    if (value.isEmpty) {
      // Fell back to the auto-suggestion — re-query so the suggestion shows.
      setState(() => _subdomainState = _CheckState.idle);
      final username = _usernameController.text.trim();
      if (username.length >= 3) {
        _subdomainTimer = Timer(
          _debounce,
          () => _checkAvailability(usernameQuery: username),
        );
      }
      return;
    }
    setState(() => _subdomainState = _CheckState.checking);
    _subdomainTimer =
        Timer(_debounce, () => _checkAvailability(subdomainQuery: value));
  }

  Future<void> _checkAvailability({
    String? usernameQuery,
    String? marketQuery,
    String? subdomainQuery,
  }) async {
    final result = await _service.checkAvailability(
      username: usernameQuery,
      marketName: marketQuery,
      subdomain: subdomainQuery,
    );
    if (!mounted) return;

    // The user may have typed more characters while we were waiting —
    // discard a stale response so the indicator never contradicts the field.
    final stillCurrent = (usernameQuery == null ||
            _usernameController.text.trim() == usernameQuery) &&
        (marketQuery == null ||
            _marketNameController.text.trim() == marketQuery) &&
        (subdomainQuery == null ||
            _subdomainController.text.trim().toLowerCase() ==
                subdomainQuery);
    if (!stillCurrent) return;

    if (result.status != SuperAdminOpStatus.success || result.data == null) {
      setState(() {
        if (usernameQuery != null) _usernameState = _CheckState.idle;
        if (marketQuery != null) _marketState = _CheckState.idle;
        if (subdomainQuery != null) _subdomainState = _CheckState.idle;
      });
      return;
    }

    setState(() {
      final data = result.data!;
      if (usernameQuery != null && data['usernameAvailable'] is bool) {
        _usernameState = (data['usernameAvailable'] as bool)
            ? _CheckState.free
            : _CheckState.taken;
      }
      if (marketQuery != null && data['marketNameAvailable'] is bool) {
        _marketState = (data['marketNameAvailable'] as bool)
            ? _CheckState.free
            : _CheckState.taken;
      }
      if (subdomainQuery != null && data['subdomainAvailable'] is bool) {
        _subdomainState = (data['subdomainAvailable'] as bool)
            ? _CheckState.free
            : _CheckState.taken;
      }
      if (data['suggestedSubdomain'] is String) {
        _suggestedSubdomain = data['suggestedSubdomain'] as String;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameState == _CheckState.taken ||
        _marketState == _CheckState.taken ||
        _subdomainState == _CheckState.taken) {
      // Server would reject anyway — bail loudly so the operator can fix it.
      return;
    }
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

  Widget? _suffixForState(_CheckState state) {
    switch (state) {
      case _CheckState.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _CheckState.free:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case _CheckState.taken:
        return const Icon(Icons.error_outline, color: AppColors.danger);
      case _CheckState.idle:
        return null;
    }
  }

  InputDecoration _decoration({
    required IconData prefix,
    required String hint,
    Widget? suffixIcon,
    String? errorText,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium().copyWith(
        color: AppColors.textMuted,
        fontSize: 15,
      ),
      prefixIcon:
          Icon(prefix, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      errorText: errorText,
      helperText: helper,
      helperStyle: AppTextStyles.bodySmall().copyWith(fontSize: 12),
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
    );
  }

  String? _errorTextForState(_CheckState state, String takenMessage) =>
      state == _CheckState.taken ? takenMessage : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Decide what to show as the live subdomain preview. If the user typed
    // their own value we echo it back; otherwise we fall back to the
    // server-suggested auto-generated one.
    final typedSubdomain = _subdomainController.text.trim().toLowerCase();
    final previewSubdomain =
        typedSubdomain.isNotEmpty ? typedSubdomain : _suggestedSubdomain;

    final disabled = _usernameState == _CheckState.taken ||
        _marketState == _CheckState.taken ||
        _subdomainState == _CheckState.taken;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          l10n.superAdminApproveTitle,
                          style: AppTextStyles.titleMedium(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.fullName,
                          style: AppTextStyles.labelLarge(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.request.phone,
                          style: AppTextStyles.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Label(l10n.username),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      prefix: Icons.person_outline,
                      hint: 'username',
                      suffixIcon: _suffixForState(_usernameState),
                      errorText: _errorTextForState(
                        _usernameState,
                        "'${_usernameController.text.trim()}' allaqachon band",
                      ),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return l10n.enterUsername;
                      if (t.length < 3) return l10n.usernameMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Label(l10n.password),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      prefix: Icons.lock_outline,
                      hint: 'Min. 8 belgi',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.enterPassword;
                      if (v.length < 8) {
                        return l10n.superAdminPasswordMinLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Label(l10n.marketName),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _marketNameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      prefix: Icons.storefront_outlined,
                      hint: "Do'kon nomi",
                      suffixIcon: _suffixForState(_marketState),
                      errorText: _errorTextForState(
                        _marketState,
                        "'${_marketNameController.text.trim()}' nomli do'kon allaqachon mavjud",
                      ),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return l10n.enterMarketName;
                      if (t.length < 3) return l10n.marketNameTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Label(l10n.superAdminSubdomainOptional),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _subdomainController,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      prefix: Icons.language_outlined,
                      hint: 'subdomain (ixtiyoriy)',
                      suffixIcon: _suffixForState(_subdomainState),
                      helper: l10n.superAdminSubdomainHint,
                      errorText: _errorTextForState(
                        _subdomainState,
                        "'$typedSubdomain' subdomeni band",
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  // Live preview of the resolved subdomain — shows what URL the
                  // owner will actually log in at, even if the field is empty.
                  if (previewSubdomain != null &&
                      previewSubdomain.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppTextStyles.bodySmall().copyWith(
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: typedSubdomain.isEmpty
                                        ? 'Avto: '
                                        : 'URL: ',
                                  ),
                                  TextSpan(
                                    text: '$previewSubdomain.strotech.uz',
                                    style: AppTextStyles.bodySmall().copyWith(
                                      color: AppColors.brand,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l10n.superAdminApprove,
                          icon: Icons.check,
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
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}
