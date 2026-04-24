/// Redirect Interceptor
/// Wraps all navigation calls with public route protection
library;

import 'package:flutter/material.dart';
import '../guards/public_route_guard.dart';
import '../managers/route_state_manager.dart';

/// Redirect Interceptor
/// Wraps all navigation operations to ensure public routes are protected
class RedirectInterceptor {
  // Private constructor - this is a static utility class
  RedirectInterceptor._();

  /// Check if redirect is allowed before performing navigation
  /// Returns true if navigation should proceed, false if blocked
  static bool canRedirect(BuildContext context, String toRoute) {
    final fromRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Check with RouteStateManager first
    final stateManagerAllowed = RouteStateManager.instance.canRedirect(fromRoute);
    if (!stateManagerAllowed) {
      debugPrint('🛑 RedirectInterceptor: Blocked by RouteStateManager');
      return false;
    }

    // Check with PublicRouteGuard
    final guardAllowed = PublicRouteGuard.allowRedirect(fromRoute, toRoute);
    return guardAllowed;
  }

  /// Perform a push operation with automatic redirect protection
  /// Returns the result of the navigation, or null if blocked
  static Future<T?> push<T extends Object>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (!canRedirect(context, routeName)) {
      debugPrint('🚫 Push blocked: $routeName');
      return null;
    }

    debugPrint('✅ Push proceeding: $routeName');
    RouteStateManager.instance.updateRoute(routeName);
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Perform a pushReplacement operation with automatic redirect protection
  /// Returns the result of the navigation, or null if blocked
  static Future<T?> pushReplacement<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    if (!canRedirect(context, routeName)) {
      debugPrint('🚫 PushReplacement blocked: $routeName');
      return null;
    }

    debugPrint('✅ PushReplacement proceeding: $routeName');
    RouteStateManager.instance.updateRoute(routeName);
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Perform a pushAndRemoveUntil operation with automatic redirect protection
  /// Returns the result of the navigation, or null if blocked
  static Future<T?> pushAndRemoveUntil<T extends Object>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    required RoutePredicate predicate,
  }) async {
    if (!canRedirect(context, routeName)) {
      debugPrint('🚫 PushAndRemoveUntil blocked: $routeName');
      return null;
    }

    debugPrint('✅ PushAndRemoveUntil proceeding: $routeName');
    RouteStateManager.instance.updateRoute(routeName);
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Force a navigation operation (bypasses public route protection)
  /// Use with caution - only when you absolutely need to redirect from a public route
  static Future<T?> forcePush<T extends Object>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    debugPrint('⚠️ FORCE Push (bypassing guards): $routeName');
    RouteStateManager.instance.updateRoute(routeName);
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Force a replacement operation (bypasses public route protection)
  /// Use with caution - only when you absolutely need to redirect from a public route
  static Future<T?> forcePushReplacement<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    debugPrint('⚠️ FORCE PushReplacement (bypassing guards): $routeName');
    RouteStateManager.instance.updateRoute(routeName);
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Show a debug message about why a redirect was blocked
  static void showBlockMessage(BuildContext context, String toRoute) {
    final fromRoute = ModalRoute.of(context)?.settings.name ?? '';
    final reason = PublicRouteGuard.getBlockReason(fromRoute, toRoute);
    debugPrint('🚫 Navigation blocked: $reason');

    // Optionally show to user (uncomment if desired)
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text(reason)),
    // );
  }
}
