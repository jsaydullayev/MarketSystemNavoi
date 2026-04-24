/// Auth Initialization Guard
/// Handles authentication state separately from UI rendering
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/public_routes.dart';
import '../providers/auth_provider.dart';
import '../handlers/auth_handler.dart';
import '../../data/services/auth_service.dart';

/// Auth Initialization Guard
/// Separates authentication logic from UI rendering
/// This prevents race conditions where auth checks interfere with public routes
class AuthInitializationGuard {
  AuthInitializationGuard._();

  /// Has the guard already run?
  static bool _hasRun = false;

  /// Check if initialization has already been performed
  static bool get hasRun => _hasRun;

  /// Initialize authentication state
  /// This should be called once at app startup, but ONLY if needed
  ///
  /// Returns:
  /// - null if route is public (no auth check needed)
  /// - Widget to redirect to if user is not authenticated
  /// - null if user is authenticated (stay on current route)
  static Future<String?> initializeAuth(
    BuildContext context,
    String currentRoute,
    AuthService authService,
  ) async {
    // CRITICAL: Skip auth check entirely for public routes
    if (PublicRoutes.isPublic(currentRoute)) {
      debugPrint('🔓 AuthInitializationGuard: Skipping auth check for public route: $currentRoute');
      _hasRun = true;
      return null;
    }

    debugPrint('🔒 AuthInitializationGuard: Checking auth for: $currentRoute');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final authHandler = AuthHandler();
    await authHandler.init();

    // Check if user is authenticated
    final bool isAuthenticated = await authHandler.isAuthenticated();

    if (!isAuthenticated) {
      debugPrint('❌ User not authenticated, redirecting to login');

      // Only redirect if not already on login or welcome
      if (currentRoute != '/login' && currentRoute != '/welcome') {
        _hasRun = true;
        return '/login';
      }
      _hasRun = true;
      return null;
    }

    debugPrint('✅ User authenticated, loading user data');

    // Load user data from storage into provider
    final role = prefs.getString('user_role');
    final fullName = prefs.getString('user_full_name');
    final username = prefs.getString('user_username');

    if (role != null) {
      authProvider.setUserFromStorage({
        'role': role,
        'fullName': fullName,
        'username': username,
      });
    }

    // Check first-time user
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      debugPrint('👶 First-time user, redirecting to welcome');
      _hasRun = true;
      return '/welcome';
    }

    _hasRun = true;
    debugPrint('✅ Auth initialization complete, user can access: $currentRoute');
    return null;
  }

  /// Reset the guard state (useful for testing or logout)
  static void reset() {
    _hasRun = false;
    debugPrint('🔄 AuthInitializationGuard reset');
  }

  /// Check if a protected route requires authentication
  /// Returns true if the route needs auth but user is not authenticated
  static Future<bool> requiresAuthRedirect(
    BuildContext context,
    String route,
  ) async {
    // Public routes don't require auth
    if (PublicRoutes.isPublic(route)) {
      return false;
    }

    final authHandler = AuthHandler();
    await authHandler.init();
    final isAuthenticated = await authHandler.isAuthenticated();

    return !isAuthenticated;
  }
}
