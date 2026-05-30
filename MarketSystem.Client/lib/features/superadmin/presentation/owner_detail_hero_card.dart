// Owner-detail hero card: avatar + identity + market meta + the
// Tahrirlash / Bloklash / O'chirish action buttons. Extracted verbatim
// from owner_detail_screen.dart (pure code-move, behavior unchanged).

import 'package:flutter/material.dart';

import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models/owner_detail.dart';
import 'owner_detail_format.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
    required this.onBlock,
  });
  final OwnerDetail detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final market = detail.market;
    final blocked = market?.isBlocked ?? false;
    final initial = detail.fullName.isNotEmpty
        ? detail.fullName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final narrow = constraints.maxWidth < 540;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.colors.brand,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.titleLarge().copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            detail.fullName,
                            style: AppTextStyles.titleLarge(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _StatusChip(
                          label: blocked
                              ? l10n.statusBlocked
                              : (detail.isActive
                                    ? l10n.statusActive
                                    : l10n.statusInactive),
                          color: blocked
                              ? AppColors.danger
                              : (detail.isActive
                                    ? AppColors.success
                                    : context.colors.textMuted),
                          background: blocked
                              ? AppColors.dangerLight
                              : (detail.isActive
                                    ? AppColors.successLight
                                    : context.colors.inputFill),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@${detail.username} · Owner · ${l10n.registeredSince(formatOwnerDetailDate(detail.createdAt, withTime: false))}',
                      style: AppTextStyles.bodySmall(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.md,
                      children: [
                        // Dart-3 non-null patterns let us bind the nullable
                        // field to a local in one line, no `!` needed.
                        if (detail.phone case final phone?)
                          _MetaItem(icon: Icons.phone_outlined, text: phone),
                        if (market != null)
                          _MetaItem(
                            icon: Icons.storefront_outlined,
                            text: market.name,
                          ),
                        if (market?.subdomain case final subdomain?)
                          _MetaItem(
                            icon: Icons.language_outlined,
                            text: '$subdomain.strotech.uz',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = _ActionButtons(
            blocked: blocked,
            onEdit: onEdit,
            onBlock: onBlock,
            onDelete: onDelete,
            narrow: narrow,
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.xl),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(width: 220, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.blocked,
    required this.onEdit,
    required this.onBlock,
    required this.onDelete,
    required this.narrow,
  });
  final bool blocked;
  final VoidCallback onEdit;
  final VoidCallback onBlock;
  final VoidCallback onDelete;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPrimaryButton(
          label: l10n.edit,
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSecondaryButton(
          label: blocked ? l10n.unblock : l10n.block,
          icon: blocked ? Icons.lock_open_outlined : Icons.block_outlined,
          onPressed: onBlock,
        ),
        const SizedBox(height: AppSpacing.md),
        AppDangerButton(
          label: l10n.delete,
          icon: Icons.delete_outline,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.bodySmall()),
      ],
    );
  }
}
