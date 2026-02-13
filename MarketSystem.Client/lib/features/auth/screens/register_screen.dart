import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../screens/dashboard_screen.dart';
import '../../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Seller';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _roles = ['Seller', 'Admin', 'Owner'];

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
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

      final success = await authProvider.register(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        language: localeProvider.locale.languageCode,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // Get error message based on error code
        String errorText;
        switch (authProvider.errorCode) {
          case 'register_failed':
            errorText = l10n.registerError;
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
                      child: const Icon(
                        Icons.person_add,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      l10n.registerScreenTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.createNewAccount,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(18),
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
                          // Full Name field
                          TextFormField(
                            controller: _fullNameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.fullName,
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterFullName;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.username,
                              icon: Icons.account_circle_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterUsername;
                              }
                              if (value.length < 3) {
                                return l10n.usernameMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

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
                              if (value.length < 6) {
                                return l10n.passwordMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Confirm Password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: AppTheme.inputDecoration(
                              label: l10n.passwordConfirm,
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.passwordConfirmRequired;
                              }
                              if (value != _passwordController.text) {
                                return l10n.passwordMismatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Role dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            dropdownColor: Colors.white,
                            iconEnabledColor: AppTheme.textSecondary,
                            decoration: AppTheme.inputDecoration(
                              label: l10n.role,
                              icon: Icons.badge_outlined,
                            ),
                            items: _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(
                                  role,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Register button
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
                                  onPressed: _register,
                                  style: AppTheme.primaryButtonStyle,
                                  child: Text(l10n.register),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back to login button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                      child: Text(l10n.backToLogin),
                    ),

                    const SizedBox(height: 8),

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
