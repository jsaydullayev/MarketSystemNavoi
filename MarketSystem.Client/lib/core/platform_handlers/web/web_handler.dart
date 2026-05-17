import 'package:flutter/foundation.dart';

/// Web Handler implementation
class WebHandler {
  WebHandler();

  static Future<String> getDocumentsPath() async {
    // Web doesn't have file system access in the same way
    return '/web/storage';
  }

  static Future<bool> requestPermissions() async {
    // Web doesn't need native permissions
    return true;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // Web notification implementation
    // In a real implementation, use web_notification package
    debugPrint('Web Notification: $title - $body');
  }
}
