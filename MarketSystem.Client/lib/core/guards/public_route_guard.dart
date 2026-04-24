/// Public Route Guard
/// The "Impenetrable Wall" - prevents any redirects from public routes
library;

import 'package:flutter/material.dart';
import '../constants/public_routes.dart';

/// Public Route Guard
/// Enforces the rule: public routes can NEVER be redirected from
/// This is critical for pages like /privacy that must always be accessible
class PublicRouteGuard {
  // Private constructor - this is a static utility class
  PublicRouteGuard._();

  /// Check if a route should bypass all auth checks
  /// Returns true if the route is public (no auth required)
  static bool shouldBypassAuth(String route) {
    final isPublic = PublicRoutes.isPublic(route);
    if (isPublic) {
      debugPrint('🔓 PublicRouteGuard: Bypassing auth check for: $route');
    }
    return isPublic;
  }

  /// Check if redirect is allowed
  /// Returns true if redirect is permitted, false if blocked
  ///
  /// CRITICAL: This is the "Impenetrable Wall"
  /// Once on a public route, NO automatic redirect can force the user away
  static bool allowRedirect(String fromRoute, String toRoute) {
    // Never redirect FROM a public route
    if (PublicRoutes.isPublic(fromRoute)) {
      debugPrint('🚫 BLOCKED: Attempted redirect from public route');
      debugPrint('   From: $fromRoute (public)');
      debugPrint('   To: $toRoute');
      debugPrint('   This redirect has been BLOCKED to protect public route access');
      return false;
    }

    // Redirect is allowed
    debugPrint('✅ ALLOWED: Redirect from $fromRoute → $toRoute');
    return true;
  }

  /// Check if redirect is allowed using BuildContext
  /// Convenience method that extracts the current route from context
  static bool allowRedirectFromContext(BuildContext context, String toRoute) {
    final fromRoute = ModalRoute.of(context)?.settings.name ?? '';
    return allowRedirect(fromRoute, toRoute);
  }

  /// Validate that a navigation operation should proceed
  /// Returns true if navigation is allowed, false if blocked
  static bool canNavigate(BuildContext context, String toRoute) {
    final fromRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Special case: if navigating TO a public route, always allow
    // This ensures privacy policy, login, etc. are always accessible
    if (PublicRoutes.isPublic(toRoute)) {
      debugPrint('🔓 Navigation allowed to public route: $toRoute');
      return true;
    }

    // For protected routes, check if redirect is allowed
    return allowRedirect(fromRoute, toRoute);
  }

  /// Assert that the current route is public (for use in screen initialization)
  /// Throws an AssertionError if the route is not public
  /// Useful for ensuring public screens stay public
  static void assertPublicRoute(String route, String screenName) {
    final isPublic = PublicRoutes.isPublic(route);
    if (!isPublic) {
      final message = '🚨 SECURITY WARNING: $screenName accessed via non-public route: $route';
      debugPrint(message);
      // In debug mode, throw an error to catch this during development
      assert(isPublic, message);
    } else {
      debugPrint('✅ Public route confirmed for $screenName: $route');
    }
  }

  /// Get the reason for a blocked redirect (for user feedback)
  static String getBlockReason(String fromRoute, String toRoute) {
    if (PublicRoutes.isPublic(fromRoute)) {
      return 'Cannot redirect from public route: $fromRoute';
    }
    return 'Unknown block reason';
  }
}
