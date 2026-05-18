// Register screen — public sign-up form. Collects only Full Name + Phone;
// username/password/market name are set by a SuperAdmin when they approve the
// request from the hidden console. Migrated to the new design system while
// preserving all business logic (RegistrationRequestService, phone mask
// formatter, success dialog, rate-limit handling, l10n strings).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/services/http_service.dart';
import '../../../../data/services/registration_request_service.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final RegistrationRequestService _service =
      RegistrationRequestService(HttpService());

  bool _submitting = false;
  final _phoneFormatter = _PhoneMaskFormatter();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);

    final l10n = AppLocalizations.of(context)!;

    // Strip the visual mask so the backend sees the canonical digits + plus.
    final cleanPhone = _PhoneMaskFormatter.cleanForApi(_phoneController.text);

    final result = await _service.submit(
      fullName: _fullNameController.text.trim(),
      phone: cleanPhone,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result.status) {
      case RegistrationRequestStatus.accepted:
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
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success ring with brand-light bg and brand-colored icon.
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              AppPrimaryButton(
                label: l10n.backToLogin,
                onPressed: () {
                  // Pop the dialog first, then the screen, but only if each
                  // route is still alive — the user may have backgrounded the
                  // app or hit hardware-back between the await and this tap.
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // viewInsets.bottom = pixels currently obscured by the soft keyboard.
    // Add it to scroll padding so the Submit button stays above the keyboard.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.brandLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl3,
                40,
                AppSpacing.xl3,
                AppSpacing.xl3 + keyboardInset,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(l10n),
                      const SizedBox(height: AppSpacing.xl3),
                      _buildFormCard(l10n),
                      const SizedBox(height: AppSpacing.xl),
                      _buildBackToLogin(l10n),
                      const SizedBox(height: AppSpacing.md),
                      _buildCopyright(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        // 64x64 brand tile with person-add icon (matches login's S-tile style).
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.registerScreenTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge().copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.registerScreenSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFieldLabel(l10n.fullName.toUpperCase()),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: _inputDecoration(
              hint: 'Masalan: Jahongir Saydullayev',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return l10n.enterFullName;
              if (trimmed.length < 2) return l10n.fullNameTooShort;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildFieldLabel(l10n.phone.toUpperCase()),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [_phoneFormatter],
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: _inputDecoration(
              hint: '+998 90 123 45 67',
              prefixIcon: Icons.phone_outlined,
            ),
            validator: (value) {
              final clean = _PhoneMaskFormatter.cleanForApi(value ?? '');
              if (clean.isEmpty) return l10n.enterPhone;
              if (!RegExp(r'^\+998[3-9]\d{8}$').hasMatch(clean)) {
                return l10n.invalidPhoneFormat;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: l10n.submitRegistrationRequest,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    "Arizangiz administrator tomonidan ko'rib chiqilgach, sizga login va parol yuboriladi.",
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.brandDark,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.labelSmall().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium().copyWith(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
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

  Widget _buildBackToLogin(AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: _submitting ? null : () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: AppColors.brand),
        child: Text(
          l10n.backToLogin,
          style: AppTextStyles.labelLarge().copyWith(
            fontSize: 13,
            color: AppColors.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Text(
      '© 2026 Strotech',
      textAlign: TextAlign.center,
      style: AppTextStyles.caption().copyWith(
        color: AppColors.textMuted,
        fontSize: 11,
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
    // collapse to nothing instead of re-rendering as "+998 9X".
    final isDeleting = newValue.text.length < oldValue.text.length;
    final digits = _justUzbekDigits(newValue.text, isDeleting: isDeleting);
    final masked = _format(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _justUzbekDigits(String raw, {bool isDeleting = false}) {
    final onlyDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.isEmpty) return '';
    // Country code already complete → strip it, keep up to 9 subscriber digits.
    if (onlyDigits.startsWith('998')) {
      final body = onlyDigits.length > 3 ? onlyDigits.substring(3) : '';
      return body.take(9);
    }
    // Mid-delete remnant of the country code: collapse so the mask stays at
    // "+998" rather than re-rendering "+998 99".
    if (isDeleting && onlyDigits.length <= 3) return '';
    return onlyDigits.take(9);
  }

  static String _format(String digits) {
    final buffer = StringBuffer(_prefix);
    if (digits.isEmpty) return buffer.toString();
    for (var i = 0; i < digits.length; i++) {
      // Group boundaries: after positions 2, 5, 7, 9 within the 9-digit body.
      if (i == 0 || i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Canonical form for the API: "+998XXXXXXXXX" (no spaces, no parentheses).
  /// Returns an empty string if the input has fewer than 9 subscriber digits.
  static String cleanForApi(String raw) {
    final digits = _justUzbekDigits(raw);
    if (digits.length != 9) return '';
    return '$_prefix$digits';
  }
}

extension _StringTake on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
