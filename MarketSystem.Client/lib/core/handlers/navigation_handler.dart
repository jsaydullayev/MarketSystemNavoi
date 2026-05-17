/// Navigation Handler
/// Centralized navigation management
library;

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';

/// Navigation Handler - Manages app navigation
class NavigationHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  BuildContext? get context => navigatorKey.currentContext;

  static NavigatorState? get _state => navigatorKey.currentState;
  static BuildContext? get _context => navigatorKey.currentContext;

  /// Navigate to new route
  static Future<T?> navigateTo<T>(
    String routeName, {
    Object? arguments,
  }) {
    final state = _state;
    if (state == null) {
      debugPrint('NavigationHandler: state unavailable for navigateTo($routeName)');
      return Future.value(null);
    }
    return state.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to new route and replace current
  static Future<T?> navigateToReplacement<T>(
    String routeName, {
    Object? arguments,
  }) {
    final state = _state;
    if (state == null) {
      debugPrint('NavigationHandler: state unavailable for navigateToReplacement($routeName)');
      return Future.value(null);
    }
    return state.pushReplacementNamed<T, Object?>(routeName, arguments: arguments);
  }

  /// Navigate to new route and clear all previous routes
  static Future<T?> navigateToAndClear<T>(
    String routeName, {
    Object? arguments,
  }) {
    final state = _state;
    if (state == null) {
      debugPrint('NavigationHandler: state unavailable for navigateToAndClear($routeName)');
      return Future.value(null);
    }
    return state.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  static void goBack<T>([T? result]) {
    if (canGoBack()) {
      _state?.pop<T>(result);
    }
  }

  /// Check if can go back
  static bool canGoBack() {
    return _state?.canPop() ?? false;
  }

  /// Pop until specific route
  static void popUntil(String routeName) {
    final state = _state;
    if (state == null) {
      debugPrint('NavigationHandler: state unavailable for popUntil($routeName)');
      return;
    }
    state.popUntil(ModalRoute.withName(routeName));
  }

  /// Show dialog
  static Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    final ctx = _context;
    if (ctx == null) {
      debugPrint('NavigationHandler: context unavailable for showDialog');
      return Future.value(null);
    }
    return material.showDialog<T>(
      context: ctx,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
    );
  }

  /// Show bottom sheet
  static Future<T?> showBottomSheet<T>({
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
  }) {
    final ctx = _context;
    if (ctx == null) {
      debugPrint('NavigationHandler: context unavailable for showBottomSheet');
      return Future.value(null);
    }
    return showModalBottomSheet(
      context: ctx,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
    );
  }

  /// Show snackbar
  static void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    final ctx = _context;
    if (ctx == null) {
      debugPrint('NavigationHandler: context unavailable for showSnackBar');
      return;
    }
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Hide current snackbar
  static void hideSnackBar() {
    final ctx = _context;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
  }

  /// Remove current route
  static void removeCurrentRoute() {
    final ctx = _context;
    final state = _state;
    if (ctx == null || state == null) {
      debugPrint('NavigationHandler: unavailable for removeCurrentRoute');
      return;
    }
    final route = ModalRoute.of(ctx);
    if (route != null) state.removeRoute(route);
  }
}
