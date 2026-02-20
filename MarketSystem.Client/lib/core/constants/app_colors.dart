import 'package:flutter/material.dart';

class AppColors {
  static const Color orangePrimary = Color(0xFFF28C33);
  static const Color darkBluePrimary = Color(0xFF1E3A8A);
  static Color getPrimary(BuildContext context) {
    // Context orqali ilova hozir qaysi rejimdaligini aniqlaymiz
    return Theme.of(context).brightness == Brightness.light
        ? orangePrimary
        : darkBluePrimary;
  }
}

class AppThemes {
  // Light Theme (Orange)
  static final light = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.orangePrimary,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.orangePrimary,
      secondary: AppColors.orangePrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangePrimary),
    ),
  );

  // Dark Theme (Deep Blue)
  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkBluePrimary,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Juda to'q ko'k/qora fon
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkBluePrimary,
      secondary: AppColors.darkBluePrimary,
      surface: Color(0xFF1E293B),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(backgroundColor: AppColors.darkBluePrimary),
    ),
  );
}
