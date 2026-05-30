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
import 'owner_detail_hero_card.dart';
import 'owner_detail_info_cards.dart';
import 'owner_detail_stats_grid.dart';
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
    // Snapshot the field into a local so Dart's flow analysis promotes it
    // to non-null after the guard — keeps the rest of the method free of
    // _detail! crash-bombs.
    final detail = _detail;
    if (detail == null) return;
    final updated = await showDialog<OwnerDetail>(
      context: context,
      builder: (_) => EditOwnerDialog(detail: detail),
    );
    if (updated != null && mounted) {
      setState(() => _detail = updated);
      final l10n = AppLocalizations.of(context)!;
      _snack(l10n.infoUpdated, isError: false);
    }
  }

  Future<void> _onDelete() async {
    final detail = _detail;
    final market = detail?.market;
    if (detail == null || market == null) return;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteOwnerDialog(
        ownerName: detail.fullName,
        marketName: market.name,
        userId: detail.userId,
        stats: detail.stats,
      ),
    );
    if (deleted == true && mounted) {
      Navigator.of(context).pop(true); // signal list to refresh
    }
  }

  Future<void> _onBlock() async {
    final detail = _detail;
    final market = detail?.market;
    if (detail == null || market == null) return;
    final blocked = await showDialog<bool>(
      context: context,
      builder: (_) => BlockMarketDialog(
        marketId: market.id,
        marketName: market.name,
        currentlyBlocked: market.isBlocked,
        currentReason: market.blockedReason,
      ),
    );
    if (blocked == true && mounted) {
      await _load(); // pull fresh block state
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Snapshot the state fields once so Dart can flow-promote them inside
    // the nested ternaries below — field accesses aren't promotable on
    // their own, so without locals every later use needs a `!`.
    final detail = _detail;
    final error = _error;
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
        title: Text(l10n.ownerInfoTitle, style: AppTextStyles.titleMedium()),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: context.colors.brand),
            )
          : error != null
          ? _ErrorState(error: error, onRetry: _load)
          : detail == null
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
                    HeroCard(
                      detail: detail,
                      onEdit: _onEdit,
                      onDelete: _onDelete,
                      onBlock: _onBlock,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StatsGrid(stats: detail.stats),
                    const SizedBox(height: AppSpacing.lg),
                    OwnerInfoCard(detail: detail),
                    const SizedBox(height: AppSpacing.lg),
                    // Dart-3 non-null pattern: matches when
                    // detail.market is non-null and binds it.
                    if (detail.market case final market?)
                      MarketInfoCard(market: market),
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
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
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
