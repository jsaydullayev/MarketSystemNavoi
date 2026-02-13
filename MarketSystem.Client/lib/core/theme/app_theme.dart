import 'package:flutter/material.dart';

/// Market System uchun birlashtirilgan dizayn tizimi
class AppTheme {
  // --- Asosiy ranglar (Clean light theme) ---
  static const Color primary = Color(0xFF2563EB);      // Blue
  static const Color primaryDark = Color(0xFF1D4ED8);  // Dark Blue
  static const Color secondary = Color(0xFF10B981);    // Emerald Green
  static const Color accent = Color(0xFFF59E0B);       // Amber
  static const Color danger = Color(0xFFEF4444);       // Red
  static const Color success = Color(0xFF10B981);      // Green
  static const Color background = Color(0xFFFFFFFF);   // White
  static const Color surface = Color(0xFFF8FAFC);      // Very light gray
  static const Color textPrimary = Color(0xFF1E293B);  // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium slate

  // --- Text styles ---
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: textSecondary,
  );

  // --- Card decoration styles ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFFE2E8F0),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF64748B).withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration menuCardDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: color.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.1),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // --- Input decoration ---
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: textSecondary,
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: textSecondary, size: 20),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: primary,
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
  );

  // --- Button styles ---
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 10,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
    textStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );

  // --- Theme data ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 13),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Menu card uchun ranglar
class MenuCardColors {
  static const Color products = Color(0xFF3B82F6);    // Blue
  static const Color sales = Color(0xFF10B981);       // Green
  static const Color customers = Color(0xFFF59E0B);   // Orange
  static const Color zakup = Color(0xFF8B5CF6);       // Purple
  static const Color reports = Color(0xFFEC4899);     // Pink
  static const Color debts = Color(0xFFEF4444);       // Red
  static const Color users = Color(0xFF14B8A6);       // Teal
  static const Color adminProducts = Color(0xFF6366F1); // Indigo
}
