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

  /// Navigate to new route
  static Future<T?> navigateTo<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to new route and replace current
  static Future<T?> navigateToReplacement<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, Object?>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to new route and clear all previous routes
  static Future<T?> navigateToAndClear<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  static void goBack<T>([T? result]) {
    if (canGoBack()) {
      navigatorKey.currentState!.pop<T>(result);
    }
  }

  /// Check if can go back
  static bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Pop until specific route
  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Show dialog
  static Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return material.showDialog<T>(
      context: navigatorKey.currentContext!,
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
    return showModalBottomSheet(
      context: navigatorKey.currentContext!,
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
    final scaffoldMessenger = ScaffoldMessenger.of(navigatorKey.currentContext!);
    scaffoldMessenger.showSnackBar(
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
    ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();
  }

  /// Remove current route
  static void removeCurrentRoute() {
    navigatorKey.currentState!.removeRoute(
      ModalRoute.of(navigatorKey.currentContext!)!,
    );
  }
}
