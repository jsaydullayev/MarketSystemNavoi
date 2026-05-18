// Dashboard screen — owner / admin / seller home, redesigned to the
// new design system (see lib/design/*). Drawer navigation, role gating,
// theme toggle, language switcher, and logout are preserved from the
// previous implementation; only the body has been rebuilt to match the
// HTML demo (#page-owner-dash and #page-staff-dash in design-demo).

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../categories/screens/category_management_screen.dart';
import '../daily_sales/screens/daily_sales_screen.dart';
import '../products/presentation/screens/products_screen.dart';
import '../profile/screens/profile_screen.dart';
import 'dashboard_widgets.dart';

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
    final role = (user?['role'] ?? 'Seller') as String;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _DashboardDrawer(user: user, role: role, l10n: l10n),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: AppColors.text),
          ),
        ),
        title: Text(
          'STROTECH',
          style: AppTextStyles.titleMedium()
              .copyWith(letterSpacing: 2, color: AppColors.text),
        ),
      ),
      body: _DashboardBody(user: user, role: role),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — switches layout by role: Owner shows the analytics dashboard,
// Seller/Admin show the action-focused layout.
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.user, required this.role});

  final dynamic user;
  final String role;

  String _fullName() {
    final raw = user?['fullName'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return 'Foydalanuvchi';
  }

  String _dateLabel() {
    const months = [
      'yanvar',
      'fevral',
      'mart',
      'aprel',
      'may',
      'iyun',
      'iyul',
      'avgust',
      'sentabr',
      'oktabr',
      'noyabr',
      'dekabr',
    ];
    final now = DateTime.now();
    return '${now.day}-${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName();
    final date = _dateLabel();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GreetingCard(
              fullName: name,
              role: role,
              dateLabel: date,
              onSettingsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const SizedBox(height: 14),
            if (role == 'Owner')
              const _OwnerBody()
            else
              _SellerBody(role: role),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Owner layout — hero card + KPI grid + alerts + chart + top sellers.
// ---------------------------------------------------------------------------

class _OwnerBody extends StatelessWidget {
  const _OwnerBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SalesHeroCard(
          amount: '2 450 000',
          deltaText: "15% kechagidan ko'p",
          stats: [
            SalesHeroStat(value: '28', label: 'Chek'),
            SalesHeroStat(value: '15', label: 'Mijoz'),
            SalesHeroStat(value: '450K', label: 'Foyda'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Statistika',
          actionLabel: "Hammasini ko'rish",
          onAction: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        const SizedBox(height: AppSpacing.md),
        const _KpiGrid(),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Ogohlantirish'),
        const SizedBox(height: AppSpacing.md),
        AlertCard(
          emoji: '💸',
          title: 'Bugun 3 ta qarzga sotildi',
          description: 'Jami: 1 250 000 UZS',
          tone: AlertTone.danger,
          onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
        ),
        const SizedBox(height: AppSpacing.md),
        AlertCard(
          emoji: '📦',
          title: '5 ta mahsulot tugab qoldi',
          description: 'Coca-Cola 1.5L, Pepsi 0.5L va boshqalar',
          tone: AlertTone.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductsScreen(isReadOnly: false),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Tahlil',
          actionLabel: 'Hisobotlar',
          onAction: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        const SizedBox(height: AppSpacing.md),
        const ChartCard(
          title: '7-kunlik sotuv',
          period: 'Bu hafta',
          bars: [0.40, 0.55, 0.35, 0.70, 0.60, 0.85, 1.00],
          footerValue: '12.4M UZS',
          footerDelta: "18% o'tgan haftadan",
        ),
        const SizedBox(height: AppSpacing.lg),
        const TopSellersCard(
          title: "Eng ko'p sotilgan",
          period: 'Bu oy',
          entries: [
            TopSellerEntry(
                emoji: '🥤', name: 'Coca-Cola 0.5L', countLabel: '248 dona'),
            TopSellerEntry(
                emoji: '🍞', name: 'Non (oddiy)', countLabel: '187 dona'),
            TopSellerEntry(
                emoji: '🚬',
                name: 'Sigaret Hollywood',
                countLabel: '156 dona'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 700;
        final crossCount = isWide ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: const [
            KpiCard(
              emoji: '💰',
              value: '12.4M',
              label: 'Bu hafta foyda',
              tone: KpiTone.green,
            ),
            KpiCard(
              emoji: '📊',
              value: '68M',
              label: 'Bu oy aylanma',
              tone: KpiTone.purple,
            ),
            KpiCard(
              emoji: '👥',
              value: '86',
              label: 'Mijozlar',
              tone: KpiTone.blue,
            ),
            KpiCard(
              emoji: '💎',
              value: '32',
              label: 'Top mahsulot',
              tone: KpiTone.orange,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Seller / Admin layout — big CTA, pending sale, quick stats, admin shortcuts.
// ---------------------------------------------------------------------------

class _SellerBody extends StatelessWidget {
  const _SellerBody({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerHeroCta(
          emoji: '🛒',
          title: 'Yangi sotuv',
          subtitle: 'Mahsulot tanlash uchun bosing',
          onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
        ),
        const SizedBox(height: AppSpacing.lg),
        PendingSaleCard(
          title: '1 ta sotuv davom etmoqda',
          subtitle: 'Chek #1247 · 3 dona · 42 000 UZS',
          onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SellerStatsRow(
          stats: [
            SalesHeroStat(value: '12', label: 'Bugun'),
            SalesHeroStat(value: '850K', label: 'Tushum'),
            SalesHeroStat(value: '6 soat', label: 'Smena'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Tezkor amallar'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                emoji: '💸',
                value: 'Qarz',
                label: 'Qarz qabul qilish',
                tone: KpiTone.orange,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.debts),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiCard(
                emoji: '↩️',
                value: 'Qaytarish',
                label: 'Sotuvni qaytarish',
                tone: KpiTone.blue,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.sales),
              ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Admin'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  emoji: '🧾',
                  value: 'Hisobot',
                  label: 'Hisobotlar',
                  tone: KpiTone.green,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.reports),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: KpiCard(
                  emoji: '💼',
                  value: 'Kassa',
                  label: 'Kassa boshqaruvi',
                  tone: KpiTone.purple,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.cashRegister),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer — preserves the previous menu items, theme toggle, language
// switcher, and logout, but uses the new design tokens for surfaces / type.
// ---------------------------------------------------------------------------

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.user,
    required this.role,
    required this.l10n,
  });

  final dynamic user;
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 900 ? 320.0 : 280.0;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    return Drawer(
      width: width,
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user, role: role, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                children: [
                  ..._menuTiles(context, role),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsTile(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDark ? l10n.lightMode : l10n.darkMode,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeThumbColor: AppColors.brand,
                      onChanged: (_) {
                        if (isDark) {
                          AdaptiveTheme.of(context).setLight();
                        } else {
                          AdaptiveTheme.of(context).setDark();
                        }
                      },
                    ),
                    onTap: () {
                      if (isDark) {
                        AdaptiveTheme.of(context).setLight();
                      } else {
                        AdaptiveTheme.of(context).setDark();
                      }
                    },
                  ),
                  Consumer<LocaleProvider>(
                    builder: (context, lp, _) => _SettingsTile(
                      icon: Icons.translate_rounded,
                      label: lp.locale.languageCode == 'uz'
                          ? "O'zbekcha"
                          : 'Русский',
                      onTap: () => _showLanguageDialog(context, lp),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                color: AppColors.border,
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
                height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: _SettingsTile(
                icon: Icons.logout_rounded,
                label: l10n.logout,
                tint: AppColors.danger,
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the list of menu tiles, gated by role.
  List<Widget> _menuTiles(BuildContext context, String role) {
    final items = <_DrawerItem>[
      _DrawerItem(
        icon: Icons.inventory_2_rounded,
        label: l10n.products,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsScreen(isReadOnly: role == 'Seller'),
          ),
        ),
      ),
      _DrawerItem(
        icon: Icons.grid_view_rounded,
        label: l10n.categories,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
        ),
      ),
      _DrawerItem(
        icon: Icons.shopping_bag_rounded,
        label: l10n.sales,
        onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
      ),
      _DrawerItem(
        icon: Icons.receipt_long_rounded,
        label: l10n.dailySales,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailySalesScreen()),
        ),
      ),
      _DrawerItem(
        icon: Icons.people_alt_rounded,
        label: l10n.customers,
        onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
      ),
      _DrawerItem(
        icon: Icons.add_business_rounded,
        label: l10n.zakup,
        onTap: () => Navigator.pushNamed(context, AppRoutes.zakup),
      ),
    ];

    if (role == 'Admin' || role == 'Owner') {
      items.addAll([
        _DrawerItem(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.cashRegister,
          onTap: () => Navigator.pushNamed(context, AppRoutes.cashRegister),
        ),
        _DrawerItem(
          icon: Icons.bar_chart_rounded,
          label: l10n.reports,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        _DrawerItem(
          icon: Icons.admin_panel_settings,
          label: l10n.users,
          onTap: () => Navigator.pushNamed(context, AppRoutes.users),
        ),
        _DrawerItem(
          icon: Icons.monetization_on_rounded,
          label: l10n.debts,
          onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
        ),
      ]);
    }

    return [
      for (final it in items)
        _SettingsTile(
          icon: it.icon,
          label: it.label,
          onTap: () {
            Navigator.pop(context); // close drawer first
            it.onTap();
          },
        ),
    ];
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider lp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: AppColors.brand),
            const SizedBox(width: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: AppTextStyles.titleMedium(),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(ctx, lp, "O'zbekcha", 'uz', '🇺🇿'),
            _languageOption(ctx, lp, 'Русский', 'ru', '🇷🇺'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext ctx,
    LocaleProvider lp,
    String title,
    String code,
    String flag,
  ) {
    final isSelected = lp.locale.languageCode == code;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        lp.setLocale(code);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  isSelected ? AppColors.brand : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.lg),
            Text(title, style: AppTextStyles.bodyLarge()),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer pieces.
// ---------------------------------------------------------------------------

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.user,
    required this.role,
    required this.l10n,
  });

  final dynamic user;
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final name = (user?['fullName'] as String?) ??
        (l10n.localeName == 'uz' ? 'Foydalanuvchi' : 'Пользователь');
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: user?['profileImage'] != null
                  ? Image.network(
                      user!['profileImage'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(initial),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _fallback(initial),
                    )
                  : _fallback(initial),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.labelLarge().copyWith(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_note_rounded,
                color: AppColors.brand, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _fallback(String initial) => Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTextStyles.titleMedium()
              .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final color = tint ?? (isDark ? Colors.white : AppColors.text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium()
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
