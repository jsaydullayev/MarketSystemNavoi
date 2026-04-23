import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/extensions/app_extensions.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final primaryColor = AppColors.getPrimary(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                20.height,
                _buildHeader(context, isDark, l10n),
                const Spacer(flex: 2),
                _buildBrandSection(isDark),
                const Spacer(flex: 3),
                _buildStartButton(context, primaryColor, l10n),
                20.height,
                TextButton(
                  onPressed: () => _showPrivacyDialog(context, isDark),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                20.height,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return _buildLanguageDropdown(
                context, localeProvider, l10n, isDark);
          },
        ),
        _buildThemeToggle(context, isDark),
      ],
    );
  }

  Widget _buildBrandSection(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          isDark
              ? 'assets/images/blueLogo.png'
              : 'assets/images/orangeLogo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        24.height,
        Text(
          "STROTECH",
          style: AppStyles.brandTitle.copyWith(
            fontSize: 28,
            letterSpacing: 8,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(
      BuildContext context, Color primaryColor, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_first_time', false);
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
        child: Text(
          l10n.login,
          style: AppStyles.cardTitle.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, LocaleProvider provider,
      AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.locale.languageCode,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.black54),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          onChanged: (value) =>
              value != null ? provider.setLocale(value) : null,
          items: [
            DropdownMenuItem(
                value: 'uz',
                child: Text("O'zbekcha",
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black))),
            DropdownMenuItem(
                value: 'ru',
                child: Text("Русский",
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black))),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    return IconButton(
      onPressed: () => isDark
          ? AdaptiveTheme.of(context).setLight()
          : AdaptiveTheme.of(context).setDark(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
          key: ValueKey(isDark),
          color: isDark ? Colors.amber : Colors.black87,
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrivacySection(
                        'Introduction',
                        'This Privacy Policy describes how MarketSystem collects, uses, and protects your personal information. By using our application, you agree to the terms of this policy.',
                        isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacySection(
                        'Data Collection',
                        'We collect the following types of information:\n\n'
                        '1. Personal Information: Name, email address, phone number\n'
                        '2. Usage Data: How you interact with the application\n'
                        '3. Device Information: Device type, operating system, unique device identifiers\n'
                        '4. Business Data: Sales, inventory, customer information (if you are a business user)',
                        isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacySection(
                        'Data Usage',
                        'We use the collected information for:\n\n'
                        '• Providing and maintaining our services\n'
                        '• Improving user experience\n'
                        '• Processing transactions\n'
                        '• Sending notifications about important updates\n'
                        '• Analyzing usage patterns to enhance our services',
                        isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacySection(
                        'Data Security',
                        'We take data security seriously and implement appropriate measures to protect your information:\n\n'
                        '• Encryption of sensitive data in transit and at rest\n'
                        '• Regular security audits\n'
                        '• Access controls and authentication\n'
                        '• Secure data storage and backup systems',
                        isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacySection(
                        'Your Rights',
                        'You have the following rights regarding your data:\n\n'
                        '• Access to your personal information\n'
                        '• Request correction of inaccurate data\n'
                        '• Request deletion of your account and data\n'
                        '• Opt-out of marketing communications\n'
                        '• Export your data',
                        isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildPrivacySection(
                        'Contact Information',
                        'If you have questions about this Privacy Policy or your data, please contact us at:\n\n'
                        'Email: support@strotech.uz\n'
                        'Website: https://strotech.uz',
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
