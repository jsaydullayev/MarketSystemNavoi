// Owner-detail info cards: Owner info + Market info section cards, plus the
// shared _SectionCard / _InfoRow building blocks. Extracted verbatim from
// owner_detail_screen.dart (pure code-move, behavior unchanged).

import 'package:flutter/material.dart';

import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models/owner_detail.dart';
import 'owner_detail_format.dart';

class OwnerInfoCard extends StatelessWidget {
  const OwnerInfoCard({super.key, required this.detail});
  final OwnerDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.ownerSectionHeader,
      icon: Icons.person_outline,
      children: [
        _InfoRow(label: l10n.fullNameUpper, value: detail.fullName),
        _InfoRow(
          label: l10n.usernameUpper,
          value: '@${detail.username}',
          mono: true,
        ),
        _InfoRow(label: l10n.phoneUpper, value: detail.phone ?? '—'),
        _InfoRow(
          label: l10n.languageUpper,
          value: detail.language == 'russian' ? '🇷🇺 Русский' : "🇺🇿 O'zbek",
        ),
        _InfoRow(
          label: l10n.registeredUpper,
          value: formatOwnerDetailDate(detail.createdAt),
        ),
        _InfoRow(
          label: l10n.statusUpper,
          value: detail.isActive ? l10n.statusActive : l10n.statusInactive,
          valueColor: detail.isActive
              ? AppColors.success
              : context.colors.textMuted,
        ),
      ],
    );
  }
}

class MarketInfoCard extends StatelessWidget {
  const MarketInfoCard({super.key, required this.market});
  final OwnerDetailMarket market;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pull the nullable fields into locals — `market.X` (field access via a
    // widget property) doesn't promote across an `if (... != null)`, but a
    // local does. The locals also let the conditional InfoRows use the
    // smart-cast value directly instead of paying `!` round-trips.
    final blockedReason = market.blockedReason;
    final blockedAt = market.blockedAt;
    final expiresAt = market.expiresAt;
    return _SectionCard(
      title: l10n.shopSectionHeader,
      icon: Icons.storefront_outlined,
      children: [
        _InfoRow(label: l10n.nameUpper, value: market.name),
        _InfoRow(
          label: l10n.subdomainUpper,
          value: market.subdomain != null
              ? '${market.subdomain}.strotech.uz'
              : '—',
          mono: true,
        ),
        _InfoRow(label: l10n.marketIdUpper, value: '#${market.id}', mono: true),
        _InfoRow(
          label: l10n.statusUpper,
          value: market.isBlocked
              ? l10n.statusBlocked
              : (market.isActive ? l10n.statusActive : l10n.statusInactive),
          valueColor: market.isBlocked
              ? AppColors.danger
              : (market.isActive
                    ? AppColors.success
                    : context.colors.textMuted),
        ),
        if (market.isBlocked && blockedReason != null)
          _InfoRow(
            label: l10n.blockReasonUpper,
            value: blockedReason,
            valueColor: AppColors.danger,
          ),
        if (market.isBlocked && blockedAt != null)
          _InfoRow(label: l10n.blockedAtUpper, value: formatOwnerDetailDate(blockedAt)),
        if (expiresAt != null)
          _InfoRow(
            label: l10n.subscriptionExpiresUpper,
            value: formatOwnerDetailDate(expiresAt, withTime: false),
          ),
        _InfoRow(
          label: l10n.createdUpper,
          value: formatOwnerDetailDate(market.createdAt),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.caption().copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (ctx, c) {
              final cross = c.maxWidth < 480 ? 1 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cross,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.xl,
                childAspectRatio: cross == 1 ? 6 : 4,
                children: children,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.colors.text,
            fontFamily: mono ? 'monospace' : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
