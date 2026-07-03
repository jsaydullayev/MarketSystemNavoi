// lib/features/users/screens/users_screen.dart
//
// Staff list screen, mapped to demo `id="page-staff-list"`:
// - 3-stat summary card (JAMI / SMENADA / BUGUN TUSHUM)
// - Filter chips (Hammasi / Smena ochiq / Smena yopiq / Admin / Seller)
// - Staff row cards via [UserCard]
// - Brand-orange extended FAB to open [AddUserSheet]

import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/users_service.dart';
import '../widgets/add_user_sheet.dart';
import '../widgets/user_card.dart';
import '../widgets/user_info_sheet.dart';

/// Quick-filter taxonomy mirroring the demo's filter chips.
enum _UsersFilter { all, shiftOpen, shiftClosed, admin, seller }

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  // Today's combined sales revenue across all staff — sourced from the
  // /Reports/staff-performance?period=today endpoint, summed across rows.
  // Null while loading; falls back to 0 on error so the UI shows "0 UZS"
  // rather than "—" once we've finished trying.
  double? _todayRevenue;
  bool _isLoading = false;
  String? _error;
  final _searchCtrl = TextEditingController();
  _UsersFilter _filter = _UsersFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilters(List<dynamic> users) {
    final q = _searchCtrl.text.toLowerCase().trim();
    return users.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      // "Shift open/closed" reflects the real shift state, not the account
      // active flag — Admin/Owner control it from the user detail sheet.
      final onShift = u['isShiftActive'] ?? false;
      switch (_filter) {
        case _UsersFilter.shiftOpen:
          if (!onShift) return false;
          break;
        case _UsersFilter.shiftClosed:
          if (onShift) return false;
          break;
        case _UsersFilter.admin:
          if (role != 'admin') return false;
          break;
        case _UsersFilter.seller:
          if (role != 'seller') return false;
          break;
        case _UsersFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      return (u['fullName'] ?? '').toString().toLowerCase().contains(q) ||
          (u['username'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Fire users + today's staff-performance in parallel — the page is
      // pretty empty until both resolve, but a slow performance call should
      // not block the user list from rendering, so we tolerate either
      // future failing independently below.
      final usersFuture = UsersService(authProvider: auth).getAllUsers();
      final perfFuture = ReportService(authProvider: auth)
          .getStaffPerformance(period: 'today')
          .then(
            (perf) => perf.staff.fold<double>(0, (sum, s) => sum + s.revenue),
          )
          // Endpoint is AdminOrOwner-gated; for Sellers (and on network errors)
          // we'd rather show 0 UZS than block the whole page.
          .catchError((_) => 0.0);

      final users = await usersFuture;
      final revenue = await perfFuture;
      if (!mounted) return;
      setState(() {
        _users = users;
        _todayRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final l10n = AppLocalizations.of(context)!;
        _error = '${l10n.error}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(dynamic user) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final svc = UsersService(authProvider: auth);
      final isActive = user['isActive'] ?? false;
      if (isActive) {
        await svc.deactivateUser(user['id']);
      } else {
        await svc.activateUser(user['id']);
      }
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? l10n.deactivated : l10n.activated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (user['id'] == auth.user?['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotDeleteSelf),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(l10n.deleteUser, style: AppTextStyles.titleMedium()),
        content: Text(
          l10n.deleteUserConfirm(user['fullName'] ?? user['userName'] ?? ''),
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.no,
              style: AppTextStyles.labelLarge().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              l10n.yesDelete,
              style: AppTextStyles.labelLarge().copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await UsersService(authProvider: auth).deleteUser(user['id']);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deleteSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // RBAC: foydalanuvchi boshqarish ruxsati (users.manage) bo'lmasa, qo'shish
    // FAB va kartadagi bloklash/o'chirish tugmalari ko'rsatilmaydi.
    final canManage = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).can(Permissions.usersManage);

    return NetworkWrapper(
      onRetry: _loadUsers,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(title: l10n.users, onRefresh: _loadUsers),
        body: _buildBody(l10n, canManage),
        floatingActionButton: !canManage
            ? null
            : FloatingActionButton.extended(
                onPressed: () => AddUserSheet.show(context),
                backgroundColor: context.colors.brand,
                foregroundColor: context.colors.onBrand,
                icon: const Icon(Icons.person_add_rounded),
                label: Text(
                  l10n.newUser,
                  style: AppTextStyles.labelLarge().copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool canManage) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error case final err?) {
      return _ErrorView(message: err, onRetry: _loadUsers);
    }

    final filtered = _applyFilters(_users);

    // Search / summary / filter chips render once; only the user cards are
    // built lazily via ListView.builder.
    final leading = <Widget>[
      _SearchBar(controller: _searchCtrl),
      const SizedBox(height: AppSpacing.lg),
      _StaffSummary(users: _users, todayRevenue: _todayRevenue),
      const SizedBox(height: AppSpacing.lg),
      _FilterChips(
        active: _filter,
        onChanged: (f) => setState(() => _filter = f),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
    final bodyCount = filtered.isEmpty ? 1 : filtered.length;

    return RefreshIndicator(
      onRefresh: _loadUsers,
      // Centered + max-width container so the layout adapts cleanly to any
      // device width — phone (full width), tablet, and web (800px cap).
      // Previously the list spanned the entire window on desktop, which
      // made each card stretch to ~1400px and broke the card-density feel
      // designed for mobile.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              96,
            ),
            itemCount: leading.length + bodyCount,
            itemBuilder: (context, index) {
              if (index < leading.length) return leading[index];
              if (filtered.isEmpty) {
                return _EmptyView(
                  isSearching:
                      _searchCtrl.text.isNotEmpty ||
                      _filter != _UsersFilter.all,
                );
              }
              final u = filtered[index - leading.length];
              return UserCard(
                key: ValueKey('user_${u['id']}'),
                user: u,
                canManage: canManage,
                onTap: () =>
                    UserInfoSheet.show(context, user: u, onChanged: _loadUsers),
                onToggleStatus: () => _toggleStatus(u),
                onDelete: () => _deleteUser(u),
              );
            },
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
        hintText: l10n.searchUser,
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

/// 3-stat summary card matching the demo's `.prod-summary` block:
/// "Jami" (total users) / "Smenada" (active users) / "Bugun tushum"
/// (today's combined sales from /Reports/staff-performance, summed across
/// staff). All three labels are localised — they previously hardcoded
/// uppercase Uzbek which leaked into the Russian UI.
class _StaffSummary extends StatelessWidget {
  const _StaffSummary({required this.users, this.todayRevenue});
  final List<dynamic> users;

  /// Today's combined revenue across all staff (sum of `StaffRow.revenue`).
  /// Null while the parent's load future is still in flight — we render "…"
  /// in that case so it visually differs from a clean "0 UZS" zero state.
  final double? todayRevenue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = users.length;
    final onShift = users
        .where((u) => (u['isShiftActive'] ?? false) == true)
        .length;

    // Compact a big number (450 000 → 450K, 12.4M → 12.4M) for the stat
    // tile so it stays on one line even on narrow screens.
    String revenueLabel;
    // Snapshot the parameter into a non-nullable local so the formatter
    // doesn't need `!` on every arithmetic call.
    final revenue = todayRevenue;
    if (revenue == null) {
      revenueLabel = '…';
    } else {
      final v = revenue.abs();
      if (v >= 1000000) {
        final m = revenue / 1000000;
        revenueLabel = '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
      } else if (v >= 1000) {
        final k = revenue / 1000;
        revenueLabel = '${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
      } else {
        revenueLabel = NumberFormatter.format(revenue);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              value: '$total',
              label: l10n.totalShort,
              valueColor: context.colors.text,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryStat(
              value: '$onShift',
              label: l10n.usersOnShiftShort,
              valueColor: AppColors.success,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryStat(
              value: revenueLabel,
              label: l10n.usersTodayRevenueShort,
              valueColor: context.colors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: context.colors.borderSoft);
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge().copyWith(
            color: valueColor,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});
  final _UsersFilter active;
  final ValueChanged<_UsersFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: l10n.all,
            isActive: active == _UsersFilter.all,
            onTap: () => onChanged(_UsersFilter.all),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.shiftOpenLabel,
            leadingDot: AppColors.success,
            isActive: active == _UsersFilter.shiftOpen,
            onTap: () => onChanged(_UsersFilter.shiftOpen),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.shiftClosedLabel,
            isActive: active == _UsersFilter.shiftClosed,
            onTap: () => onChanged(_UsersFilter.shiftClosed),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.admin,
            leadingIcon: Icons.admin_panel_settings_rounded,
            isActive: active == _UsersFilter.admin,
            onTap: () => onChanged(_UsersFilter.admin),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: l10n.seller,
            leadingIcon: Icons.storefront_rounded,
            isActive: active == _UsersFilter.seller,
            onTap: () => onChanged(_UsersFilter.seller),
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
    this.leadingIcon,
    this.leadingDot,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Color? leadingDot;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingDot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: leadingDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: isActive
                    ? context.colors.onBrand
                    : context.colors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: isActive
                    ? context.colors.onBrand
                    : context.colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
            isSearching ? l10n.userNotFound : l10n.noUsersFound,
            style: AppTextStyles.titleMedium().copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
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
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                l10n.retry,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
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
