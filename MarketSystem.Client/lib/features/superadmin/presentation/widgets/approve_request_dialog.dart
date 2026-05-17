import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
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

/// State of a single live-validation field. `null` = nothing typed yet,
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
        if (_subdomainController.text.trim().isEmpty) _suggestedSubdomain = null;
      });
      return;
    }
    setState(() => _usernameState = _CheckState.checking);
    _usernameTimer = Timer(_debounce, () => _checkAvailability(usernameQuery: value));
  }

  void _onMarketChanged() {
    final value = _marketNameController.text.trim();
    _marketTimer?.cancel();
    if (value.length < 3) {
      setState(() => _marketState = _CheckState.idle);
      return;
    }
    setState(() => _marketState = _CheckState.checking);
    _marketTimer = Timer(_debounce, () => _checkAvailability(marketQuery: value));
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
    _subdomainTimer = Timer(_debounce, () => _checkAvailability(subdomainQuery: value));
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
            _subdomainController.text.trim().toLowerCase() == subdomainQuery);
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
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _CheckState.free:
        return const Icon(Icons.check_circle, color: Color(0xFF137333));
      case _CheckState.taken:
        return const Icon(Icons.error_outline, color: Color(0xFFD93025));
      case _CheckState.idle:
        return null;
    }
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

    return AlertDialog(
      title: Text(l10n.superAdminApproveTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subdomainController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.superAdminSubdomainOptional,
                    prefixIcon: const Icon(Icons.language_outlined),
                    suffixIcon: _suffixForState(_subdomainState),
                    helperText: l10n.superAdminSubdomainHint,
                    errorText: _errorTextForState(
                      _subdomainState,
                      "'$typedSubdomain' subdomeni band",
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                // Live preview of the resolved subdomain — shows what URL the
                // owner will actually log in at, even if the field is empty.
                if (previewSubdomain != null && previewSubdomain.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.public,
                            size: 14, color: Color(0xFF5F6368)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                              ),
                              children: [
                                TextSpan(
                                  text: typedSubdomain.isEmpty
                                      ? 'Avto: '
                                      : 'URL: ',
                                ),
                                TextSpan(
                                  text: '$previewSubdomain.strotech.uz',
                                  style: const TextStyle(
                                    color: Color(0xFF1A73E8),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
          // Disable the submit button when any field is known-taken so the
          // operator can't fire a 400 on purpose.
          onPressed: (_usernameState == _CheckState.taken ||
                  _marketState == _CheckState.taken ||
                  _subdomainState == _CheckState.taken)
              ? null
              : _submit,
          icon: const Icon(Icons.check),
          label: Text(l10n.superAdminApprove),
        ),
      ],
    );
  }
}
