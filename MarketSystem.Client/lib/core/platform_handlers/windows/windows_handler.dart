import 'dart:io' as io;
import 'package:flutter/foundation.dart';

/// Windows Handler implementation
class WindowsHandler {
  WindowsHandler();

  static Future<String> getDocumentsPath() async {
    final home = io.Platform.environment['USERPROFILE'] ?? '';
    return '$home\\Documents\\Strotech';
  }

  static Future<bool> requestPermissions() async {
    return true;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('Windows Notification: $title - $body');
  }
}
