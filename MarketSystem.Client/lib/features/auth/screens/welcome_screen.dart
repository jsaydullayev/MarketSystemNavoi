import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/extensions/app_extensions.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final primaryColor = AppColors.getPrimary(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color.fromARGB(255, 5, 9, 30) : Colors.white,
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
                40.height,
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
}
