// Design tokens: colors, spacing, and radius constants matching the HTML demo design system.

import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color brand = Color(0xFFFF6B00);
  static const Color brandDark = Color(0xFFE55400);
  static const Color brandLight = Color(0xFFFFF4EB);
  static const Color brandTint = Color(0xFFFFE9D6);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Surface & borders
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSoft = Color(0xFFF1F5F9);

  // Text
  static const Color text = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Page background
  static const Color bg = Color(0xFFF8FAFC);

  // Auxiliary input fill (gray) used by inputs/secondary buttons.
  static const Color inputFill = Color(0xFFF3F4F6);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xl2 = 20;
  static const double xl3 = 24;
  static const double xl4 = 32;
}

class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double xl2 = 18;
  static const double full = 9999;
}
