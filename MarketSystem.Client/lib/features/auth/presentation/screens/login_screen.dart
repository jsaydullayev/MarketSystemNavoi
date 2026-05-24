// Login screen — migrated to the new design system (AppColors, AppSpacing,
// AppTextStyles, AppPrimaryButton, AppTextInput). Preserves all business logic
// from the original implementation: AuthProvider, structured LoginOutcome
// handling, market-blocked dialog, autofill disabled, SuperAdmin routing, and
// language persistence. The visual design follows the HTML demo 12.1 Login.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/network_wrapper.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../../../design/widgets/app_text_input.dart';
import '../../../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // D2 — wrap login so the user sees the localized no-internet panel
    // up front instead of typing a password and watching the submit
    // call hang. There's no auto-retry here (login is user-initiated);
    // restoring the connection just dismisses the panel.
    return NetworkWrapper(
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DecoratedBox(
          // Subtle white -> brandLight gradient, matching the demo's auth-screen
          // background.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.colors.surface, context.colors.brandLight],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 40,
                  left: AppSpacing.xl3,
                  right: AppSpacing.xl3,
                  bottom: AppSpacing.xl3,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBrand(),
                          const SizedBox(height: AppSpacing.xl4),
                          _buildTitleBlock(),
                          const SizedBox(height: 22),
                          Builder(
                            builder: (ctx) {
                              final l10n = AppLocalizations.of(ctx)!;
                              return AppTextInput(
                                label: l10n.loginLabel,
                                hint: l10n.loginLabel,
                                prefixIcon: Icons.person_outline_rounded,
                                controller: _usernameController,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? l10n.loginHint
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Builder(
                            builder: (ctx) {
                              final l10n = AppLocalizations.of(ctx)!;
                              return AppTextInput(
                                label: l10n.password,
                                hint: l10n.password,
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                controller: _passwordController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.passwordHint
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: context.colors.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          _buildHelperRow(),
                          const SizedBox(height: AppSpacing.lg),
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) {
                              final l10n = AppLocalizations.of(context)!;
                              return AppPrimaryButton(
                                label: l10n.loginButton,
                                isLoading: auth.isLoading,
                                onPressed: auth.isLoading ? null : _login,
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          _buildDivider(),
                          const SizedBox(height: AppSpacing.xl2),
                          _buildBottomLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Building blocks ------------------------------------------------------

  Widget _buildBrand() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.brand,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            boxShadow: [
              BoxShadow(
                color: context.colors.brand.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: AppTextStyles.displayLarge().copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Strotech',
          style: AppTextStyles.titleLarge().copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.appTagline,
          style: AppTextStyles.bodySmall().copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTitleBlock() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loginAction,
          style: AppTextStyles.titleMedium().copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.loginFormSubtitle,
          style: AppTextStyles.bodySmall().copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildHelperRow() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: context.colors.brand,
                    side: BorderSide(color: context.colors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.rememberMe,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 13,
                    color: context.colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: _showForgotPasswordHint,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.forgotPassword,
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.brand,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            l10n.orDivider,
            style: AppTextStyles.caption().copyWith(
              fontSize: 11,
              letterSpacing: 1,
              color: context.colors.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.border, height: 1)),
      ],
    );
  }

  Widget _buildBottomLink() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.bodySmall().copyWith(
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
          children: [
            TextSpan(text: l10n.noAccount),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                child: Text(
                  l10n.createNewShop,
                  style: AppTextStyles.bodySmall().copyWith(
                    fontSize: 13,
                    color: context.colors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Behavior -------------------------------------------------------------

  void _showForgotPasswordHint() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.forgotPasswordContactAdmin),
        backgroundColor: context.colors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      TextInput.finishAutofillContext();

      final user = authProvider.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', user?['role'] ?? '');
      await prefs.setString('user_full_name', user?['fullName'] ?? '');
      await prefs.setString('user_username', user?['username'] ?? '');

      if (user != null && user['language'] != null) {
        await localeProvider.setLocale(user['language']);
      }

      if (!mounted) return;

      // SuperAdmin accounts are cross-tenant and have no market to land in,
      // so the regular dashboard would just show errors. Route them to the
      // hidden console; every other role goes to the normal dashboard.
      final isSuperAdmin = (user?['role'] as String?) == 'SuperAdmin';
      if (isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminConsole);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
      return;
    }

    // Market-blocked is the only error that warrants a full dialog — it
    // carries the SuperAdmin's reason and timestamp, which a snackbar would
    // hide and send the operator chasing fake credential issues.
    if (authProvider.errorCode == 'market_blocked') {
      await _showMarketBlockedDialog(
        reason: authProvider.loginBlockReason,
        blockedAt: authProvider.loginBlockedAt,
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    String errorText;
    switch (authProvider.errorCode) {
      case 'login_failed':
        errorText = l10n.loginFailed;
        break;
      case 'rate_limited':
        errorText = l10n.rateLimited;
        break;
      case 'network_error':
        errorText = l10n.networkError;
        break;
      default:
        errorText = l10n.loginGenericError;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorText),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _showMarketBlockedDialog({
    String? reason,
    DateTime? blockedAt,
  }) async {
    if (!mounted) return;

    String two(int n) => n < 10 ? '0$n' : '$n';
    String? formattedTime;
    if (blockedAt != null) {
      final local = blockedAt.toLocal();
      formattedTime =
          '${local.year}-${two(local.month)}-${two(local.day)}  '
          '${two(local.hour)}:${two(local.minute)}';
    }

    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.block_outlined,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                l10n.shopBlocked,
                style: AppTextStyles.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shopBlockedBody,
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  border: Border.all(color: AppColors.danger),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.blockReasonUpper,
                      style: AppTextStyles.caption().copyWith(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      reason,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: context.colors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (formattedTime != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.blockedAtLabel(formattedTime),
                    style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: context.colors.brand),
            child: Text(l10n.dismiss),
          ),
        ],
      ),
    );
  }
}
