/// Web URL handler
library;

import 'dart:html' as html;

/// Web URL Handler
/// Handles all Web-specific URL operations
class WebUrlHandler {
  /// Get current URL path
  static String getCurrentPath() {
    return html.window.location.pathname ?? '';
  }

  /// Get current URL origin (protocol + host + port)
  static String getCurrentOrigin() {
    return html.window.location.origin;
  }

  /// Update URL without reloading (for SPA routing)
  static void updateUrl(String path) {
    html.window.history.pushState(null, '', path);
  }

  /// Replace URL without creating history entry
  static void replaceUrl(String path) {
    html.window.history.replaceState(null, '', path);
  }

  /// Go back in history
  static void goBack() {
    html.window.history.back();
  }

  /// Go forward in history
  static void goForward() {
    html.window.history.forward();
  }

  /// Get hash fragment from URL
  static String getHash() {
    return html.window.location.hash;
  }

  /// Set hash fragment in URL
  static void setHash(String hash) {
    html.window.location.hash = hash;
  }

  /// Listen to URL changes (popstate event)
  static void onUrlChange(void Function() callback) {
    html.window.onPopState.listen((_) => callback());
  }

  /// Check if running in HTTPS
  static bool get isSecure =>
      html.window.location.protocol == 'https:';

  /// Get hostname
  static String getHostname() {
    return html.window.location.hostname ?? '';
  }

  /// Get port number
  static int getPort() {
    final portStr = html.window.location.port;
    return portStr.isEmpty ? 80 : int.parse(portStr);
  }
}
