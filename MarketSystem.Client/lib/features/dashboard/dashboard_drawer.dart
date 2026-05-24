import 'dart:convert' show base64Decode;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permission_context.dart';
import '../../core/auth/permissions.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../categories/screens/category_management_screen.dart';
import '../daily_sales/screens/daily_sales_screen.dart';
import '../products/presentation/screens/products_screen.dart';
import '../profile/screens/profile_screen.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    super.key,
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
      backgroundColor: isDark ? AppColors.darkBg : context.colors.surface,
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
                  Divider(color: context.colors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsTile(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDark ? l10n.lightMode : l10n.darkMode,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeThumbColor: context.colors.brand,
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
            Divider(
                color: context.colors.border,
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

  List<Widget> _menuTiles(BuildContext context, String role) {
    final items = <_DrawerItem>[
      _DrawerItem(
        icon: Icons.inventory_2_rounded,
        label: l10n.products,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductsScreen(isReadOnly: !context.can(Permissions.productsEdit)),
          ),
        ),
      ),
      _DrawerItem(
        icon: Icons.grid_view_rounded,
        label: l10n.categories,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CategoryManagementScreen()),
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
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.cashRegister),
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

    if (context.can(Permissions.dataAuditLog)) {
      items.add(_DrawerItem(
        icon: Icons.shield_outlined,
        label: l10n.securityJournal,
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.securityJournal),
      ));
    }

    return [
      for (final it in items)
        _SettingsTile(
          icon: it.icon,
          label: it.label,
          onTap: () {
            Navigator.pop(context);
            it.onTap();
          },
        ),
    ];
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider lp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            Icon(Icons.translate_rounded, color: context.colors.brand),
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
              color: isSelected
                  ? ctx.colors.brand
                  : ctx.colors.textSecondary,
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

  /// D3 — gate the destructive logout behind a confirmation dialog so an
  /// accidental drawer tap doesn't kick a seller out mid-shift. After the
  /// user confirms, we call `AuthProvider.logout()` and reset the back
  /// stack with `pushNamedAndRemoveUntil` — `pushReplacement` only swaps
  /// the top route, so a backswipe could still land on a stale
  /// authenticated screen with a now-cleared auth provider.
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _confirmLogout(context);
    if (confirmed != true) return;
    if (!context.mounted) return;
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Returns `true` only when the user explicitly taps the danger-styled
  /// "Tizimdan chiqish" / "Выйти" button. Tap-outside, cancel, or back
  /// gesture all resolve to `null` and abort the logout.
  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                l10n.logout,
                style: AppTextStyles.titleMedium()
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        content: Text(
          l10n.logoutConfirm,
          style: AppTextStyles.bodyMedium()
              .copyWith(color: ctx.colors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: AppTextStyles.bodyMedium().copyWith(
                color: ctx.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            ),
            child: Text(
              l10n.yes,
              style: AppTextStyles.bodyMedium().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final rawName = user?['fullName'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName
        : l10n.defaultUserName;
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
          color: isDark ? AppColors.darkSurface : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white12 : context.colors.border,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child:
                  _buildAvatar(context, user?['profileImage'] as String?, initial),
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
                      color: isDark ? Colors.white : context.colors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: context.colors.brand,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded,
                color: context.colors.brand, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? img, String initial) {
    final fallback = _fallback(context, initial);
    if (img == null || img.isEmpty) return fallback;

    Widget? imgWidget;
    if (img.startsWith('http')) {
      imgWidget = Image.network(
        img,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      );
    } else if (img.startsWith('data:image') || img.length > 100) {
      try {
        final b64 = img.contains(',') ? img.split(',').last : img;
        imgWidget = Image.memory(
          base64Decode(b64),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        imgWidget = null;
      }
    }
    return imgWidget ?? fallback;
  }

  Widget _fallback(BuildContext context, String initial) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.brand,
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
    final color = tint ?? (isDark ? Colors.white : context.colors.text);
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
              if (trailing case final t?) t,
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
