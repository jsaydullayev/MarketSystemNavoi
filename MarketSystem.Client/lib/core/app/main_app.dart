/// Main App Widget
/// Central app configuration with DI setup
library;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../utils/di.dart';
import '../constants/app_strings.dart';
import '../handlers/navigation_handler.dart';
import '../routes/route_generator.dart';
import '../routes/navigator_observer.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';
import '../../features/customers/presentation/bloc/customers_bloc.dart';
import '../../features/zakup/presentation/bloc/zakup_bloc.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';

/// Main App Widget
class MainApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MainApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    // Route protection observer for debugging unwanted redirects
    final routeObserver = RouteProtectionObserver();

    return MultiProvider(
      providers: [
        // Auth Provider - must be first, others may depend on it
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: sl<AuthService>())),
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Locale Provider
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // BLoC Providers
        BlocProvider(create: (_) => sl<SalesBloc>()),
        BlocProvider(create: (_) => sl<CustomersBloc>()),
        BlocProvider(create: (_) => sl<ZakupBloc>()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => AdaptiveTheme(
          light: AppThemes.light,
          dark: AppThemes.dark,
          initial: savedThemeMode ?? AdaptiveThemeMode.light,
          builder: (theme, darkTheme) => MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            navigatorKey: NavigationHandler.navigatorKey,
            onGenerateRoute: generateRoute,
            // Add navigator observer to track and warn about unwanted redirects
            navigatorObservers: [routeObserver],
            // Don't set initialRoute - let usePathUrlStrategy() handle it
            // This way /privacy will work directly without going through splash
            locale:
                localeProvider.locale, // ✅ Dynamic locale from LocaleProvider
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('uz'), // Uzbek
              Locale('ru'), // Russian
            ],
          ),
        ),
      ),
    );
  }
}
