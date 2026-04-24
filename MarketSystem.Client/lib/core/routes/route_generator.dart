/// Route Generator
/// Generates routes for navigation
library;

import 'package:flutter/material.dart';
import 'package:market_system_client/features/cash_register/screens/cash_register_screen.dart';
import 'package:market_system_client/features/splash/splash_screen.dart';

import 'app_routes.dart';
import '../constants/public_routes.dart';
import '../managers/route_state_manager.dart';

// Screens
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/zakup/presentation/screens/zakup_screen.dart';
import '../../features/admin_products/screens/admin_products_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/privacy/screens/privacy_screen.dart';

/// Public routes that should NOT trigger any auto-navigation or auth redirects
/// These routes are accessible without authentication and should never redirect
@Deprecated('Use PublicRoutes.isPublic() instead')
const Set<String> publicRoutesExemptFromRedirect = {
  AppRoutes.privacy,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
};

/// Check if a route should be exempt from any auto-redirect logic
@Deprecated('Use PublicRoutes.isPublic() instead')
bool isRouteExemptFromRedirect(String routeName) {
  return publicRoutesExemptFromRedirect.contains(routeName);
}

/// Generate route
Route<dynamic> generateRoute(RouteSettings settings) {
  final routeName = settings.name ?? '';

  debugPrint('🛣️ generateRoute called: $routeName');

  // CRITICAL: Capture and initialize route state IMMEDIATELY
  // This must happen before any other logic to prevent race conditions
  RouteStateManager.instance.updateRoute(routeName);

  // CRITICAL: Check if route is public FIRST
  // This is the "Impenetrable Wall" - public routes bypass ALL other logic
  // NOTE: /splash is handled here but it's a special case - it DOES redirect
  if (PublicRoutes.isPublic(routeName) || PublicRoutes.isSplash(routeName)) {
    final isSplash = PublicRoutes.isSplash(routeName);
    debugPrint('🔒 Public route detected: $routeName${isSplash ? " (will redirect after auth check)" : " (no redirect)"}');

    switch (routeName) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      default:
        // Should not happen if route is in PublicRoutes, but handle gracefully
        break;
    }
  }

  // Handle protected routes
  switch (routeName) {
    case AppRoutes.dashboard:
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

    case AppRoutes.products:
      return MaterialPageRoute(builder: (_) => const ProductsScreen());

    case AppRoutes.sales:
      return MaterialPageRoute(builder: (_) => const SalesScreen());

    case AppRoutes.customers:
      return MaterialPageRoute(builder: (_) => const CustomersScreen());

    case AppRoutes.zakup:
      return MaterialPageRoute(builder: (_) => const ZakupScreen());

    case AppRoutes.adminProducts:
      return MaterialPageRoute(builder: (_) => const AdminProductsScreen());

    case AppRoutes.users:
      return MaterialPageRoute(builder: (_) => const UsersScreen());

    case AppRoutes.profile:
      return MaterialPageRoute(builder: (_) => const ProfileScreen());

    case AppRoutes.reports:
      return MaterialPageRoute(builder: (_) => const ReportsScreen());

    case AppRoutes.debts:
      return MaterialPageRoute(builder: (_) => const DebtsScreen());

    case AppRoutes.cashRegister:
      return MaterialPageRoute(builder: (_) => const CashRegisterScreen());

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route not found: ${settings.name}'),
          ),
        ),
      );
  }
}
