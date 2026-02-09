import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'data/services/http_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final httpService = HttpService();
    final authService = AuthService(httpService: httpService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Market System',
            debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('uz'), // Uzbek
              Locale('ru'), // Russian
              Locale('en'), // English (fallback)
            ],
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
