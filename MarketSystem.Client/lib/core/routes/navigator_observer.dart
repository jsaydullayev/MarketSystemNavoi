/// Navigator Observer for Route Protection
/// Prevents unwanted redirects on public routes like /privacy
library;

import 'package:flutter/material.dart';
import '../utils/route_helper.dart';

/// A navigator observer that prevents redirects on public routes
class RouteProtectionObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('PUSH', route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('POP', route.settings.name, previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteChange('REPLACE', newRoute?.settings.name, oldRoute?.settings.name);

    // CRITICAL: Detect and warn about unwanted redirects on public routes
    if (oldRoute != null && newRoute != null) {
      final oldRouteName = oldRoute.settings.name ?? '';
      final newRouteName = newRoute.settings.name ?? '';

      if (isPublicRoute(oldRouteName) && !isPublicRoute(newRouteName)) {
        debugPrint('⚠️ WARNING: Possible unwanted redirect from public route!');
        debugPrint('  From: $oldRouteName (public)');
        debugPrint('  To: $newRouteName (protected)');
        debugPrint('  This redirect should not happen automatically.');
      }
    }
  }

  void _logRouteChange(String action, String? newRoute, String? oldRoute) {
    debugPrint('🔄 NavigatorObserver: $action - $oldRoute → $newRoute');
  }
}
