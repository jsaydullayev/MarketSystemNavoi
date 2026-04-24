/// Route State Manager
/// Single source of truth for the initial route and public route state
library;

import 'package:flutter/material.dart';
import '../constants/public_routes.dart';

/// Manages the state of routes throughout the app lifecycle
/// Critical for preventing unwanted redirects on public routes
class RouteStateManager {
  static RouteStateManager? _instance;
  static RouteStateManager get instance => _instance ??= RouteStateManager._();

  RouteStateManager._() {
    debugPrint('📋 RouteStateManager initialized');
  }

  /// The initial route captured when the app starts
  String? _initialRoute;

  /// Whether the initial/current route is public (no auth required)
  bool _isPublicRoute = false;

  /// Tracks if route has been initialized
  bool _isInitialized = false;

  /// Stream of route changes for reactive UI
  final ValueNotifier<String?> _currentRoute = ValueNotifier<String?>(null);

  /// Get the current route value
  String? get currentRoute => _currentRoute.value;

  /// Get the initial route
  String? get initialRoute => _initialRoute;

  /// Whether the current route is public
  bool get isPublicRoute => _isPublicRoute;

  /// Whether route state has been initialized
  bool get isInitialized => _isInitialized;

  /// Stream of route changes
  ValueNotifier<String?> get routeStream => _currentRoute;

  /// Capture the initial route at app startup
  /// This should be called as early as possible, ideally in main()
  void captureInitialRoute(String route) {
    if (!_isInitialized) {
      _initialRoute = route;
      _isPublicRoute = PublicRoutes.isPublic(route);
      _currentRoute.value = route;
      _isInitialized = true;

      debugPrint('📋 Route State Initialized:');
      debugPrint('   Initial Route: $route');
      debugPrint('   Is Public: $_isPublicRoute');
      debugPrint('   Auth Check: ${_isPublicRoute ? "SKIPPED" : "REQUIRED"}');
    } else {
      debugPrint('⚠️ RouteStateManager: Attempted to re-initialize (ignored)');
    }
  }

  /// Update the current route (call when navigating)
  void updateRoute(String route) {
    _currentRoute.value = route;
    _isPublicRoute = PublicRoutes.isPublic(route);
    debugPrint('📋 Route updated: $route (public: $_isPublicRoute)');
  }

  /// Reset the manager (useful for testing or hot reload)
  void reset() {
    _initialRoute = null;
    _isPublicRoute = false;
    _isInitialized = false;
    _currentRoute.value = null;
    _instance = null;
    debugPrint('📋 RouteStateManager reset');
  }

  /// Check if redirect is allowed from current route
  /// Returns false if current route is public (impenetrable wall)
  bool canRedirect(String fromRoute) {
    final result = PublicRoutes.isPublic(fromRoute);
    if (result) {
      debugPrint('🛑 REDIRECT BLOCKED: Attempted redirect from public route: $fromRoute');
    }
    return !result;
  }

  /// Check if redirect is allowed from current route (using context)
  bool canRedirectFromContext(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    return canRedirect(currentRoute);
  }
}
