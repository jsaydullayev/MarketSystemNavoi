import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login xato'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.welcome,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.username,
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterUsername;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.password,
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterPassword;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Login button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.isLoading) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: AppTheme.primaryButtonStyle,
                                    child: const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: AppTheme.primaryButtonStyle,
                                  child: Text(l10n.login),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer
                    const Text(
                      '© 2026 Market System',
                      style: AppTheme.caption,
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
}
