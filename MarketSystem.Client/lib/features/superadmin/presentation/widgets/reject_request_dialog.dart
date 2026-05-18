// Reject-request dialog — migrated to the new design system. Operator
// supplies a reason; the parent screen handles the actual reject API call.

import 'package:flutter/material.dart';

import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/registration_request.dart';

/// Returns the reason text, or null if the operator cancelled.
class RejectRequestDialog extends StatefulWidget {
  const RejectRequestDialog({super.key, required this.request});
  final RegistrationRequest request;

  @override
  State<RejectRequestDialog> createState() => _RejectRequestDialogState();
}

class _RejectRequestDialogState extends State<RejectRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
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
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        l10n.superAdminRejectTitle,
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
                const SizedBox(height: AppSpacing.xl),
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
                Text(
                  l10n.superAdminRejectReason.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 500,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: l10n.superAdminRejectReasonHint,
                    hintStyle: AppTextStyles.bodyMedium().copyWith(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg + 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md + 2),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md + 2),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md + 2),
                      borderSide: const BorderSide(
                          color: AppColors.brand, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return l10n.superAdminRejectReasonRequired;
                    return null;
                  },
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
                      child: AppDangerButton(
                        label: l10n.superAdminReject,
                        icon: Icons.close,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
