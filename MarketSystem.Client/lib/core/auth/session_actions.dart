/// Centralised logout + "return to /login" flow.
///
/// Every logout entry point — the dashboard drawer, the profile screen, the
/// SuperAdmin console, and the forced session-end / market-blocked listeners
/// in [MainApp] — funnels through here. Two reasons:
///
///  1. Single source of truth. Previously each screen duplicated the same
///     `authProvider.logout()` + `Navigator.push…RemoveUntil('/login')` block,
///     each with slightly different navigation (`pushNamedAndRemoveUntil` vs a
///     hand-built `MaterialPageRoute(LoginScreen())`).
///
///  2. The "/login opens twice" bug. When a reactive trigger (the
///     session-ended stream) fired at the same moment as a manual logout tap —
///     or the async `logout()` round-trip let a second tap through before the
///     route swapped — TWO `/login` routes were pushed onto the stack. The
///     [redirectToLogin] latch below collapses any burst of redirects within a
///     single frame into exactly ONE navigation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../handlers/navigation_handler.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class SessionActions {
  SessionActions._();

  /// True while a redirect-to-login is already scheduled for the current
  /// frame. Reset on the next post-frame callback so a *later* logout (after
  /// the user logs back in) can redirect again.
  static bool _redirecting = false;

  /// True for the whole duration of an in-flight [logout] — including the
  /// network round-trip. A second tap on a logout button (e.g. the SuperAdmin
  /// console's, which has no confirm dialog) that lands DURING that await would
  /// otherwise fire its own `redirectToLogin` in a later frame, after the
  /// one-frame [_redirecting] latch had already reset — pushing /login twice.
  /// Spanning the whole operation closes that gap.
  static bool _loggingOut = false;

  /// Clear auth state, then return to the login screen — exactly once. A second
  /// call while the first is still in flight is ignored.
  static Future<void> logout(BuildContext context) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await context.read<AuthProvider>().logout();
      redirectToLogin();
    } finally {
      _loggingOut = false;
    }
  }

  /// Navigate to `/login`, clearing the entire back stack. Re-entrant calls
  /// fired within the same frame are ignored, so the login route can never be
  /// pushed twice no matter how many triggers race here at once.
  static void redirectToLogin() {
    if (_redirecting) return;
    _redirecting = true;
    NavigationHandler.navigateToAndClear(AppRoutes.login);
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirecting = false);
  }
}
