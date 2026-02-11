/// Web storage handler (using IndexedDB and LocalStorage)
library;

import 'dart:html' as html;

import '../platform_interface.dart';

/// Web Storage Handler
/// Handles all Web-specific storage operations
class WebStorageHandler extends StorageHandlerInterface {
  @override
  Future<void> clear() async {
    html.window.localStorage.clear();
    // TODO: Also clear IndexedDB if needed
  }

  @override
  Future<bool> containsKey(String key) async {
    return html.window.localStorage.containsKey(key);
  }

  @override
  Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<String?> get(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> save(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  /// Get all keys from local storage
  Future<List<String>> getAllKeys() async {
    return html.window.localStorage.keys.toList();
  }

  /// Get multiple values at once
  Future<Map<String, String>> getMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Save multiple values at once
  Future<void> saveMultiple(Map<String, String> data) async {
    for (final entry in data.entries) {
      await save(entry.key, entry.value);
    }
  }

  /// Get storage size estimate (in bytes)
  int getStorageSize() {
    int total = 0;
    for (final key in html.window.localStorage.keys) {
      total += (key.length + (html.window.localStorage[key]?.length ?? 0));
    }
    return total;
  }

  /// Check if storage is available
  Future<bool> isStorageAvailable() async {
    try {
      final testKey = '__storage_test__';
      await save(testKey, 'test');
      await delete(testKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Session storage (clears when tab closes)
  Future<void> saveToSession(String key, String value) async {
    html.window.sessionStorage[key] = value;
  }

  Future<String?> getFromSession(String key) async {
    return html.window.sessionStorage[key];
  }

  Future<void> deleteFromSession(String key) async {
    html.window.sessionStorage.remove(key);
  }

  Future<void> clearSession() async {
    html.window.sessionStorage.clear();
  }

  /// IndexedDB operations for larger data storage
  /// TODO: Implement IndexedDB for storing large data like images
  /// Use indexed_db package or js interop

  /// Store file in IndexedDB
  Future<bool> storeFile(String key, List<int> bytes) async {
    // TODO: Implement IndexedDB file storage
    return true;
  }

  /// Retrieve file from IndexedDB
  Future<List<int>?> getFile(String key) async {
    // TODO: Implement IndexedDB file retrieval
    return null;
  }
}
