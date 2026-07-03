import 'package:flutter/material.dart';

import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/owner_summary.dart';

class OwnerCard extends StatelessWidget {
  const OwnerCard({super.key, required this.owner, required this.onTap});

  final OwnerSummary owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = owner.fullName.isNotEmpty
        ? owner.fullName[0].toUpperCase()
        : '?';
    final avatarColor = _avatarColor(context, owner.userId);

    Color statusColor;
    Color statusBg;
    String statusLabel;
    if (owner.isMarketBlocked) {
      statusLabel = l10n.statusBlocked;
      statusColor = AppColors.danger;
      statusBg = AppColors.dangerLight;
    } else if (owner.isActive) {
      statusLabel = l10n.statusActive;
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
    } else {
      statusLabel = l10n.statusInactive;
      statusColor = context.colors.textMuted;
      statusBg = context.colors.inputFill;
    }

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge().copyWith(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.fullName,
                      style: AppTextStyles.labelLarge().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${owner.username}',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.brand,
                        fontSize: 13,
                      ),
                    ),
                    if (owner.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            owner.phone ?? '',
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Flexible so a long market name shares remaining width with the
              // Expanded name column instead of starving it on narrow phones.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (owner.marketName case final marketName?)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 13,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              marketName,
                              style: AppTextStyles.bodySmall().copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.colors.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.chevron_right, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// Deterministic per-owner colour so the same owner always gets the same
  /// avatar tint between sessions.
  Color _avatarColor(BuildContext context, String userId) {
    final palette = [
      context.colors.brand,
      AppColors.success,
      AppColors.accentPurple, // purple
      AppColors.avatarSky, // sky
      AppColors.avatarPink, // pink
      AppColors.warning,
    ];
    final hash = userId.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return palette[hash % palette.length];
  }
}
