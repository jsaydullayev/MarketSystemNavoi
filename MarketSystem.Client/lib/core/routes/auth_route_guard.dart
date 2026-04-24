/// Auth Route Guard Widget
/// Wraps protected routes and handles authentication
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/route_helper.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../l10n/app_localizations.dart';

/// Widget that guards a child widget with authentication
/// Redirects to login if user is not authenticated
class AuthRouteGuard extends StatelessWidget {
  final Widget child;

  const AuthRouteGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if current route is public - if so, allow without auth check
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (isPublicRoute(currentRoute)) {
      debugPrint('🔓 AuthRouteGuard: Skipping auth check for public route: $currentRoute');
      return child;
    }

    if (!authProvider.isAuthenticated) {
      // Show login screen if not authenticated
      return const LoginScreen();
    }

    return child;
  }
}

/// Role-based route guard
/// Shows access denied page if user doesn't have required role
class RoleRouteGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleRouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userRole = user?['role'] as String?;

    // Check if current route is public - if so, skip role check
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (isPublicRoute(currentRoute)) {
      debugPrint('🔓 RoleRouteGuard: Skipping role check for public route: $currentRoute');
      return child;
    }

    if (!allowedRoles.contains(userRole)) {
      // User doesn't have required role - show access denied page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.accessDenied ?? 'Access denied'),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate back to dashboard instead of just popping
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      // Show loading screen while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}

/// Combined auth + role guard
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<String>? allowedRoles;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = AuthRouteGuard(child: child);

    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      widget = RoleRouteGuard(
        allowedRoles: allowedRoles!,
        child: widget,
      );
    }

    return widget;
  }
}
