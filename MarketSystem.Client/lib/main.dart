import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app/main_app.dart';
import 'core/utils/di.dart';
import 'core/managers/route_state_manager.dart';

/// Gets the current browser URL path (web only)
String? getCurrentUrlPath() {
  try {
    return Uri.base.path;
  } catch (_) {
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Use clean URLs (/sales) instead of hash URLs (#/sales)
  await setupDependencyInjection();

  // Capture initial route BEFORE any widget rendering so public routes are
  // protected from auth redirects throughout the entire session.
  final currentUrlPath = getCurrentUrlPath() ?? '/';
  RouteStateManager.instance.captureInitialRoute(currentUrlPath);

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MainApp(savedThemeMode: savedThemeMode));
}
