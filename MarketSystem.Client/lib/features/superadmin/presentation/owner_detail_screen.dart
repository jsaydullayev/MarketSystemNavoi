// Owner profile — migrated to the new design system. Hero card
// (avatar + identity + market + Tahrirlash / Bloklash / O'chirish), stat
// tiles (Mahsulotlar / Sotuvlar / Mijozlar / Qarz), Owner info, Market info,
// and Block/Unblock control. Business logic (SuperAdminService) untouched.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/superadmin_service.dart';
import '../domain/models/owner_detail.dart';
import 'widgets/block_market_dialog.dart';
import 'widgets/delete_owner_dialog.dart';
import 'widgets/edit_owner_dialog.dart';

class OwnerDetailScreen extends StatefulWidget {
  const OwnerDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  late final SuperAdminService _service;
  OwnerDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = SuperAdminService(context.read<AuthProvider>().httpService);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getOwnerDetail(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.status == SuperAdminOpStatus.success) {
        _detail = res.data;
      } else {
        _error = res.message ?? 'failure';
      }
    });
  }

  Future<void> _onEdit() async {
    if (_detail == null) return;
    final updated = await showDialog<OwnerDetail>(
      context: context,
      builder: (_) => EditOwnerDialog(detail: _detail!),
    );
    if (updated != null && mounted) {
      setState(() => _detail = updated);
      final l10n = AppLocalizations.of(context)!;
      _snack(l10n.infoUpdated, isError: false);
    }
  }

  Future<void> _onDelete() async {
    if (_detail?.market == null) return;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteOwnerDialog(
        ownerName: _detail!.fullName,
        marketName: _detail!.market!.name,
        userId: _detail!.userId,
        stats: _detail!.stats,
      ),
    );
    if (deleted == true && mounted) {
      Navigator.of(context).pop(true); // signal list to refresh
    }
  }

  Future<void> _onBlock() async {
    if (_detail?.market == null) return;
    final blocked = await showDialog<bool>(
      context: context,
      builder: (_) => BlockMarketDialog(
        marketId: _detail!.market!.id,
        marketName: _detail!.market!.name,
        currentlyBlocked: _detail!.market!.isBlocked,
        currentReason: _detail!.market!.blockedReason,
      ),
    );
    if (blocked == true && mounted) {
      await _load(); // pull fresh block state
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.colors.border, width: 1),
        ),
        title: Text(
          l10n.ownerInfoTitle,
          style: AppTextStyles.titleMedium(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.brand))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : _detail == null
                  ? Center(
                      child: Text(
                        l10n.ownerNotFound,
                        style: AppTextStyles.bodyMedium(),
                      ),
                    )
                  : RefreshIndicator(
                      color: context.colors.brand,
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroCard(
                              detail: _detail!,
                              onEdit: _onEdit,
                              onDelete: _onDelete,
                              onBlock: _onBlock,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _StatsGrid(stats: _detail!.stats),
                            const SizedBox(height: AppSpacing.lg),
                            _OwnerInfoCard(detail: _detail!),
                            const SizedBox(height: AppSpacing.lg),
                            if (_detail!.market != null)
                              _MarketInfoCard(market: _detail!.market!),
                            const SizedBox(height: AppSpacing.xl3),
                          ],
                        ),
                      ),
                    ),
    );
  }

  void _snack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
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
    final initial =
        detail.fullName.isNotEmpty ? detail.fullName[0].toUpperCase() : '?';

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
                              : (detail.isActive ? l10n.statusActive : l10n.statusInactive),
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
                      '@${detail.username} · Owner · ${l10n.registeredSince(_formatDate(detail.createdAt, withTime: false))}',
                      style: AppTextStyles.bodySmall(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.md,
                      children: [
                        if (detail.phone != null)
                          _MetaItem(
                            icon: Icons.phone_outlined,
                            text: detail.phone!,
                          ),
                        if (market != null)
                          _MetaItem(
                            icon: Icons.storefront_outlined,
                            text: market.name,
                          ),
                        if (market?.subdomain != null)
                          _MetaItem(
                            icon: Icons.language_outlined,
                            text: '${market!.subdomain}.strotech.uz',
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final OwnerDetailStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cross = c.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: cross == 2 ? 1.7 : 1.35,
          children: [
            _StatTile(
              label: 'MAHSULOTLAR',
              value: _fmtNum(stats.productsCount),
              subtitle: 'Faol turlari',
              color: context.colors.text,
              icon: Icons.inventory_2_outlined,
            ),
            _StatTile(
              label: 'SOTUVLAR',
              value: _fmtNum(stats.salesCount),
              subtitle: 'Jami chek',
              color: AppColors.success,
              icon: Icons.point_of_sale_outlined,
            ),
            _StatTile(
              label: 'MIJOZLAR',
              value: _fmtNum(stats.customersCount),
              subtitle: 'Faol mijozlar',
              color: context.colors.text,
              icon: Icons.people_outline,
            ),
            _StatTile(
              label: 'QARZ',
              value: _fmtMoney(stats.outstandingDebt),
              subtitle: 'UZS jami',
              color: stats.outstandingDebt > 0
                  ? AppColors.warning
                  : context.colors.text,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        );
      },
    );
  }

  String _fmtNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _fmtMoney(double d) {
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption()
                .copyWith(color: context.colors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Row(
            children: [
              Icon(icon, size: 14, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  const _OwnerInfoCard({required this.detail});
  final OwnerDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.ownerSectionHeader,
      icon: Icons.person_outline,
      children: [
        _InfoRow(label: l10n.fullNameUpper, value: detail.fullName),
        _InfoRow(label: l10n.usernameUpper, value: '@${detail.username}', mono: true),
        _InfoRow(label: l10n.phoneUpper, value: detail.phone ?? '—'),
        _InfoRow(
          label: l10n.languageUpper,
          value: detail.language == 'russian' ? '🇷🇺 Русский' : "🇺🇿 O'zbek",
        ),
        _InfoRow(
          label: l10n.registeredUpper,
          value: _formatDate(detail.createdAt),
        ),
        _InfoRow(
          label: l10n.statusUpper,
          value: detail.isActive ? l10n.statusActive : l10n.statusInactive,
          valueColor:
              detail.isActive ? AppColors.success : context.colors.textMuted,
        ),
      ],
    );
  }
}

class _MarketInfoCard extends StatelessWidget {
  const _MarketInfoCard({required this.market});
  final OwnerDetailMarket market;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              : (market.isActive ? AppColors.success : context.colors.textMuted),
        ),
        if (market.isBlocked && market.blockedReason != null)
          _InfoRow(
            label: l10n.blockReasonUpper,
            value: market.blockedReason!,
            valueColor: AppColors.danger,
          ),
        if (market.isBlocked && market.blockedAt != null)
          _InfoRow(
            label: l10n.blockedAtUpper,
            value: _formatDate(market.blockedAt!),
          ),
        if (market.expiresAt != null)
          _InfoRow(
            label: l10n.subscriptionExpiresUpper,
            value: _formatDate(market.expiresAt!, withTime: false),
          ),
        _InfoRow(label: l10n.createdUpper, value: _formatDate(market.createdAt)),
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
                style: AppTextStyles.caption()
                    .copyWith(color: context.colors.textSecondary),
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
          style: AppTextStyles.caption()
              .copyWith(color: context.colors.textSecondary),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: l10n.retry,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime utc, {bool withTime = true}) {
  final local = utc.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  final date = '${local.year}-${two(local.month)}-${two(local.day)}';
  if (!withTime) return date;
  return '$date ${two(local.hour)}:${two(local.minute)}';
}
