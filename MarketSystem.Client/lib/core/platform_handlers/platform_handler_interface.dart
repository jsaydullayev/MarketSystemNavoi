/// Platform Handler Interface
/// Abstract interface for all platform-specific operations

/// Platform Handler Interface
abstract class PlatformHandlerInterface {
  /// Show notification on this platform
  Future<void> showNotification({
    required String title,
    required String body,
  });

  /// Request necessary permissions for this platform
  Future<bool> requestPermissions();

  /// Get the documents directory path for this platform
  Future<String> getDocumentsPath();
}
