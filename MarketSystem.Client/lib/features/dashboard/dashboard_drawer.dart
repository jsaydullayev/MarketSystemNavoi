import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/auth/permission_context.dart';
import '../../core/auth/permissions.dart';
import '../../core/auth/session_actions.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/base64_image.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [..._menuTiles(context, role)],
              ),
            ),
            Divider(
              color: context.colors.border,
              indent: AppSpacing.xl,
              endIndent: AppSpacing.xl,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
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
    void go(VoidCallback nav) {
      Navigator.pop(context);
      nav();
    }

    return [
      if (context.can(Permissions.productsAccess))
        _SettingsTile(
          icon: Icons.inventory_2_rounded,
          label: l10n.products,
          onTap: () => go(
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductsScreen(
                  isReadOnly: !context.can(Permissions.productsEdit),
                ),
              ),
            ),
          ),
        ),
      if (context.can(Permissions.categoriesAccess))
        _SettingsTile(
          icon: Icons.grid_view_rounded,
          label: l10n.categories,
          onTap: () => go(
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryManagementScreen(),
              ),
            ),
          ),
        ),
      if (context.can(Permissions.salesAccess))
        _SettingsTile(
          icon: Icons.shopping_bag_rounded,
          label: l10n.sales,
          onTap: () => go(() => Navigator.pushNamed(context, AppRoutes.sales)),
        ),
      if (context.can(Permissions.salesAccess))
        _SettingsTile(
          icon: Icons.receipt_long_rounded,
          label: l10n.dailySales,
          onTap: () => go(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailySalesScreen()),
            ),
          ),
        ),
      if (context.can(Permissions.customersAccess))
        _SettingsTile(
          icon: Icons.people_alt_rounded,
          label: l10n.customers,
          onTap: () =>
              go(() => Navigator.pushNamed(context, AppRoutes.customers)),
        ),
      if (context.can(Permissions.zakupAccess))
        _SettingsTile(
          icon: Icons.add_business_rounded,
          label: l10n.zakup,
          onTap: () => go(() => Navigator.pushNamed(context, AppRoutes.zakup)),
        ),
      if (context.can(Permissions.cashRegisterAccess))
        _SettingsTile(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.cashRegister,
          onTap: () =>
              go(() => Navigator.pushNamed(context, AppRoutes.cashRegister)),
        ),
      if (context.can(Permissions.reportsAccess))
        _SettingsTile(
          icon: Icons.bar_chart_rounded,
          label: l10n.reports,
          onTap: () =>
              go(() => Navigator.pushNamed(context, AppRoutes.reports)),
        ),
      if (context.can(Permissions.usersAccess))
        _SettingsTile(
          icon: Icons.admin_panel_settings,
          label: l10n.users,
          onTap: () => go(() => Navigator.pushNamed(context, AppRoutes.users)),
        ),
      if (context.can(Permissions.debtsAccess))
        _SettingsTile(
          icon: Icons.monetization_on_rounded,
          label: l10n.debts,
          onTap: () => go(() => Navigator.pushNamed(context, AppRoutes.debts)),
        ),
      // Audit jurnali — data.auditLog ruxsati bilan (Owner/SuperAdmin doim,
      // Owner ishonchli Admin'ga ham yoqishi mumkin). Ilgari xato bilan faqat
      // SuperAdmin'ga cheklangan edi, shuning uchun Owner panelда ko'rinmasди.
      if (context.can(Permissions.dataAuditLog))
        _SettingsTile(
          icon: Icons.shield_outlined,
          label: l10n.securityJournal,
          onTap: () =>
              go(() => Navigator.pushNamed(context, AppRoutes.securityJournal)),
        ),
    ];
  }

  /// D3 — gate the destructive logout behind a confirmation dialog so an
  /// accidental drawer tap doesn't kick a seller out mid-shift. After the
  /// user confirms, [SessionActions.logout] clears auth state and resets the
  /// back stack to `/login` exactly once (see SessionActions for why the
  /// "/login opens twice" guard lives there rather than here).
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _confirmLogout(context);
    if (confirmed != true) return;
    if (!context.mounted) return;
    await SessionActions.logout(context);
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
                style: AppTextStyles.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        content: Text(
          l10n.logoutConfirm,
          style: AppTextStyles.bodyMedium().copyWith(
            color: ctx.colors.textSecondary,
          ),
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
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
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
              child: _buildAvatar(
                context,
                user?['profileImage'] as String?,
                initial,
              ),
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
            Icon(
              Icons.edit_note_rounded,
              color: context.colors.brand,
              size: 26,
            ),
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
      imgWidget = CachedNetworkImage(
        imageUrl: img,
        width: 50,
        height: 50,
        memCacheWidth: 144,
        memCacheHeight: 144,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      );
    } else if (img.startsWith('data:image') || img.length > 100) {
      final b64 = img.contains(',') ? img.split(',').last : img;
      // Base64Image decodes once + caches; the old inline base64Decode ran on
      // every drawer rebuild (e.g. AuthProvider notifying while it's open).
      imgWidget = Base64Image(
        data: b64,
        width: 50,
        height: 50,
        cacheWidth: 144,
        cacheHeight: 144,
        errorWidget: fallback,
      );
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
      style: AppTextStyles.titleMedium().copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
