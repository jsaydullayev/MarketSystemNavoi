/// Storage Handler
/// Centralized local storage operations
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage Handler - Manages local storage operations
class StorageHandler {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Initialize storage handler
  Future<void> init() async {
    await _getPrefs();
  }

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    return prefs.setString(key, value);
  }

  /// Get string value
  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  /// Save integer value
  Future<bool> saveInt(String key, int value) async {
    final prefs = await _getPrefs();
    return prefs.setInt(key, value);
  }

  /// Get integer value
  Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key);
  }

  /// Save double value
  Future<bool> saveDouble(String key, double value) async {
    final prefs = await _getPrefs();
    return prefs.setDouble(key, value);
  }

  /// Get double value
  Future<double?> getDouble(String key) async {
    final prefs = await _getPrefs();
    return prefs.getDouble(key);
  }

  /// Save boolean value
  Future<bool> saveBool(String key, bool value) async {
    final prefs = await _getPrefs();
    return prefs.setBool(key, value);
  }

  /// Get boolean value
  Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key);
  }

  /// Save JSON object (as string)
  Future<bool> saveJson(String key, Map<String, dynamic> value) async {
    final prefs = await _getPrefs();
    return prefs.setString(key, jsonEncode(value));
  }

  /// Get JSON object (from string)
  Future<Map<String, dynamic>?> getJson(String key) async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save string list
  Future<bool> saveStringList(String key, List<String> value) async {
    final prefs = await _getPrefs();
    return prefs.setStringList(key, value);
  }

  /// Get string list
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _getPrefs();
    return prefs.getStringList(key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _getPrefs();
    return prefs.containsKey(key);
  }

  /// Remove specific key
  Future<bool> remove(String key) async {
    final prefs = await _getPrefs();
    return prefs.remove(key);
  }

  /// Clear all storage
  Future<bool> clear() async {
    final prefs = await _getPrefs();
    return prefs.clear();
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    final prefs = await _getPrefs();
    return prefs.getKeys().toList();
  }

  /// Reload preferences
  Future<void> reload() async {
    final prefs = await _getPrefs();
    await prefs.reload();
  }
}
