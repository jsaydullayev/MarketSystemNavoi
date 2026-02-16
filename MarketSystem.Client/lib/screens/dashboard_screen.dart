import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/admin_products/screens/admin_products_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/debts/screens/debts_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/cash_register/screens/cash_register_screen.dart';
import '../features/market/screens/market_registration_screen.dart';
import '../features/daily_sales/screens/daily_sales_screen.dart';
import '../features/sales/screens/draft_sales_screen.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../data/services/report_service.dart';
import '../data/models/profit_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Data for Owner
  ProfitSummaryModel? _profitSummary;
  CashBalanceModel? _cashBalance;
  bool _isLoadingProfit = false;
  String? _profitError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Load profit data if Owner - delay to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?['role'] == 'Owner') {
        _loadOwnerData();
      }
    });
  }

  Future<void> _loadOwnerData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoadingProfit = true;
      _profitError = null;
    });

    try {
      final reportService = ReportService(authProvider: authProvider);
      final profitSummary = await reportService.getProfitSummary();
      final cashBalance = await reportService.getCashBalance();

      if (mounted) {
        setState(() {
          _profitSummary = profitSummary;
          _cashBalance = cashBalance;
          _isLoadingProfit = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profitError = e.toString();
          _isLoadingProfit = false;
        });
      }
    }
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
    final isOwner = user?['role'] == 'Owner';

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
                      _buildUserInfoCard(context, user),

                      // Profit cards for Owner only
                      if (isOwner) ...[
                        const SizedBox(height: 16),
                        _buildProfitCards(context),
                      ],

                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.dashboard,
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.appTitle,
            style: const TextStyle(
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
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  content: Text(
                    l10n.logoutConfirm,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.no),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.yes),
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

  Widget _buildUserInfoCard(BuildContext context, dynamic user) {
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
                  user?['fullName'] ?? 'User',
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

  Widget _buildProfitCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingProfit) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_profitError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          _profitError!,
          style: TextStyle(color: Colors.red.shade800),
        ),
      );
    }

    return Column(
      children: [
        // Profit Summary Row
        Row(
          children: [
            Expanded(
              child: _buildProfitCard(
                context,
                icon: Icons.today_outlined,
                title: "Bugun",
                value: _profitSummary?.todayProfit.toStringAsFixed(0) ?? '0',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildProfitCard(
                context,
                icon: Icons.calendar_view_week_outlined,
                title: "Hafta",
                value: _profitSummary?.weekProfit.toStringAsFixed(0) ?? '0',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildProfitCard(
                context,
                icon: Icons.calendar_month_outlined,
                title: "Oy",
                value: _profitSummary?.monthProfit.toStringAsFixed(0) ?? '0',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildProfitCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: "Kassa",
                value: _cashBalance?.cashInRegister.toStringAsFixed(0) ?? '0',
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfitCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value so\'m',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final menuItems = [
      _MenuItemData(
        title: l10n.products,
        subtitle: user?['role'] == 'Seller'
            ? l10n.productList
            : l10n.productManagement,
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
        title: l10n.sales,
        subtitle: l10n.salesHistory,
        icon: Icons.shopping_cart_outlined,
        color: MenuCardColors.sales,
        onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
      ),
      _MenuItemData(
        title: 'Kunlik Savdolar',
        subtitle: 'Bugungi savdo ro\'yxati',
        icon: Icons.receipt_long_outlined,
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailySalesScreen()),
        ),
      ),
      _MenuItemData(
        title: 'Draft Savdolar',
        subtitle: 'Tugatilmagan savdolar',
        icon: Icons.edit_note_outlined,
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DraftSalesScreen()),
        ),
      ),
      _MenuItemData(
        title: l10n.customers,
        subtitle: l10n.customerList,
        icon: Icons.people_outline,
        color: MenuCardColors.customers,
        onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
      ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.zakup,
          subtitle: l10n.productPurchases,
          icon: Icons.shopping_bag_outlined,
          color: MenuCardColors.zakup,
          onTap: () => Navigator.pushNamed(context, AppRoutes.zakup),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.reports,
          subtitle: l10n.systemReports,
          icon: Icons.bar_chart_outlined,
          color: MenuCardColors.reports,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.debts,
          subtitle: l10n.customerDebts,
          icon: Icons.money_outlined,
          color: MenuCardColors.debts,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebtsScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.users,
          subtitle: l10n.userManagement,
          icon: Icons.admin_panel_settings_outlined,
          color: MenuCardColors.users,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsersScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.adminProducts,
          subtitle: l10n.priceManagement,
          icon: Icons.settings_outlined,
          color: MenuCardColors.adminProducts,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
          ),
        ),
      if (user?['role'] == 'Admin' || user?['role'] == 'Owner')
        _MenuItemData(
          title: l10n.cashRegister,
          subtitle: l10n.currentBalance,
          icon: Icons.account_balance_wallet_outlined,
          color: MenuCardColors.zakup,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CashRegisterScreen()),
          ),
        ),
      // Market Registration - only for Owner without market
      if (user?['role'] == 'Owner' && user?['marketId'] == null)
        _MenuItemData(
          title: 'Market Registratsiyasi',
          subtitle: 'O\'zingizning marketingizni yarating',
          icon: Icons.store_outlined,
          color: MenuCardColors.products,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketRegistrationScreen()),
          ),
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
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
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: 6),

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
