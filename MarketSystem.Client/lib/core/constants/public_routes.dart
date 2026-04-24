/// Public Routes
/// Single source of truth for all routes that don't require authentication
library;

import '../routes/app_routes.dart';

/// Centralized public route definitions
/// Any route added here will bypass all auth checks and auto-redirects
class PublicRoutes {
  /// All public routes (no authentication required)
  /// NOTE: Splash route (/) is NOT in this list - it's a special case that DOES redirect
  static const Set<String> all = {
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.privacy,
  };

  /// Check if a route is public
  /// Returns true if route requires no authentication
  static bool isPublic(String route) {
    final normalized = _normalizeRoute(route);
    return all.contains(normalized);
  }

  /// Check if route is splash screen
  /// Splash screen is special - it should still check auth and redirect
  static bool isSplash(String route) {
    final normalized = _normalizeRoute(route);
    return normalized == _normalizeRoute(AppRoutes.splash);
  }

  /// Check if route should skip auto-navigation (stay on the page)
  /// This is true for routes like /privacy that should NEVER redirect
  /// BUT false for /splash which SHOULD redirect after checking auth
  static bool shouldSkipAutoNavigation(String route) {
    // Splash screen should NOT skip auto-navigation - it needs to check auth
    if (isSplash(route)) {
      return false;
    }
    // Other public routes should stay where they are
    return isPublic(route);
  }

  /// Normalize route string for consistent comparison
  /// Handles trailing slashes, query parameters, hash fragments
  static String _normalizeRoute(String route) {
    // Remove query parameters and hash fragments
    final cleanRoute = route.split('?')[0].split('#')[0];

    // Remove trailing slash unless it's just "/"
    String normalized = cleanRoute;
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Check if route should be exempt from auto-redirect logic
  /// This is the same as isPublic() but with a clearer semantic name
  @Deprecated('Use shouldSkipAutoNavigation() instead')
  static bool shouldExemptFromRedirect(String route) {
    return isPublic(route);
  }

  /// Get all public routes as a list (for logging/debugging)
  static List<String> toList() => all.toList();
}
