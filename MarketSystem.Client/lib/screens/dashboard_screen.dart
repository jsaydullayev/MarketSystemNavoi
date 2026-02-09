import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/zakup/screens/zakup_screen.dart';
import '../features/admin_products/screens/admin_products_screen.dart';
import '../features/sales/screens/sales_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/debts/screens/debts_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/reports/screens/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, user),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoCard(user),
                      const SizedBox(height: 16),
                      const Text(
                        'Bo\'limlar',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 10),
                      _buildMenuGrid(context, user),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Market System',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary, size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text(
                    'Tizimdan chiqish',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  content: const Text(
                    'Rostdan ham tizimdan chiqmoqchimisiz?',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
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
    );
  }

  Widget _buildUserInfoCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary,
            child: Text(
              (user?['fullName'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['fullName'] ?? 'Foydalanuvchi',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user?['username'] ?? 'user'}',
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user?['role']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user?['role'] ?? 'Seller',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, dynamic user) {
    final menuItems = [
      _MenuItemData(
        title: 'Mahsulotlar',
        subtitle: user?['role'] == 'Seller'
            ? 'Mahsulotlar ro\'yxati'
            : 'Mahsulotlarni boshqarish',
        icon: Icons.inventory_2_outlined,
        color: MenuCardColors.products,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsScreen(isReadOnly: user?['role'] == 'Seller'),
          ),
        ),
      ),
      _MenuItemData(
        title: 'Sotuvlar',
        subtitle: 'Sotuvlar tarixi',
        icon: Icons.shopping_cart_outlined,
        color: MenuCardColors.sales,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesScreen()),
        ),
      ),
      _MenuItemData(
        title: 'Mijozlar',
        subtitle: 'Mijozlar ro\'yxati',
        icon: Icons.people_outline,
        color: MenuCardColors.customers,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomersScreen()),
        ),
      ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: 'Xaridlar',
          subtitle: 'Maxsulot xaridlari',
          icon: Icons.shopping_bag_outlined,
          color: MenuCardColors.zakup,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ZakupScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: 'Hisobotlar',
          subtitle: 'Tizim hisobotlari',
          icon: Icons.bar_chart_outlined,
          color: MenuCardColors.reports,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: 'Qarzdorlik',
          subtitle: 'Mijozlar qarzlari',
          icon: Icons.money_outlined,
          color: MenuCardColors.debts,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebtsScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: 'Foydalanuvchilar',
          subtitle: 'Foydalanuvchilarni boshqarish',
          icon: Icons.admin_panel_settings_outlined,
          color: MenuCardColors.users,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsersScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: 'Admin: Mahsulotlar',
          subtitle: 'Narxlarni boshqarish',
          icon: Icons.settings_outlined,
          color: MenuCardColors.adminProducts,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
          ),
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildAnimatedMenuItem(menuItems[index], index);
      },
    );
  }

  Widget _buildAnimatedMenuItem(_MenuItemData item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 150 + (index * 60)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _buildMenuItemCard(item),
    );
  }

  Widget _buildMenuItemCard(_MenuItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: AppTheme.menuCardDecoration(item.color),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'Owner':
        return AppTheme.accent;
      case 'Admin':
        return AppTheme.primary;
      case 'Seller':
        return AppTheme.secondary;
      default:
        return Colors.grey;
    }
  }
}

class _MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
