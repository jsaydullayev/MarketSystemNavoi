import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_styles.dart';
import 'package:market_system_client/core/extensions/app_extensions.dart';
import 'package:market_system_client/core/providers/locale_provider.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = AppColors.getPrimary(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(isDark),
                      40.height,
                      _buildGlassForm(context, isDark, primaryColor, l10n),
                      30.height,
                      _buildRegisterLink(primaryColor, isDark, l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Image.asset(
      isDark ? 'assets/images/blueLogo.png' : 'assets/images/orangeLogo.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
  }

  Widget _buildGlassForm(
      BuildContext context, bool isDark, Color primaryColor, var l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.login,
                  style: AppStyles.brandTitle
                      .copyWith(color: isDark ? Colors.white : Colors.black87)),
              30.height,
              _buildTextField(
                controller: _usernameController,
                label: l10n.username,
                icon: Icons.person_outline_rounded,
                isDark: isDark,
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.enterUsername
                    : null,
              ),
              20.height,
              _buildTextField(
                controller: _passwordController,
                label: l10n.password,
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                isPassword: true,
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.enterPassword
                    : null,
              ),
              30.height,
              _buildLoginButton(primaryColor, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppStyles.subtitle
                .copyWith(color: isDark ? Colors.white70 : Colors.black54)),
        8.height,
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          cursorColor: isDark ? Colors.white : Colors.blue,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            prefixIcon:
                Icon(icon, color: isDark ? Colors.white60 : Colors.black45),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDark ? Colors.white60 : Colors.black45),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(Color primaryColor, var l10n) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.login,
                    style: AppStyles.cardTitle.copyWith(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink(Color primaryColor, bool isDark, var l10n) {
    return TextButton(
      onPressed: () => _showRegisterInfo(context),
      child: Text(
        l10n.register,
        style: TextStyle(
          color: isDark ? Colors.white70 : primaryColor,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        final user = authProvider.user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', user?['role'] ?? '');
        await prefs.setString('user_full_name', user?['fullName'] ?? '');
        await prefs.setString('user_username', user?['username'] ?? '');

        if (user != null && user['language'] != null) {
          await localeProvider.setLocale(user['language']);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        String errorText;
        switch (authProvider.errorCode) {
          case 'login_failed':
            errorText = l10n.loginError;
            break;
          case 'network_error':
            errorText = l10n.networkError;
            break;
          default:
            errorText = l10n.error;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _showRegisterInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 50, color: Colors.orange),
            16.height,
            Text(l10n.info,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            12.height,
            Text(l10n.registrationPendingInfo, textAlign: TextAlign.center),
            20.height,
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(context)),
              child: Text(l10n.understand,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
