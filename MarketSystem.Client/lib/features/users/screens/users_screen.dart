import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/users_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/dashboard_screen.dart';
import 'add_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final fullName = (user['fullName'] ?? '').toLowerCase();
          final username = (user['username'] ?? '').toLowerCase();
          return fullName.contains(query) || username.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usersService = UsersService(authProvider: authProvider);

      final users = await usersService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(dynamic user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usersService = UsersService(authProvider: authProvider);

      final isActive = user['isActive'] ?? false;

      if (isActive) {
        await usersService.deactivateUser(user['id']);
      } else {
        await usersService.activateUser(user['id']);
      }

      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive
                ? 'User deaktivatsiya qilindi'
                : 'User aktivatsiya qilindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    // O'zini o'chira olmaydi
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?['userId'];

    if (user['id'] == currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O\'zingizni o\'chira olmaysiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foydalanuvchini o\'chirish'),
        content: Text(
            '${user['fullName']} (${user['username']}) foydalanuvchisini rostdan ham o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ha'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final usersService = UsersService(authProvider: authProvider);
        await usersService.deleteUser(user['id']);
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foydalanuvchi muvaffaqiyatli o\'chirildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xatolik: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddUserDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddUserScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadUsers();
      }
    });
  }

  void _showUserInfo(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['fullName'] ?? 'Noma\'lum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${user['username'] ?? 'Noma\'lum'}'),
            const SizedBox(height: 8),
            Text('Role: ${user['role'] ?? 'Noma\'lum'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Holati: '),
                Chip(
                  label: Text(
                    (user['isActive'] ?? false) ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: (user['isActive'] ?? false)
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foydalanuvchilar'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yangi user qo\'shgandan so\'ng, unga username va password bering. U o\'sha ma\'lumotlar bilan login qiladi.',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterUsers(),
              decoration: InputDecoration(
                hintText: 'Foydalanuvchi qidirish...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Foydalanuvchi topilmadi'
                                      : 'Foydalanuvchilar yo\'q',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _buildUserCard(user, userRole);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Yangi user'),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, String? currentUserRole) {
    final isActive = user['isActive'] ?? false;
    final role = user['role'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getRoleColor(role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            color: _getRoleColor(role),
          ),
        ),
        title: Text(
          user['fullName'] ?? 'Noma\'lum',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user['username'] ?? 'Noma\'lum'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    role,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getRoleColor(role).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showUserInfo(user),
            ),
            IconButton(
              icon: Icon(isActive ? Icons.block : Icons.check_circle),
              color: isActive ? Colors.orange : Colors.green,
              onPressed: () => _toggleUserStatus(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'seller':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
