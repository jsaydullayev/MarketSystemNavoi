import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app/main_app.dart';
import 'core/utils/di.dart';
import 'core/managers/route_state_manager.dart';
import 'core/constants/public_routes.dart';

/// Gets the current browser URL path (web only)
String? getCurrentUrlPath() {
  try {
    // Try to access window.location via JS interop
    final path = Uri.base.path;
    debugPrint('🔍 [main.dart] Current URL path: $path');
    debugPrint('🔍 [main.dart] Full URI: ${Uri.base}');
    return path;
  } catch (e) {
    debugPrint('⚠️ [main.dart] Failed to get URL path: $e');
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Use clean URLs (/sales) instead of hash URLs (#/sales)
  await setupDependencyInjection();

  // CRITICAL: Capture initial route BEFORE any widget rendering
  // This is the "Impenetrable Wall" foundation - once set, public routes are protected
  final currentUrlPath = getCurrentUrlPath() ?? '/';
  RouteStateManager.instance.captureInitialRoute(currentUrlPath);

  debugPrint('🎯 [main.dart] Initial route captured: $currentUrlPath');
  debugPrint('🎯 [main.dart] Is public route: ${PublicRoutes.isPublic(currentUrlPath)}');

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MainApp(savedThemeMode: savedThemeMode));
}
