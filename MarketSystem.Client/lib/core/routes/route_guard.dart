/// Route Guard / Middleware
/// Protects routes requiring authentication
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../constants/public_routes.dart';
import '../guards/public_route_guard.dart';
import 'app_routes.dart';

/// Public routes that don't require authentication
@Deprecated('Use PublicRoutes.isPublic() instead')
const List<String> publicRoutes = [
  '/',
  '/welcome',
  '/login',
  '/register',
  '/privacy',
];

/// Check if route is public
@Deprecated('Use PublicRoutes.isPublic() instead')
bool isPublicRoute(String? routeName) {
  if (routeName == null) return false;
  return publicRoutes.contains(routeName) || routeName == AppRoutes.splash;
}

/// Auth middleware - protects authenticated routes
/// Returns true if navigation should continue, false if blocked
Future<bool> authGuard(BuildContext context, String? routeName) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  // CRITICAL: Use PublicRoutes for consistent public route checking
  // If route is public, allow navigation without any auth check
  if (PublicRoutes.isPublic(routeName ?? '')) {
    debugPrint('🔓 RouteGuard: Public route, bypassing auth check: $routeName');
    return true;
  }

  // Check if user is authenticated
  if (!authProvider.isAuthenticated) {
    // Not authenticated - redirect to login
    // Only redirect if we're not already being redirected from a public route
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    if (PublicRouteGuard.allowRedirect(currentRoute, '/login')) {
      if (context.mounted) {
        debugPrint('🔒 RouteGuard: Redirecting to login (not authenticated)');
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return false;
    } else {
      debugPrint('🚫 RouteGuard: Blocked redirect to login (from public route)');
      return false;
    }
  }

  return true;
}

/// Role-based access control
/// Checks if user has required role to access route
bool hasRequiredRole(
  Map<String, dynamic>? user,
  List<String> allowedRoles,
) {
  if (user == null) return false;
  final role = user['role'] as String?;
  return allowedRoles.contains(role);
}

/// Protected routes with required roles
const Map<String, List<String>> protectedRoutes = {
  '/users': ['Admin', 'Owner'],
  '/admin-products': ['Admin', 'Owner'],
  '/zakup': ['Admin', 'Owner'],
  '/cash-register': ['Admin', 'Owner'],
  '/reports': ['Admin', 'Owner'],
  '/debts': ['Admin', 'Owner'],
};

/// Check if route requires specific role
List<String>? getRequiredRoles(String? routeName) {
  if (routeName == null) return null;
  for (final entry in protectedRoutes.entries) {
    if (routeName.startsWith(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
