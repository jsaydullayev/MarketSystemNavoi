/// Web-specific platform handler
library;

import 'dart:html' as html;
import 'dart:js' as js;

import '../platform_interface.dart';

/// Web Handler for Web-specific operations
class WebHandler extends PlatformHandler {
  /// Check if current platform is Web
  static bool get isWeb => identical(0, 0.0);

  /// Get browser information
  static String getBrowserInfo() {
    return html.window.navigator.userAgent;
  }

  /// Get current URL
  static String getCurrentURL() {
    return html.window.location.href;
  }

  /// Open URL in new tab
  static void openURL(String url) {
    html.window.open(url, '_blank');
  }

  /// Reload page
  static void reload() {
    html.window.location.reload();
  }

  /// Get query parameters from URL
  static Map<String, String> getQueryParameters() {
    final params = <String, String>{};
    final queryString = html.window.location.search;
    if (queryString != null && queryString.isNotEmpty) {
      final pairs = queryString.substring(1).split('&');
      for (final pair in pairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          params[keyValue[0]] = keyValue[1];
        }
      }
    }
    return params;
  }

  /// Copy text to clipboard (Web implementation)
  static Future<void> copyToClipboard(String text) async {
    // TODO: Implement using clipboard package or JS interop
    // await html.window.navigator.clipboard.writeText(text);
  }

  /// Download file (Web implementation)
  static void downloadFile({
    required String fileName,
    required String data,
    String mimeType = 'text/plain',
  }) {
    final blob = html.Blob([data], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Show alert dialog
  static void showAlert(String message) {
    html.window.alert(message);
  }

  /// Show confirmation dialog
  static bool? showConfirm(String message) {
    return html.window.confirm(message);
  }

  /// Get from local storage
  static String? getFromLocalStorage(String key) {
    return html.window.localStorage[key];
  }

  /// Save to local storage
  static void saveToLocalStorage(String key, String value) {
    html.window.localStorage[key] = value;
  }

  /// Remove from local storage
  static void removeFromLocalStorage(String key) {
    html.window.localStorage.remove(key);
  }

  /// Clear all local storage
  static void clearLocalStorage() {
    html.window.localStorage.clear();
  }

  /// Check if service worker is supported
  static bool get isServiceWorkerSupported => true; // Simplified check

  /// Register service worker
  static Future<void> registerServiceWorker(String scriptUrl) async {
    // TODO: Implement service worker registration
  }
}
