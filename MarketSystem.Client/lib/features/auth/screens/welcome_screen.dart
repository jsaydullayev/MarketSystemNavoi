import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import 'login_screen.dart';
import '../../../core/providers/locale_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.store,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    l10n.welcomeScreenSubtitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Language Selector
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: localeProvider.locale.languageCode,
                              dropdownColor: Colors.blue.shade700,
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              items: const [
                                DropdownMenuItem(
                                  value: 'uz',
                                  child: Text('O\'zbek'),
                                ),
                                DropdownMenuItem(
                                  value: 'ru',
                                  child: Text('Русский'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  localeProvider.setLocale(value);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.login,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
