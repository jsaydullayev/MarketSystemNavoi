// lib/features/customers/presentation/screens/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/customers/presentation/widgets/add_customer_sheet.dart';
import 'package:market_system_client/features/customers/presentation/widgets/customers_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/events/customers_event.dart';
import '../bloc/states/customers_state.dart';

/// Quick-filter taxonomy mirroring the demo's filter chips.
enum _CustomerFilter { all, debtors, clean }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  _CustomerFilter _filter = _CustomerFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(const GetCustomersEvent());
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        context.read<CustomersBloc>().add(const GetCustomersEvent());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> customers,
  ) {
    final query = _searchController.text.toLowerCase().trim();
    return customers.where((c) {
      final debt = (c['totalDebt'] as num?)?.toDouble() ?? 0.0;
      switch (_filter) {
        case _CustomerFilter.debtors:
          if (debt <= 0) return false;
          break;
        case _CustomerFilter.clean:
          if (debt > 0) return false;
          break;
        case _CustomerFilter.all:
          break;
      }
      if (query.isEmpty) return true;
      return (c['fullName'] ?? '').toString().toLowerCase().contains(query) ||
          (c['phone'] ?? '').toString().toLowerCase().contains(query);
    }).toList();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomersBloc>(),
        child: const AddCustomerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<CustomersBloc, CustomersState>(
      listener: (context, state) {
        if (state is CustomerDeleted || state is CustomerCreated) {
          final msg = state is CustomerDeleted
              ? l10n.customerDeleted
              : l10n.customerAdded;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.success),
          );
          context.read<CustomersBloc>().add(const GetCustomersEvent());
        } else if (state is CustomersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: NetworkWrapper(
        onRetry: () =>
            context.read<CustomersBloc>().add(const GetCustomersEvent()),
        child: Scaffold(
          backgroundColor: context.colors.bg,
          appBar: CommonAppBar(
            title: l10n.customers,
            onRefresh: () =>
                context.read<CustomersBloc>().add(const GetCustomersEvent()),
          ),
          body: BlocBuilder<CustomersBloc, CustomersState>(
            builder: (context, state) {
              if (state is CustomersLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CustomersError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => context.read<CustomersBloc>().add(
                    const GetCustomersEvent(),
                  ),
                );
              }
              if (state is CustomersLoaded) {
                final all = state.customers.map((e) => e.toJson()).toList();
                final filtered = _applyFilters(all);
                // AUDIT-2 — compute hero aggregates ONCE here instead of
                // re-folding the full list inside `_CustomersHero.build`
                // on every parent rebuild (search keystroke, filter chip
                // tap, RefreshIndicator pull). With 200+ customers the
                // old fold + where ran ~400 iterations per keystroke.
                var totalDebt = 0.0;
                var debtors = 0;
                for (final c in all) {
                  final v = (c['totalDebt'] as num?)?.toDouble() ?? 0.0;
                  totalDebt += v;
                  if (v > 0) debtors++;
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<CustomersBloc>().add(
                    const GetCustomersEvent(),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      96,
                    ),
                    children: [
                      _SearchBar(controller: _searchController),
                      const SizedBox(height: AppSpacing.lg),
                      _CustomersHero(
                        customerCount: all.length,
                        totalDebt: totalDebt,
                        debtors: debtors,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FilterChips(
                        active: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (filtered.isEmpty)
                        _EmptyView(
                          isSearching:
                              _searchController.text.isNotEmpty ||
                              _filter != _CustomerFilter.all,
                        )
                      else
                        ...filtered.map((c) => CustomersCard(customer: c)),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddSheet,
            backgroundColor: context.colors.brand,
            foregroundColor: context.colors.onBrand,
            elevation: 4,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: l10n.searchCustomer,
        hintStyle: AppTextStyles.bodyMedium().copyWith(
          color: context.colors.textMuted,
          fontSize: 15,
        ),
        prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: context.colors.textMuted),
                onPressed: controller.clear,
              )
            : null,
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
          borderSide: BorderSide(color: context.colors.brand, width: 1.5),
        ),
      ),
    );
  }
}

/// Amber hero card with the JAMI QARZ total + three mini stats below
/// (debtors / clean balance / count). Demo uses #B45309 → #F59E0B.
///
/// AUDIT-2 — aggregates are pre-computed by the parent and passed in as
/// primitives, so this widget can stay `const`-friendly and never has to
/// walk the customer list itself. Old API took the whole list and folded
/// it on every rebuild, which was the dominant cost during search/filter
/// interaction on 200+ row tenants.
class _CustomersHero extends StatelessWidget {
  const _CustomersHero({
    required this.customerCount,
    required this.totalDebt,
    required this.debtors,
  });
  final int customerCount;
  final double totalDebt;
  final int debtors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clean = customerCount - debtors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        // Amber "JAMI QARZ" gradient identical to the demo's `.debt-hero`
        // — sourced from the warning token family so the gradient stays
        // in step with the rest of the palette.
        gradient: const LinearGradient(
          colors: [AppColors.warningDark, AppColors.warning],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.25),
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
                l10n.totalDebt.toUpperCase(),
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$customerCount ${l10n.customer.toLowerCase()}',
                style: AppTextStyles.bodySmall().copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            child: Text(
              '${NumberFormatter.format(totalDebt)} ${l10n.currencySom}',
              style: AppTextStyles.displayLarge().copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _HeroStat(value: '$debtors', label: l10n.debtor.toLowerCase()),
              const SizedBox(width: AppSpacing.xl),
              _HeroStat(value: '$clean', label: l10n.noDebt.toLowerCase()),
              const SizedBox(width: AppSpacing.xl),
              _HeroStat(
                value: '$customerCount',
                label: l10n.total.toLowerCase(),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium().copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});
  final _CustomerFilter active;
  final ValueChanged<_CustomerFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: l10n.all,
            isActive: active == _CustomerFilter.all,
            onTap: () => onChanged(_CustomerFilter.all),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.debtors,
            isActive: active == _CustomerFilter.debtors,
            onTap: () => onChanged(_CustomerFilter.debtors),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.noDebt,
            isActive: active == _CustomerFilter.clean,
            onTap: () => onChanged(_CustomerFilter.clean),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? context.colors.brand : context.colors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? context.colors.brand : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: isActive
                ? context.colors.onBrand
                : context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: context.colors.onBrand),
              label: Text(
                l10n.retry,
                style: TextStyle(color: context.colors.onBrand),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
                foregroundColor: context.colors.onBrand,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl3,
                  vertical: AppSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isSearching});
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 56,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isSearching ? l10n.customerNotFound : l10n.noCustomers,
            style: AppTextStyles.titleMedium().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
