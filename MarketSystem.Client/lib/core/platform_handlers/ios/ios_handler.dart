import 'package:flutter/foundation.dart';

/// iOS Handler implementation
class IOSHandler {
  IOSHandler();

  static Future<String> getDocumentsPath() async {
    return '/var/mobile/Containers/Data/Application/Library/Documents';
  }

  static Future<bool> requestPermissions() async {
    return true;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('iOS Notification: $title - $body');
  }
}
