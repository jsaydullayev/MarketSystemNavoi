import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/zakup/screens/zakup_screen.dart';
import '../features/admin_products/screens/admin_products_screen.dart';
import '../features/sales/screens/sales_screen.dart';
import '../features/users/screens/users_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market System'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tizimdan chiqish'),
                  content: const Text('Rostdan ham tizimdan chiqmoqchimisiz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Yo\'q'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ha'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['fullName'] ?? 'Foydalanuvchi',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user?['username'] ?? 'user'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              user?['role'] ?? 'Seller',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getRoleColor(user?['role']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Menu items
            const Text(
              'Bo\'limlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Products
            _buildMenuItem(
              context,
              title: 'Mahsulotlar',
              subtitle: 'Mahsulotlarni boshqarish',
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsScreen()),
                );
              },
            ),

            // Sales
            _buildMenuItem(
              context,
              title: 'Sotuvlar',
              subtitle: 'Sotuvlar tarixi',
              icon: Icons.shopping_cart_outlined,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesScreen()),
                );
              },
            ),

            // Customers
            _buildMenuItem(
              context,
              title: 'Mijozlar',
              subtitle: 'Mijozlar ro\'yxati',
              icon: Icons.people_outline,
              color: Colors.blue,
              onTap: () {
                _showComingSoon(context, 'Mijozlar');
              },
            ),

            // Zakup
            _buildMenuItem(
              context,
              title: 'Xaridlar',
              subtitle: 'Maxsulot xaridlari',
              icon: Icons.shopping_bag_outlined,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ZakupScreen()),
                );
              },
            ),

            // Reports
            _buildMenuItem(
              context,
              title: 'Hisobotlar',
              subtitle: 'Tizim hisobotlari',
              icon: Icons.bar_chart_outlined,
              color: Colors.teal,
              onTap: () {
                _showComingSoon(context, 'Hisobotlar');
              },
            ),

            // Debts
            _buildMenuItem(
              context,
              title: 'Qarzdorlik',
              subtitle: 'Mijozlar qarzlari',
              icon: Icons.money_outlined,
              color: Colors.red,
              onTap: () {
                _showComingSoon(context, 'Qarzdorlik');
              },
            ),

            // Users (Admin/Owner only)
            if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
              _buildMenuItem(
                context,
                title: 'Foydalanuvchilar',
                subtitle: 'Foydalanuvchilarni boshqarish',
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsersScreen()),
                  );
                },
              ),

            // Admin Products (Admin/Owner only)
            if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
              _buildMenuItem(
                context,
                title: 'Admin: Mahsulotlar',
                subtitle: 'Mahsulot narxlari va sozlamalari',
                icon: Icons.settings,
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'Owner':
        return Colors.purple.withOpacity(0.2);
      case 'Admin':
        return Colors.blue.withOpacity(0.2);
      case 'Seller':
        return Colors.green.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature tez orada ishga tushadi!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
