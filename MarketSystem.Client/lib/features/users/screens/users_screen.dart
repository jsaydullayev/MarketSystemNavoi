import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../data/services/users_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_info_sheet.dart';
import '../widgets/add_user_sheet.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _isLoading = false;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) {
              return (u['fullName'] ?? '').toLowerCase().contains(q) ||
                  (u['username'] ?? '').toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _loadUsers() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final users = await UsersService(authProvider: auth).getAllUsers();
      setState(() {
        _users = users;
        _filtered = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.error}: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (user['id'] == auth.user?['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.cannotDeleteSelf),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteUser),
        content:
            Text(l10n.deleteUserConfirm(user['fullName'] ?? user['userName'])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.no)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.yesDelete)),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await UsersService(authProvider: auth).deleteUser(user['id']);
        await _loadUsers();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.deleteSuccess),
            backgroundColor: Colors.green,
          ));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${l10n.error}: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(title: l10n.users, onRefresh: _loadUsers),
      body: Column(children: [
        _SearchBar(controller: _searchCtrl, isDark: isDark),
        Expanded(child: _buildBody(isDark)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddUserSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label:
            Text(l10n.newUser, style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return _ErrorView(message: _error!, onRetry: _loadUsers);
    if (_filtered.isEmpty)
      return _EmptyView(isSearching: _searchCtrl.text.isNotEmpty);

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => UserCard(
          user: _filtered[i],
          onTap: () => UserInfoSheet.show(context, user: _filtered[i]),
          onToggleStatus: () => _toggleStatus(_filtered[i]),
          onDelete: () => _deleteUser(_filtered[i]),
        ),
      ),
    );
  }
}

// Search bar
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.searchUser,
          hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.grey.shade400),
                  onPressed: controller.clear)
              : null,
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// Empty / Error views
class _EmptyView extends StatelessWidget {
  final bool isSearching;
  const _EmptyView({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle),
            child: Icon(Icons.people_outline_rounded,
                size: 44, color: AppColors.primary)),
        const SizedBox(height: 14),
        Text(isSearching ? l10n.userNotFound : l10n.noUsersFound,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade500)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text(l10n.retry)),
        ]),
      ),
    );
  }
}
