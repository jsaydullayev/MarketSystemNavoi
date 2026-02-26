import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_styles.dart';
import '../core/extensions/app_extensions.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/routes/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/categories/screens/category_management_screen.dart';
import '../features/daily_sales/screens/daily_sales_screen.dart';
import '../features/sales/screens/draft_sales_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = user?['role'] ?? 'Seller';
    final l10n = AppLocalizations.of(context)!;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final primaryColor = AppColors.getPrimary(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          drawer: Drawer(
            width: isLargeScreen ? 320 : 280,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
            ),
            child: _buildDrawerContent(
                context, user, role, primaryColor, isDark, l10n),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu_rounded,
                    color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            title: Text("STROTECH",
                style: AppStyles.brandTitle.copyWith(letterSpacing: 2)),
          ),
          body: _buildBody(
              context, role, primaryColor, isDark, l10n, isLargeScreen),
        );
      },
    );
  }

  Widget _buildDrawerContent(BuildContext context, dynamic user, String role,
      Color primary, bool isDark, var l10n) {
    return SafeArea(
      child: Column(
        children: [
          _buildDrawerHeader(context, user, role, primary, isDark, l10n),
          20.height,
          Expanded(
            child: ListTileTheme(
              textColor: isDark ? Colors.white : Colors.black87,
              iconColor: isDark ? Colors.white : Colors.black87,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ListTile(
                    leading: Icon(isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined),
                    title: Text(isDark ? l10n.lightMode : l10n.darkMode),
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeColor: primary,
                      onChanged: (v) =>
                          AdaptiveTheme.of(context).toggleThemeMode(),
                    ),
                  ),
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) => ListTile(
                      leading: const Icon(Icons.translate_rounded),
                      title: Text(localeProvider.locale.languageCode == 'uz'
                          ? "O'zbekcha"
                          : "Русский"),
                      onTap: () => _showLanguageDialog(context, localeProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(l10n.logout,
                style: const TextStyle(color: Colors.redAccent)),
            onTap: () => _handleLogout(context),
          ),
          20.height,
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, dynamic user, String role,
      Color primary, bool isDark, var l10n) {
    final String defaultName =
        l10n.localeName == 'uz' ? "Foydalanuvchi" : "Пользователь";
    return ZoomTapAnimation(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: primary,
              child: Text(user?['fullName']?[0] ?? 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            15.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?['fullName'] ?? defaultName,
                    style: AppStyles.cardTitle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(role,
                      style: TextStyle(
                          color: isDark ? primary.withOpacity(0.9) : primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded, color: primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String role, Color primary,
      bool isDark, var l10n, bool isLargeScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard,
              style: AppStyles.brandTitle.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: isLargeScreen ? 28 : 22)),
          25.height,
          _buildMenuContent(
              context, role, primary, isDark, l10n, isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildMenuContent(BuildContext context, String role, Color primary,
      bool isDark, var l10n, bool isLarge) {
    final menuItems = _getMenuItems(context, role, l10n);
    if (isLarge) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 4),
        itemCount: menuItems.length,
        itemBuilder: (context, index) => _buildWebPremiumCard(
            menuItems[index]['title'],
            menuItems[index]['icon'],
            primary,
            isDark,
            menuItems[index]['onTap']),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: menuItems.length,
        separatorBuilder: (context, index) => 12.height,
        itemBuilder: (context, index) => _buildMobileNeonCard(
            menuItems[index]['title'],
            menuItems[index]['icon'],
            primary,
            isDark,
            menuItems[index]['onTap']),
      );
    }
  }

  List<Map<String, dynamic>> _getMenuItems(
      BuildContext context, String role, var l10n) {
    List<Map<String, dynamic>> items = [
      {
        'title': l10n.products,
        'icon': Icons.inventory_2_rounded,
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductsScreen(isReadOnly: role == 'Seller')))
      },
      {
        'title': l10n.categories,
        'icon': Icons.grid_view_rounded,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoryManagementScreen()))
      },
      {
        'title': l10n.sales,
        'icon': Icons.shopping_bag_rounded,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.sales)
      },
      {
        'title': l10n.dailySales,
        'icon': Icons.receipt_long_rounded,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DailySalesScreen()))
      },
      {
        'title': l10n.drafts,
        'icon': Icons.edit_calendar_rounded,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DraftSalesScreen()))
      },
      {
        'title': l10n.customers,
        'icon': Icons.people_alt_rounded,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.customers)
      },
    ];
    if (role == 'Admin' || role == 'Owner') {
      items.addAll([
        {
          'title': l10n.reports,
          'icon': Icons.bar_chart_rounded,
          'onTap': () => Navigator.pushNamed(context, AppRoutes.reports)
        },
        {
          'title': l10n.users,
          'icon': Icons.admin_panel_settings,
          'onTap': () => Navigator.pushNamed(context, AppRoutes.users)
        },
        {
          'title': l10n.debts,
          'icon': Icons.monetization_on_rounded,
          'onTap': () => Navigator.pushNamed(context, AppRoutes.debts)
        },
      ]);
    }
    return items;
  }

  Widget _buildWebPremiumCard(String title, IconData icon, Color primary,
      bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: primary, size: 24),
            ),
            15.width,
            Expanded(
                child: Text(title,
                    style: AppStyles.cardTitle.copyWith(fontSize: 15))),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNeonCard(String title, IconData icon, Color primary,
      bool isDark, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Icon(icon, color: primary),
      title: Text(title, style: AppStyles.cardTitle.copyWith(fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider lp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.getPrimary(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            Icon(Icons.translate_rounded, color: primary),
            12.width,
            Text(AppLocalizations.of(context)!.selectLanguage,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(ctx, lp, "O'zbekcha", 'uz', '🇺🇿', primary),
            _buildLanguageOption(ctx, lp, "Русский", 'ru', '🇷🇺', primary),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext ctx, LocaleProvider lp, String title,
      String code, String flag, Color primary) {
    // final isSelected = lp.locale.languageCode == code;
    return RadioListTile<String>(
      value: code,
      groupValue: lp.locale.languageCode,
      activeColor: primary,
      title: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          15.width,
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
      onChanged: (val) {
        lp.setLocale(val!);
        Navigator.pop(ctx);
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
}
