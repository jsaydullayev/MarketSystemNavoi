import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Row(
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
              ),
              const Spacer(),
              // Hero(
              //   tag: 'logo',
              //   child: Image.asset(
              //     'assets/images/logo.png',
              //     width: MediaQuery.of(context).size.width * 0.75,
              //   ),
              // ),
              // const SizedBox(height: 24),
              // Text(
              //   l10n.welcomeScreenSubtitle,
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: isDark ? Colors.white70 : Colors.black54,
              //     fontWeight: FontWeight.w400,
              //   ),
              // ),
              Column(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1),
                      children: [
                        TextSpan(
                            text: "ST",
                            style: TextStyle(
                                color: AppColors.getPrimary(context))),
                        TextSpan(
                            text: "ROTECH",
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
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
          onChanged: (value) {
            if (value != null) provider.setLocale(value);
          },
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
      onPressed: () {
        if (isDark) {
          AdaptiveTheme.of(context).setLight();
        } else {
          AdaptiveTheme.of(context).setDark();
        }
      },
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
