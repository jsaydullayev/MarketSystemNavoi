/// Platform Handler
/// Unified interface for all platform-specific operations

import 'dart:io' as io;

import 'package:market_system_client/core/platform_handlers/android/android_handler.dart';
import 'package:market_system_client/core/platform_handlers/ios/ios_handler.dart';
import 'package:market_system_client/core/platform_handlers/web/web_handler.dart';
import 'package:market_system_client/core/platform_handlers/windows/windows_handler.dart';

/// Platform enum
enum AppPlatform {
  android,
  ios,
  windows,
  web,
}

/// Platform Handler - Unified interface
class PlatformHandler {

  /// Get current platform
  static AppPlatform get currentPlatform {
    if (io.Platform.isAndroid) return AppPlatform.android;
    if (io.Platform.isIOS) return AppPlatform.ios;
    if (io.Platform.isWindows) return AppPlatform.windows;
    return AppPlatform.web;
  }

  /// Check if running on Android
  static bool get isAndroid => io.Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => io.Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => io.Platform.isWindows;

  /// Check if running on Web
  static bool get isWeb =>
      io.Platform.isAndroid || io.Platform.isIOS || io.Platform.isWindows
          ? false
          : true;

  /// Show notification (platform-specific)
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (isAndroid) {
      return AndroidHandler.showNotification(title: title, body: body);
    } else if (isIOS) {
      return IOSHandler.showNotification(title: title, body: body);
    } else if (isWeb) {
      return WebHandler.showNotification(title: title, body: body);
    } else if (isWindows) {
      return WindowsHandler.showNotification(title: title, body: body);
    }
  }

  /// Request permissions (platform-specific)
  static Future<bool> requestPermissions() async {
    if (isAndroid) {
      return AndroidHandler.requestPermissions();
    } else if (isIOS) {
      return IOSHandler.requestPermissions();
    } else if (isWeb) {
      // Web doesn't need permissions
      return true;
    } else if (isWindows) {
      return WindowsHandler.requestPermissions();
    }
    return true;
  }

  /// Get documents path (platform-specific)
  static Future<String> getDocumentsPath() async {
    if (isAndroid) {
      return AndroidHandler.getDocumentsPath();
    } else if (isIOS) {
      return IOSHandler.getDocumentsPath();
    } else if (isWeb) {
      return WebHandler.getDocumentsPath();
    } else if (isWindows) {
      return WindowsHandler.getDocumentsPath();
    }
    return '/';
  }
}
