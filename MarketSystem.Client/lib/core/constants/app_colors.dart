import 'package:flutter/material.dart';

class AppColors {
  static const Color orangePrimary = Color(0xFFF28C33);
  static const Color darkBluePrimary = Color(0xFF1E3A8A);
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? orangePrimary
        : const Color.fromARGB(255, 24, 67, 184);
  }

  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkBorder = Colors.white10;

  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFEEEEEE);

  static const Color primary = Color.fromARGB(255, 40, 77, 180);
  static const Color accent = Colors.orange;
  static const Color success = Colors.green;
  static const Color error = Colors.red;

  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color getCard(bool isDark) => isDark ? darkCard : lightCard;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
}

class AppThemes {
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

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkBluePrimary,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
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
