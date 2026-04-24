/// Route Helper Utilities
/// Provides helper functions for route-related operations
library;

import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../constants/public_routes.dart';

/// Public routes that should NOT trigger any auto-navigation
@Deprecated('Use PublicRoutes instead')
const Set<String> publicRoutes = {
  AppRoutes.privacy,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.splash,
};

/// Check if a route is public (no auth required)
@Deprecated('Use PublicRoutes.isPublic() instead')
bool isPublicRoute(String routeName) {
  return publicRoutes.contains(routeName);
}

/// Check if current route should be exempt from auto-navigation
/// This is used by splash screen and other auto-redirect logic
bool shouldSkipAutoRedirect(BuildContext context) {
  final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
  final isPublic = PublicRoutes.isPublic(currentRoute);

  debugPrint('🔍 Route Helper - Current route: $currentRoute');
  debugPrint('🔍 Route Helper - Is public: $isPublic');
  debugPrint('🔍 Route Helper - Should skip redirect: $isPublic');

  return isPublic;
}

/// Get the current route name from navigator state
String? getCurrentRouteName(NavigatorState navigator) {
  final route = navigator.widget.pages.last.name;
  return route;
}
