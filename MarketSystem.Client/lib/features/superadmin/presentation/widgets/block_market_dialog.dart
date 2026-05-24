// Block / unblock a market — migrated to the new design system. Block
// requires a reason (subscription expired, ToS violation, etc.); the reason
// is shown to staff on their next login attempt and goes into the audit log.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/superadmin_service.dart';

class BlockMarketDialog extends StatefulWidget {
  const BlockMarketDialog({
    super.key,
    required this.marketId,
    required this.marketName,
    required this.currentlyBlocked,
    this.currentReason,
  });
  final int marketId;
  final String marketName;
  final bool currentlyBlocked;
  final String? currentReason;

  @override
  State<BlockMarketDialog> createState() => _BlockMarketDialogState();
}

class _BlockMarketDialogState extends State<BlockMarketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final reason = widget.currentReason;
    if (reason != null) {
      _reason.text = reason;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _doBlock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.blockMarket(
      marketId: widget.marketId,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(true);
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = res.message ?? l10n.blockFailed);
    }
  }

  Future<void> _doUnblock() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.unblockMarket(marketId: widget.marketId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(true);
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = res.message ?? l10n.unblockFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocking = !widget.currentlyBlocked;
    final accent = blocking ? AppColors.warning : AppColors.success;
    final accentBg = blocking ? AppColors.warningLight : AppColors.successLight;
    final icon = blocking ? Icons.block_outlined : Icons.lock_open_outlined;
    final title = blocking ? l10n.blockShopTitle : l10n.unblock;

    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
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
                        color: accentBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(title, style: AppTextStyles.titleMedium()),
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
                const SizedBox(height: AppSpacing.lg),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(),
                    children: [
                      TextSpan(
                        text: blocking ? l10n.blocking : l10n.unblocking,
                      ),
                      TextSpan(
                        text: widget.marketName,
                        style: AppTextStyles.labelLarge(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (blocking) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.blockImmediateInfo,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: context.colors.text,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.blockReasonRequired,
                    style: AppTextStyles.caption().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _reason,
                    maxLines: 3,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l10n.blockReasonHint,
                      hintStyle: AppTextStyles.bodyMedium().copyWith(
                        color: context.colors.textMuted,
                        fontSize: 15,
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
                        borderSide: BorderSide(
                          color: context.colors.brand,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? l10n.reasonRequiredDetailed
                        : null,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.unblockInfo,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: context.colors.text,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.currentReason case final previousReason?) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.previousBlockReason,
                      style: AppTextStyles.caption().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(previousReason, style: AppTextStyles.bodyMedium()),
                  ],
                ],
                if (_errorMessage case final msg?) ...[
                  const SizedBox(height: AppSpacing.lg),
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
                ],
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
                      child: blocking
                          ? AppDangerButton(
                              label: l10n.block,
                              icon: Icons.block_outlined,
                              isLoading: _submitting,
                              onPressed: _submitting ? null : _doBlock,
                            )
                          : AppPrimaryButton(
                              label: l10n.unblock,
                              icon: Icons.lock_open_outlined,
                              isLoading: _submitting,
                              onPressed: _submitting ? null : _doUnblock,
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
