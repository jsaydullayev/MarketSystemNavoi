/// Route Generator
/// Generates routes for navigation
library;

import 'package:flutter/material.dart';
import 'package:market_system_client/features/cash_register/screens/cash_register_screen.dart';
import 'package:market_system_client/features/splash/splash_screen.dart';

import 'app_routes.dart';
import '../auth/permissions.dart';
import '../constants/public_routes.dart';
import '../managers/route_state_manager.dart';
import '../widgets/permission_gate.dart';

// Screens
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/zakup/presentation/screens/zakup_screen.dart';
import '../../features/admin_products/screens/admin_products_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/privacy/screens/privacy_screen.dart';
import '../../features/security_journal/screens/security_journal_screen.dart';
import '../../features/superadmin/presentation/superadmin_console_screen.dart';

/// Generate route
Route<dynamic> generateRoute(RouteSettings settings) {
  final routeName = settings.name ?? '';

  debugPrint('🛣️ generateRoute called: $routeName');

  // CRITICAL: Capture and initialize route state IMMEDIATELY
  // This must happen before any other logic to prevent race conditions
  RouteStateManager.instance.updateRoute(routeName);

  // CRITICAL: Check if route is public FIRST
  // This is the "Impenetrable Wall" - public routes bypass ALL other logic
  // /privacy route must return here without ANY further processing
  if (PublicRoutes.isPublic(routeName) || PublicRoutes.isSplash(routeName)) {
    debugPrint(
      '🔒 Public route detected: $routeName - RETURNING IMMEDIATELY (no auth check, no redirect)',
    );

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
        // CRITICAL: /privacy MUST return here with NO further processing
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      default:
        // Should not happen if route is in PublicRoutes, but handle gracefully
        break;
    }
  }

  // Handle protected routes below
  debugPrint('🔐 Protected route detected: $routeName - checking auth');

  switch (routeName) {
    case AppRoutes.superAdminConsole:
      // SuperAdmin-only screen. The Authorize guard in the post-login routing
      // (login_screen.dart) is the gate that decides who reaches this route —
      // we intentionally don't redirect non-SuperAdmin users from here, since
      // the route is supposed to be unreachable from the UI.
      return MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen());
    case AppRoutes.dashboard:
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

    case AppRoutes.products:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.productsAccess,
          child: ProductsScreen(),
        ),
      );

    case AppRoutes.sales:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.salesAccess,
          child: SalesScreen(),
        ),
      );

    case AppRoutes.customers:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.customersAccess,
          child: CustomersScreen(),
        ),
      );

    case AppRoutes.zakup:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.zakupAccess,
          child: ZakupScreen(),
        ),
      );

    case AppRoutes.adminProducts:
      return MaterialPageRoute(builder: (_) => const AdminProductsScreen());

    case AppRoutes.users:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.usersAccess,
          child: UsersScreen(),
        ),
      );

    case AppRoutes.profile:
      return MaterialPageRoute(builder: (_) => const ProfileScreen());

    case AppRoutes.reports:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.reportsAccess,
          child: ReportsScreen(),
        ),
      );

    case AppRoutes.debts:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.debtsAccess,
          child: DebtsScreen(),
        ),
      );

    case AppRoutes.cashRegister:
      return MaterialPageRoute(
        builder: (_) => const PermissionGate(
          permission: Permissions.cashRegisterAccess,
          child: CashRegisterScreen(),
        ),
      );

    case AppRoutes.notifications:
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());

    case AppRoutes.securityJournal:
      return MaterialPageRoute(builder: (_) => const SecurityJournalScreen());

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Route not found: ${settings.name}')),
        ),
      );
  }
}
