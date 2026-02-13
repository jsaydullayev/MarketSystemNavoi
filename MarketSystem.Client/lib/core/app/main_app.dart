/// Main App Widget
/// Central app configuration with DI setup
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../utils/di.dart';
import '../constants/app_strings.dart';
import '../handlers/navigation_handler.dart';
import '../routes/app_routes.dart';
import '../routes/route_generator.dart';
import '../theme/app_theme.dart';

// Import BLoCs
import '../../features/sales/presentation/bloc/sales_bloc.dart';
import '../../features/customers/presentation/bloc/customers_bloc.dart';
import '../../features/zakup/presentation/bloc/zakup_bloc.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';

/// Main App Widget
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - must be first, others may depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: sl<AuthService>())),
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Locale Provider
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // BLoC Providers
        BlocProvider(create: (_) => sl<SalesBloc>()),
        BlocProvider(create: (_) => sl<CustomersBloc>()),
        BlocProvider(create: (_) => sl<ZakupBloc>()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: NavigationHandler.navigatorKey,
        onGenerateRoute: generateRoute,
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
        initialRoute: AppRoutes.welcome,
      ),
    );
  }
}
