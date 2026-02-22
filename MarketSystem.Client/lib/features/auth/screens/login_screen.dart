import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/providers/locale_provider.dart';
import 'package:market_system_client/core/theme/app_theme.dart';
import 'package:market_system_client/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

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
    final size = MediaQuery.of(context).size;
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
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(context, isDark, size),
                    SizedBox(height: size.height * 0.04),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.06),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark ? Colors.white10 : Colors.white),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.login,
                                style: TextStyle(
                                    fontSize: size.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87),
                              ),
                              SizedBox(height: size.height * 0.03),
                              _buildTextField(
                                controller: _usernameController,
                                label: l10n.username,
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                size: size,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? l10n.enterUsername
                                        : null,
                              ),
                              SizedBox(height: size.height * 0.02),
                              _buildTextField(
                                controller: _passwordController,
                                label: l10n.password,
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                isPassword: true,
                                size: size,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? l10n.enterPassword
                                        : null,
                              ),
                              SizedBox(height: size.height * 0.03),
                              _buildLoginButton(
                                  context, primaryColor, l10n, size),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    TextButton(
                      onPressed: () => _showRegisterInfo(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white.withOpacity(0.9)
                            : primaryColor,
                      ),
                      child: Text(
                        l10n.register,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.038,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              isDark ? Colors.white70 : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark, Size size) {
    return Column(
      children: [
        Image.asset(
          isDark
              ? 'assets/images/blueLogo.png'
              : 'assets/images/orangeLogo.png',
          width: size.height * 0.12,
          height: size.height * 0.12,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Size size,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: size.width * 0.03,
                color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          cursorColor: isDark ? Colors.white : Colors.blue,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: size.width * 0.04,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            prefixIcon: Icon(icon,
                size: size.width * 0.05,
                color: isDark ? Colors.white60 : Colors.black45),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: size.width * 0.05,
                        color: isDark ? Colors.white60 : Colors.black45),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(
                vertical: size.height * 0.018, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(
      BuildContext context, Color primaryColor, var l10n, Size size) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: size.height * 0.065 > 56 ? 60 : 54,
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.045)),
          ),
        );
      },
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
            const SizedBox(height: 16),
            Text(l10n.info,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(l10n.registrationPendingInfo, textAlign: TextAlign.center),
            const SizedBox(height: 20),
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
