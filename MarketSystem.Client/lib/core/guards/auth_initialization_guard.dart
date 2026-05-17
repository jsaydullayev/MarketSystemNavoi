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
      _hasRun = true;
      return null;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final authHandler = AuthHandler();
    await authHandler.init();

    // Check if user is authenticated
    final bool isAuthenticated = await authHandler.isAuthenticated();

    if (!isAuthenticated) {
      if (currentRoute != '/login' && currentRoute != '/welcome') {
        _hasRun = true;
        return '/login';
      }
      _hasRun = true;
      return null;
    }

    // Load user data from storage into provider
    final role = prefs.getString('user_role');
    final fullName = prefs.getString('user_full_name');
    final username = prefs.getString('user_username');

    if (role != null) {
      // Immediate stub so the UI doesn't render a "logged out" state
      // for a frame while we refresh from the API.
      authProvider.setUserFromStorage({
        'role': role,
        'fullName': fullName,
        'username': username,
      });
    }

    // Refresh the full profile from the API. SharedPreferences only stores
    // role/fullName/username — the profile image (and any other fields the
    // user has updated) lives only on the server. Without this fetch, the
    // image disappears on every browser refresh because the local stub
    // never had it.
    // ignore: unawaited_futures
    authProvider.fetchUserProfile();

    // Check first-time user
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {

      _hasRun = true;
      return '/welcome';
    }

    _hasRun = true;
    return null;
  }

  /// Reset the guard state (useful for testing or logout)
  static void reset() {
    _hasRun = false;
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
