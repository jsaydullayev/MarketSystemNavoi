/// Main App Widget
/// Central app configuration with DI setup
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../utils/di.dart';
import '../constants/app_strings.dart';
import '../handlers/navigation_handler.dart';
import '../routes/app_routes.dart';
import '../routes/route_generator.dart';
import '../theme/app_theme.dart';

/// Main App Widget
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: NavigationHandler.navigatorKey,
      onGenerateRoute: generateRoute,
      localizationsDelegates: const [
        // AppLocalizations.delegate, // TODO: Add localization
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz'), // Uzbek
        Locale('ru'), // Russian
        Locale('en'), // English
      ],
      initialRoute: AppRoutes.welcome,
    );
  }
}
