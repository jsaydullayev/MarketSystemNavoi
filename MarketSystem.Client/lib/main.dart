import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app/main_app.dart';
import 'core/utils/di.dart';

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

  // Debug: Print current URL
  getCurrentUrlPath();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MainApp(savedThemeMode: savedThemeMode));
}
