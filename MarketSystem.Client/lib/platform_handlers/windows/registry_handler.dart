/// Windows Registry Handler
library;

/// Windows Registry Handler
/// Handles Windows Registry operations
/// NOTE: This requires platform channels or a package like win32_registry
class WindowsRegistryHandler {
  /// Registry root keys
  static const int HKEY_CURRENT_USER = 0x80000001;
  static const int HKEY_LOCAL_MACHINE = 0x80000002;

  /// Read string value from registry
  static Future<String?> readString({
    required int hKey,
    required String subKey,
    required String valueName,
  }) async {
    // TODO: Implement using win32_registry package or platform channels
    // final key = Registry.openPath(hKey, path: subKey);
    // final value = key.getValueAsString(valueName);
    // key.close();
    // return value;
    return null;
  }

  /// Write string value to registry
  static Future<bool> writeString({
    required int hKey,
    required String subKey,
    required String valueName,
    required String value,
  }) async {
    // TODO: Implement using win32_registry package or platform channels
    // final key = Registry.openPath(hKey, path: subKey);
    // key.createValue(valueName, RegistryValueType.string);
    // key.writeValue(valueName, value);
    // key.close();
    // return true;
    return false;
  }

  /// Delete value from registry
  static Future<bool> deleteValue({
    required int hKey,
    required String subKey,
    required String valueName,
  }) async {
    // TODO: Implement using win32_registry package or platform channels
    return false;
  }

  /// Check if key exists
  static Future<bool> keyExists({
    required int hKey,
    required String subKey,
  }) async {
    // TODO: Implement using win32_registry package or platform channels
    return false;
  }

  /// Add app to Windows startup (run at login)
  static Future<bool> addToStartup({
    required String appName,
    required String appPath,
  }) async {
    const startupKey =
        r'Software\Microsoft\Windows\CurrentVersion\Run';
    return await writeString(
      hKey: HKEY_CURRENT_USER,
      subKey: startupKey,
      valueName: appName,
      value: appPath,
    );
  }

  /// Remove app from Windows startup
  static Future<bool> removeFromStartup({
    required String appName,
  }) async {
    const startupKey =
        r'Software\Microsoft\Windows\CurrentVersion\Run';
    return await deleteValue(
      hKey: HKEY_CURRENT_USER,
      subKey: startupKey,
      valueName: appName,
    );
  }

  /// Check if app is in startup
  static Future<bool> isInStartup({
    required String appName,
  }) async {
    const startupKey =
        r'Software\Microsoft\Windows\CurrentVersion\Run';
    final value = await readString(
      hKey: HKEY_CURRENT_USER,
      subKey: startupKey,
      valueName: appName,
    );
    return value != null;
  }
}
