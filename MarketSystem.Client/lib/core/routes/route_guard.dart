/// Route Guard / Middleware
/// Protects routes requiring authentication
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'app_routes.dart';

/// Public routes that don't require authentication
const List<String> publicRoutes = [
  '/',
  '/welcome',
  '/login',
  '/register',
];

/// Check if route is public
bool isPublicRoute(String? routeName) {
  if (routeName == null) return false;
  return publicRoutes.contains(routeName) || routeName == AppRoutes.splash;
}

/// Auth middleware - protects authenticated routes
/// Returns true if navigation should continue, false if blocked
Future<bool> authGuard(BuildContext context, String? routeName) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  // If route is public, allow navigation
  if (isPublicRoute(routeName)) {
    return true;
  }

  // Check if user is authenticated
  if (!authProvider.isAuthenticated) {
    // Not authenticated - redirect to login
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
    return false;
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
