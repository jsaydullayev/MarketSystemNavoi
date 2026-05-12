import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/http_service.dart';
import '../../../../data/services/registration_request_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Public sign-up screen.
///
/// Collects only Full Name + Phone — username, password, and market name are
/// chosen by a SuperAdmin when they approve the request from the hidden
/// console. This intentionally keeps the public-facing form thin so a casual
/// visitor can submit interest without committing to credentials.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final RegistrationRequestService _service =
      RegistrationRequestService(HttpService());

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  bool _submitting = false;

  // Visual mask "+998 ## ### ## ##" — backend normalises any reasonable Uzbek
  // format but the mask removes ambiguity for the user typing it in.
  final _phoneFormatter = _PhoneMaskFormatter();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);

    final l10n = AppLocalizations.of(context)!;

    // Strip the visual mask so the backend sees the canonical digits + plus.
    // The server still normalises everything, but sending clean values keeps
    // the request bodies tidy in logs and replay tools.
    final cleanPhone = _PhoneMaskFormatter.cleanForApi(_phoneController.text);

    final result = await _service.submit(
      fullName: _fullNameController.text.trim(),
      phone: cleanPhone,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result.status) {
      case RegistrationRequestStatus.accepted:
        // If the backend returned a server-side validation hint (only happens
        // on 400 with our format-error keywords), show it as an ERROR snackbar
        // so a Russian-speaking user doesn't see Uzbek text inside a green
        // success dialog. A null message means the queue accepted the request
        // (or silently deduped) — show the localised success copy.
        if (result.message != null) {
          _showSnack(result.message!, isError: true);
        } else {
          await _showSuccessDialog(l10n.registrationSent);
        }
        break;
      case RegistrationRequestStatus.rateLimited:
        _showSnack(
          l10n.registrationRateLimited(result.retryAfterSeconds ?? 60),
          isError: true,
        );
        break;
      case RegistrationRequestStatus.failure:
        _showSnack(l10n.registrationFailedRetry, isError: true);
        break;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop the dialog first, then the screen, but only if each
                  // route is still alive — the user may have backgrounded the
                  // app or hit hardware-back between the await and this tap,
                  // in which case Navigator would throw.
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
                style: AppTheme.primaryButtonStyle,
                child: Text(l10n.backToLogin),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // viewInsets.bottom = pixels currently obscured by the soft keyboard.
    // We add it to the scroll padding so the Submit button stays above the
    // keyboard on small phones instead of being clipped.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + keyboardInset),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.registerScreenTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.registerScreenSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.fullName,
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return l10n.enterFullName;
                              if (trimmed.length < 2) return l10n.fullNameTooShort;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [_phoneFormatter],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.phone,
                              icon: Icons.phone_outlined,
                            ).copyWith(hintText: '+998 90 123 45 67'),
                            validator: (value) {
                              final clean = _PhoneMaskFormatter.cleanForApi(
                                value ?? '',
                              );
                              if (clean.isEmpty) return l10n.enterPhone;
                              // Real Uzbek mobile prefixes (current MNP-list):
                              //   33, 50, 55, 61, 62, 65-71, 73, 74, 77, 78,
                              //   88, 90-94, 95-99
                              // We just require the first digit after +998 to be
                              // a plausible operator first digit (3, 5, 6, 7, 8, 9).
                              // Tighter than `\d{9}` (which accepts a US number
                              // pasted into +998xxxxxxxxx) without rejecting any
                              // legitimate Uzbek subscriber.
                              if (!RegExp(r'^\+998[3-9]\d{8}$').hasMatch(clean)) {
                                return l10n.invalidPhoneFormat;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: AppTheme.primaryButtonStyle,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(l10n.submitRegistrationRequest),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                      child: Text(l10n.backToLogin),
                    ),
                    const SizedBox(height: 8),
                    const Text('© 2026 Market System', style: AppTheme.caption),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual-only mask: "+998 ## ### ## ##" (13 digits incl. country code, 17
/// chars when fully filled). Strips the user's typed prefix variants so the
/// canonical "+998..." appears in the field; the backend's NormalizePhone
/// accepts wider input but a tight mask makes the form less confusing.
class _PhoneMaskFormatter extends TextInputFormatter {
  static const String _prefix = '+998';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Direction matters for the country-code edge case: when the user is
    // deleting through "+998", a bare "99" or "9" left in the buffer should
    // collapse to nothing instead of re-rendering as "+998 9X". When the
    // user is typing fresh digits, the same bare digits should pass through
    // as the start of a subscriber number.
    final isDeleting = newValue.text.length < oldValue.text.length;
    final digits = _justUzbekDigits(newValue.text, isDeleting: isDeleting);
    final masked = _format(digits);
    return TextEditingValue(
      text: masked,
      // Caret to the end is the simplest correct policy — selection inside
      // a masked field surprises users anyway.
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  /// Extract the subscriber digits (max 9) from whatever the user typed,
  /// using the edit direction to disambiguate "+99" mid-delete from a
  /// freshly-typed "99". Without that signal the mask would "matonat bilan"
  /// re-inject the country code as subscriber digits and the user could
  /// never get back to an empty field.
  static String _justUzbekDigits(String raw, {bool isDeleting = false}) {
    final onlyDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.isEmpty) return '';
    // Country code already complete → strip it, keep up to 9 subscriber digits.
    if (onlyDigits.startsWith('998')) {
      final body = onlyDigits.length > 3 ? onlyDigits.substring(3) : '';
      return body.take(9);
    }
    // Mid-delete remnant of the country code (e.g. "+998" → "+99" → "+9"):
    // collapse so the mask stays at "+998" rather than re-rendering "+998 99".
    if (isDeleting && onlyDigits.length <= 3) return '';
    return onlyDigits.take(9);
  }

  static String _format(String digits) {
    final buffer = StringBuffer(_prefix);
    if (digits.isEmpty) return buffer.toString();
    for (var i = 0; i < digits.length; i++) {
      // Group boundaries: after positions 2, 5, 7, 9 (within the 9-digit body).
      if (i == 0 || i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Canonical form for the API: "+998XXXXXXXXX" (no spaces, no parentheses).
  /// Returns an empty string if the input has fewer than 9 digits after the
  /// country code, so callers can validate cleanly.
  static String cleanForApi(String raw) {
    final digits = _justUzbekDigits(raw);
    if (digits.length != 9) return '';
    return '$_prefix$digits';
  }
}

extension _StringTake on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
