// Credentials hand-off dialog — migrated to the new design system. Shown
// after a successful approval so the SuperAdmin can copy the credentials they
// just chose and pass them to the new owner out of band (SMS, phone call).
// The password is NOT stored anywhere — once this dialog closes there is no
// way to recover it. The dialog auto-hides the password until revealed,
// mirroring how a manager would treat written-down secrets.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

class CredentialsHandoffDialog extends StatefulWidget {
  const CredentialsHandoffDialog({
    super.key,
    required this.username,
    required this.password,
    required this.marketName,
  });

  final String username;
  final String password;
  final String marketName;

  @override
  State<CredentialsHandoffDialog> createState() =>
      _CredentialsHandoffDialogState();
}

class _CredentialsHandoffDialogState extends State<CredentialsHandoffDialog> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
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
                      Icons.lock_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      l10n.superAdminCredentialsTitle,
                      style: AppTextStyles.titleMedium(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.superAdminCredentialsSubtitle(widget.marketName),
                style: AppTextStyles.bodySmall(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _CredentialRow(
                label: l10n.username,
                value: widget.username,
                obscure: false,
              ),
              const SizedBox(height: AppSpacing.md),
              _CredentialRow(
                label: l10n.password,
                value: widget.password,
                obscure: !_passwordVisible,
                onToggleObscure: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.superAdminCredentialsWarning,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: context.colors.text,
                          fontSize: 12,
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
                      label: l10n.superAdminCredentialsCopyBoth,
                      icon: Icons.copy,
                      onPressed: () async {
                        final payload =
                            '${widget.username}\n${widget.password}\n${widget.marketName}';
                        await Clipboard.setData(ClipboardData(text: payload));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.superAdminCredentialsCopied),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppPrimaryButton(
                      label: l10n.superAdminCredentialsDone,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.obscure,
    this.onToggleObscure,
  });

  final String label;
  final String value;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  obscure ? '•' * value.length : value,
                  style: AppTextStyles.labelLarge().copyWith(
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleObscure != null)
            IconButton(
              tooltip: obscure ? 'Ko\'rsatish' : 'Yashirish',
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.colors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          IconButton(
            tooltip: 'Nusxalash',
            icon: Icon(
              Icons.copy_outlined,
              color: context.colors.textSecondary,
              size: 20,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
            },
          ),
        ],
      ),
    );
  }
}
