import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';

  // Light Theme - Yorqin, yaltiroq oq theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Primary color - yaltiroq gradient ko'k
      primaryColor: const Color(0xFF2563EB),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),

      // App Bar - gradient white
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),

      // Card Theme - yaltiroq white
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button - gradient effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF2563EB),
          elevation: 4,
          shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF8B5CF6),
        surface: Colors.white,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E293B),
      ),
    );
  }

  // Dark Theme - Yaltiroq qora theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Primary color - yaltiroq gradient binafsha
      primaryColor: const Color(0xFF8B5CF6),
      scaffoldBackgroundColor: const Color(0xFF0F172A),

      // App Bar - gradient dark
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card Theme - yaltiroq dark
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 8,
        shadowColor: Color(0xFF8B5CF6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Elevated Button - gradient effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF8B5CF6),
          elevation: 4,
          shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFE2E8F0),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF94A3B8),
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFF2563EB),
        surface: Color(0xFF1E293B),
        error: Color(0xFFF87171),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
    );
  }

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setTheme(!_isDarkMode);
  }
}
