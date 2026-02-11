/// Storage Handler
/// Centralized local storage operations
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage Handler - Manages local storage operations
class StorageHandler {
  SharedPreferences? _prefs;

  /// Initialize storage handler
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    await init();
    return await _prefs!.setString(key, value);
  }

  /// Get string value
  Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  /// Save integer value
  Future<bool> saveInt(String key, int value) async {
    await init();
    return await _prefs!.setInt(key, value);
  }

  /// Get integer value
  Future<int?> getInt(String key) async {
    await init();
    return _prefs!.getInt(key);
  }

  /// Save double value
  Future<bool> saveDouble(String key, double value) async {
    await init();
    return await _prefs!.setDouble(key, value);
  }

  /// Get double value
  Future<double?> getDouble(String key) async {
    await init();
    return _prefs!.getDouble(key);
  }

  /// Save boolean value
  Future<bool> saveBool(String key, bool value) async {
    await init();
    return await _prefs!.setBool(key, value);
  }

  /// Get boolean value
  Future<bool?> getBool(String key) async {
    await init();
    return _prefs!.getBool(key);
  }

  /// Save JSON object (as string)
  Future<bool> saveJson(String key, Map<String, dynamic> value) async {
    await init();
    return await _prefs!.setString(key, jsonEncode(value));
  }

  /// Get JSON object (from string)
  Future<Map<String, dynamic>?> getJson(String key) async {
    await init();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save string list
  Future<bool> saveStringList(String key, List<String> value) async {
    await init();
    return await _prefs!.setStringList(key, value);
  }

  /// Get string list
  Future<List<String>?> getStringList(String key) async {
    await init();
    return _prefs!.getStringList(key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    await init();
    return _prefs!.containsKey(key);
  }

  /// Remove specific key
  Future<bool> remove(String key) async {
    await init();
    return await _prefs!.remove(key);
  }

  /// Clear all storage
  Future<bool> clear() async {
    await init();
    return await _prefs!.clear();
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    await init();
    return _prefs!.getKeys().toList();
  }

  /// Reload preferences
  Future<void> reload() async {
    await init();
    await _prefs!.reload();
  }
}
