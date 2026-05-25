import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, debugPrint;
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

  // Silence the ~180 debugPrint() lines scattered through the client when
  // running in release mode. Flutter's debugPrint is NOT a no-op in release
  // by default — it still calls print(), so without this swap every release
  // build would ship verbose token / payment / network logs to the device
  // console. We rebind the global hook to a sink so the existing call sites
  // can stay unchanged.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  usePathUrlStrategy(); // Use clean URLs (/sales) instead of hash URLs (#/sales)
  await setupDependencyInjection();

  // Capture initial route BEFORE any widget rendering so public routes are
  // protected from auth redirects throughout the entire session.
  final currentUrlPath = getCurrentUrlPath() ?? '/';
  RouteStateManager.instance.captureInitialRoute(currentUrlPath);

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MainApp(savedThemeMode: savedThemeMode));
}
