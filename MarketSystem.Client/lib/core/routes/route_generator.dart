/// Route Generator
/// Generates routes for navigation
library;

import 'package:flutter/material.dart';
import 'package:market_system_client/features/splash/splash_screen.dart';

import 'app_routes.dart';

// Screens
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/zakup/screens/zakup_screen.dart';
import '../../features/admin_products/screens/admin_products_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/debts/screens/debts_screen.dart';
/// Generate route
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashScreen());

    case AppRoutes.welcome:
      return MaterialPageRoute(builder: (_) => const WelcomeScreen());

    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());

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
