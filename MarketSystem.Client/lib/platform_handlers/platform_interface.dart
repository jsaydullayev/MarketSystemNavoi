/// Platform interface for all platform-specific handlers
/// This defines the common contract that all platform handlers must implement
library;

import 'package:flutter/foundation.dart' show TargetPlatform;

/// Abstract base class for platform-specific operations
abstract class PlatformHandler {
  /// Check if current platform matches
  static bool isCurrentPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }
}

/// Platform interface for storage operations
abstract class StorageHandlerInterface {
  Future<void> save(String key, String value);
  Future<String?> get(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
}

/// Platform interface for permission handling
abstract class PermissionHandlerInterface {
  Future<bool> requestStoragePermission();
  Future<bool> requestCameraPermission();
  Future<bool> requestNotificationPermission();
  Future<bool> checkPermission(String permission);
}

/// Platform interface for file operations
abstract class FileHandlerInterface {
  Future<String> getDocumentsPath();
  Future<String> getTemporaryPath();
  Future<bool> pickFile();
  Future<String?> readFile(String path);
  Future<bool> writeFile(String path, String content);
}

/// Platform interface for notification handling
abstract class NotificationHandlerInterface {
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  });
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}
