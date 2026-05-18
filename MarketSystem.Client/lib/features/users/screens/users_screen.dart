// lib/features/users/screens/users_screen.dart
//
// Staff list screen, mapped to demo `id="page-staff-list"`:
// - 3-stat summary card (JAMI / SMENADA / BUGUN TUSHUM)
// - Filter chips (Hammasi / Smena ochiq / Smena yopiq / Admin / Seller)
// - Staff row cards via [UserCard]
// - Brand-orange extended FAB to open [AddUserSheet]

import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
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
      final isActive = u['isActive'] ?? false;
      switch (_filter) {
        case _UsersFilter.shiftOpen:
          if (!isActive) return false;
          break;
        case _UsersFilter.shiftClosed:
          if (isActive) return false;
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
      final users = await UsersService(authProvider: auth).getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isActive ? l10n.deactivated : l10n.activated),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (user['id'] == auth.user?['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.cannotDeleteSelf),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
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
              style: AppTextStyles.labelLarge()
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              l10n.yesDelete,
              style:
                  AppTextStyles.labelLarge().copyWith(color: AppColors.danger),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.deleteSuccess),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NetworkWrapper(
      onRetry: _loadUsers,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: CommonAppBar(title: l10n.users, onRefresh: _loadUsers),
        body: _buildBody(l10n),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AddUserSheet.show(context),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: Text(
            l10n.newUser,
            style: AppTextStyles.labelLarge().copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadUsers);
    }

    final filtered = _applyFilters(_users);

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          96,
        ),
        children: [
          _SearchBar(controller: _searchCtrl),
          const SizedBox(height: AppSpacing.lg),
          _StaffSummary(users: _users),
          const SizedBox(height: AppSpacing.lg),
          _FilterChips(
            active: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filtered.isEmpty)
            _EmptyView(
              isSearching: _searchCtrl.text.isNotEmpty ||
                  _filter != _UsersFilter.all,
            )
          else
            ...filtered.map((u) => UserCard(
                  user: u,
                  onTap: () => UserInfoSheet.show(context, user: u),
                  onToggleStatus: () => _toggleStatus(u),
                  onDelete: () => _deleteUser(u),
                )),
        ],
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
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textMuted),
                onPressed: controller.clear,
              )
            : null,
        filled: true,
        fillColor: AppColors.inputFill,
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
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
    );
  }
}

/// 3-stat summary card matching the demo's `.prod-summary` block:
/// JAMI (total users) / SMENADA (active users) / BUGUN TUSHUM (placeholder).
class _StaffSummary extends StatelessWidget {
  const _StaffSummary({required this.users});
  final List<dynamic> users;

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final onShift =
        users.where((u) => (u['isActive'] ?? false) == true).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              value: '$total',
              label: 'JAMI',
              valueColor: AppColors.text,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryStat(
              value: '$onShift',
              label: 'SMENADA',
              valueColor: AppColors.success,
            ),
          ),
          const _Divider(),
          const Expanded(
            // TODO(staff-performance): wire to /Reports/staff-performance?period=today.
            // ReportService.getStaffPerformance() returns StaffPerformance with
            // a `staff` list; sum staff.revenue (or filter to today's active
            // sellers) and render via NumberFormatter.format. Skipped here to
            // keep the change focused on the dashboard wiring — needs its own
            // loader, refresh wiring, and l10n key for the label.
            child: _SummaryStat(
              value: '—',
              label: 'BUGUN TUSHUM',
              valueColor: AppColors.text,
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
    return Container(
      width: 1,
      height: 32,
      color: AppColors.borderSoft,
    );
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
            color: AppColors.textMuted,
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
            label: 'Smena ochiq',
            leadingDot: AppColors.success,
            isActive: active == _UsersFilter.shiftOpen,
            onTap: () => onChanged(_UsersFilter.shiftOpen),
          ),
          const SizedBox(width: AppSpacing.md),
          _Chip(
            label: 'Smena yopiq',
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
          color: isActive ? AppColors.brand : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? AppColors.brand : AppColors.border,
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
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
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
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 56,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isSearching ? l10n.userNotFound : l10n.noUsersFound,
            style: AppTextStyles.titleMedium()
                .copyWith(color: AppColors.textSecondary),
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
              style: AppTextStyles.bodyMedium()
                  .copyWith(color: AppColors.danger),
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
                backgroundColor: AppColors.brand,
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
