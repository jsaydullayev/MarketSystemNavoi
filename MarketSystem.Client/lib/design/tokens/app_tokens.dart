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
  static const Color successDeep = Color(0xFF047857); // hsla emerald-700
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309); // amber-700 (debt hero)
  static const Color warningDeep = Color(0xFF92400E); // amber-800 (alert title)
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerDeep = Color(0xFF991B1B); // red-900 (alert title)
  static const Color dangerStrong = Color(0xFFB91C1C); // red-800 (alert desc)
  static const Color info = Color(0xFF3B82F6); // blue-500
  static const Color infoLight = Color(0xFFDBEAFE); // blue-100
  static const Color infoDeep = Color(0xFF1E40AF); // blue-800
  static const Color accentPurple = Color(0xFF7C3AED); // violet-600
  static const Color accentPurpleDeep = Color(0xFF6D28D9); // violet-700
  static const Color accentPurpleLight = Color(0xFFEDE9FE); // violet-100

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

  // ─── Dark theme palette ──────────────────────────────────────
  // Uses the old design's dark-blue family so users who prefer the
  // previous look still feel at home in dark mode.
  static const Color darkPrimary = Color(0xFF1E3A8A);
  static const Color darkPrimaryLight = Color(0xFF3B82F6);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurface2 = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderSoft = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkInputFill = Color(0xFF334155);
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
