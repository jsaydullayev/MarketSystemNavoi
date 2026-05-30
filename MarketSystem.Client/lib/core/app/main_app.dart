/// Main App Widget
/// Central app configuration with DI setup
library;

import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/design/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../utils/di.dart';
import '../constants/app_strings.dart';
import '../auth/session_actions.dart';
import '../handlers/navigation_handler.dart';
import '../routes/route_generator.dart';
import '../routes/navigator_observer.dart';
import '../../data/services/http_service.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';
import '../../features/customers/presentation/bloc/customers_bloc.dart';
import '../../features/zakup/presentation/bloc/zakup_bloc.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';

/// Main App Widget
class MainApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MainApp({super.key, this.savedThemeMode});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Route protection observer for debugging unwanted redirects
  final RouteProtectionObserver _routeObserver = RouteProtectionObserver();

  /// G1 — single global listener for "the backend kicked us out". Fires once
  /// per failed refresh (see HttpService._doRefresh). We route the user to
  /// /login and surface a one-shot "session ended" snackbar. Lives in the
  /// shell rather than per-screen because the failure can hit ANY screen
  /// (dashboard mid-load, reports tab, …) and we want the same recovery
  /// everywhere.
  StreamSubscription<SessionEndedInfo>? _sessionEndedSub;
  StreamSubscription<MarketBlockedInfo>? _marketBlockedSub;

  @override
  void initState() {
    super.initState();
    _sessionEndedSub = HttpService.sessionEndedStream.listen(_onSessionEnded);
    _marketBlockedSub = HttpService.marketBlockedStream.listen(_onMarketBlocked);
  }

  void _onMarketBlocked(MarketBlockedInfo info) {
    final ctx = NavigationHandler.navigatorKey.currentContext;
    if (ctx == null) return;

    final l10n = AppLocalizations.of(ctx);
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n?.statusBlocked ?? 'Bloklangan'),
        content: Text(info.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              SessionActions.redirectToLogin();
            },
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }

  void _onSessionEnded(SessionEndedInfo info) {
    final ctx = NavigationHandler.navigatorKey.currentContext;
    // If the navigator hasn't mounted yet (very early in startup) just bail
    // — the splash screen will route to /login on its own once the user is
    // unauthenticated.
    if (ctx == null) return;

    final l10n = AppLocalizations.of(ctx);
    final message = l10n?.sessionExpired ?? 'Sessiya tugadi, qayta kiring';

    // Best-effort snackbar BEFORE the route swap so it survives the
    // navigation by attaching to the new scaffold via ScaffoldMessenger.
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );

    SessionActions.redirectToLogin();
  }

  @override
  void dispose() {
    _sessionEndedSub?.cancel();
    _marketBlockedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - must be first, others may depend on it
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: sl<AuthService>()),
        ),
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
          // Two themes: light = brand orange (#FF6B00), dark = legacy blue (#1E3A8A).
          // Users can switch via the dashboard drawer or welcome-screen toggle.
          light: AppTheme.light,
          dark: AppTheme.dark,
          initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
          builder: (theme, darkTheme) => MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            // No themeMode here: AdaptiveTheme already decides which of the
            // two ThemeData objects to feed into MaterialApp's `theme` slot.
            // Previously we passed `ThemeMode.system`, which forced Flutter
            // to ignore AdaptiveTheme's manual setLight()/setDark()/toggle
            // and follow the OS preference instead — so the in-app theme
            // toggle (profile + drawer) silently did nothing.
            navigatorKey: NavigationHandler.navigatorKey,
            onGenerateRoute: generateRoute,
            // Add navigator observer to track and warn about unwanted redirects
            navigatorObservers: [_routeObserver],
            // CRITICAL: Don't set initialRoute - let usePathUrlStrategy() handle it
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
