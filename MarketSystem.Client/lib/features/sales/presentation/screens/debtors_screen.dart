// Qarzdorlar (Debtors) screen — mirrors the "8.1 Mijozlar ro'yxati" pattern
// from the HTML demo for the sales feature. Shows:
//   * Amber gradient "JAMI QARZ" hero with sub-stats (qarzdor / sotuv soni /
//     bugun yangilandi).
//   * Search box (ism yoki telefon).
//   * Filter chips: Hammasi / Qarzdorlar / Eski qarz / Yangi.
//   * Customer rows with palette avatar, name + phone, debt amount badge.
//
// All business logic from the legacy version is preserved: SalesService
// fetches /sales/debtors, the screen reloads on focus, and tapping a row
// still navigates into DebtorDetailScreen with the full debtor payload.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/data/services/sales_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/widgets/avatar_palette.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

import 'debtor_detail_screen.dart';

enum _DebtorFilter { all, debtors, old, recent }

class DebtorsScreen extends StatefulWidget {
  const DebtorsScreen({super.key});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  List<dynamic> _debtors = [];
  bool _isLoading = true;
  String _query = '';
  _DebtorFilter _filter = _DebtorFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDebtors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The legacy screen refreshed on every dependency change so debtors come
    // back fresh after a payment is posted from anywhere else in the app —
    // keep that behaviour.
    if (mounted) {
      Future.delayed(Duration.zero, _loadDebtors);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDebtors() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salesService = SalesService(authProvider: authProvider);
      final debtors = await salesService.getDebtors();
      if (!mounted) return;
      setState(() {
        _debtors = debtors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<dynamic> get _filtered {
    final q = _query.trim().toLowerCase();
    return _debtors.where((d) {
      final name = (d['customerName'] as String?)?.toLowerCase() ?? '';
      final phone = (d['customerPhone'] as String?) ?? '';
      if (q.isNotEmpty &&
          !name.contains(q) &&
          !phone.replaceAll(' ', '').contains(q.replaceAll(' ', ''))) {
        return false;
      }
      switch (_filter) {
        case _DebtorFilter.all:
          return true;
        case _DebtorFilter.debtors:
          final r = (d['remainingDebt'] as num?)?.toDouble() ?? 0;
          return r > 0;
        case _DebtorFilter.old:
          return _ageInDays(d) > 30;
        case _DebtorFilter.recent:
          return _ageInDays(d) <= 7;
      }
    }).toList();
  }

  int _ageInDays(dynamic d) {
    final raw = d['oldestDebtDate'];
    if (raw == null) return 0;
    try {
      final date = DateTime.parse(raw.toString())
          .toUtc()
          .add(const Duration(hours: 5));
      final now = DateTime.now().toUtc().add(const Duration(hours: 5));
      return now.difference(date).inDays;
    } catch (_) {
      return 0;
    }
  }

  double get _grandTotal {
    var sum = 0.0;
    for (final d in _debtors) {
      sum += (d['remainingDebt'] as num?)?.toDouble() ?? 0;
    }
    return sum;
  }

  int get _activeDebtorCount {
    var n = 0;
    for (final d in _debtors) {
      if (((d['remainingDebt'] as num?)?.toDouble() ?? 0) > 0) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadDebtors,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(title: l10n.debtors, onRefresh: _loadDebtors),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDebtors,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.xl, AppSpacing.xl, AppSpacing.xl3),
                  children: [
                    _SearchBox(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DebtHero(
                      total: _grandTotal,
                      debtorCount: _activeDebtorCount,
                      totalRecords: _debtors.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FilterBar(
                      selected: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_filtered.isEmpty)
                      _EmptyState(hasFilter: _query.isNotEmpty ||
                          _filter != _DebtorFilter.all)
                    else
                      ..._filtered.map((d) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.md + 2),
                            child: _DebtorRow(
                              debtor: d,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DebtorDetailScreen(
                                    customerId: d['customerId'],
                                    customerName: d['customerName'] ??
                                        l10n.noCustomer,
                                    debtorData: d,
                                  ),
                                ),
                              ),
                            ),
                          )),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Ism yoki telefon…',
          hintStyle: AppTextStyles.bodyMedium()
              .copyWith(color: context.colors.textMuted),
          icon: Icon(Icons.search_rounded,
              color: context.colors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

class _DebtHero extends StatelessWidget {
  const _DebtHero({
    required this.total,
    required this.debtorCount,
    required this.totalRecords,
  });
  final double total;
  final int debtorCount;
  final int totalRecords;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'JAMI QARZ',
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$totalRecords ${l10n.debtors.toLowerCase()}',
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${NumberFormatter.format(total)} ${l10n.currencySom.toUpperCase()}',
            style: AppTextStyles.displayMedium().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _HeroStat(value: '$debtorCount', label: 'qarzdor'),
              const SizedBox(width: AppSpacing.xl3),
              _HeroStat(
                value: NumberFormatter.formatDecimal(total),
                label: l10n.totalDebt.toLowerCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium().copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final _DebtorFilter selected;
  final ValueChanged<_DebtorFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <_FilterChipData>[
      _FilterChipData(_DebtorFilter.all, l10n.all, null),
      _FilterChipData(_DebtorFilter.debtors, l10n.debtors, '📋'),
      _FilterChipData(_DebtorFilter.old, l10n.filterOldDebt, '⏳'),
      _FilterChipData(_DebtorFilter.recent, l10n.filterRecent, '⭐'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) ...[
            _Chip(
              data: c,
              isActive: selected == c.value,
              onTap: () => onChanged(c.value),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _FilterChipData {
  final _DebtorFilter value;
  final String label;
  final String? emoji;
  const _FilterChipData(this.value, this.label, this.emoji);
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.data, required this.isActive, required this.onTap});
  final _FilterChipData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg + 2, vertical: AppSpacing.md - 1),
        decoration: BoxDecoration(
          color: isActive ? context.colors.brand : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? context.colors.brand : context.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.emoji != null) ...[
              Text(data.emoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Text(
              data.label,
              style: AppTextStyles.bodyMedium().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? context.colors.onBrand
                    : context.colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtorRow extends StatelessWidget {
  const _DebtorRow({required this.debtor, required this.onTap});
  final dynamic debtor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (debtor['customerName'] as String?) ?? l10n.noCustomer;
    final phone = debtor['customerPhone'] as String?;
    final remaining = (debtor['remainingDebt'] as num?)?.toDouble() ?? 0;
    final color = CustomerAvatarPalette.pick(name);
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final lastActivity = _formatLastActivity(debtor['oldestDebtDate'], l10n);

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge().copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelLarge(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: context.colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormatter.formatDecimal(remaining),
                    style: AppTextStyles.titleMedium().copyWith(
                      color: remaining > 0
                          ? AppColors.danger
                          : AppColors.success,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (lastActivity != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      lastActivity,
                      style: AppTextStyles.caption().copyWith(
                        color: context.colors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatLastActivity(dynamic raw, AppLocalizations l10n) {
    if (raw == null) return null;
    try {
      final date = DateTime.parse(raw.toString())
          .toUtc()
          .add(const Duration(hours: 5));
      final now = DateTime.now().toUtc().add(const Duration(hours: 5));
      final diff = now.difference(date);
      if (diff.inDays == 0) return l10n.today;
      if (diff.inDays == 1) return l10n.yesterday;
      if (diff.inDays < 30) return l10n.daysAgo(diff.inDays);
      if (diff.inDays < 365) {
        return l10n.monthsAgo((diff.inDays / 30).floor());
      }
      return l10n.yearsAgo((diff.inDays / 365).floor());
    } catch (_) {
      return null;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: context.colors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            hasFilter ? 'Hech narsa topilmadi' : l10n.noDebtors,
            style: AppTextStyles.titleMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.debtorsWillBeShownHere,
            style: AppTextStyles.bodySmall()
                .copyWith(color: context.colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
