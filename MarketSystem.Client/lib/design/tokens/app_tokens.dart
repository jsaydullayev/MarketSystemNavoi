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
  static const Color accentViolet = Color(
    0xFF8B5CF6,
  ); // violet-500 (avg stats card)
  static const Color avatarSky = Color(0xFF0EA5E9); // sky-500 (avatar palette)
  static const Color avatarPink = Color(
    0xFFEC4899,
  ); // pink-500 (avatar palette)
  static const Color avatarOrange = Color(
    0xFFF97316,
  ); // orange-500 (avatar palette)
  static const Color indigo = Color(0xFF6366F1); // indigo-500 (sale "closed")

  // Decorative accent tones (profile row icons, decorative tiles).
  static const Color accentBlue = Color(0xFF2563EB); // blue-600
  static const Color accentBlueTint = Color(0xFFEFF6FF); // blue-50
  static const Color accentPinkStrong = Color(0xFFDB2777); // pink-600
  static const Color accentPinkTint = Color(0xFFFCE7F3); // pink-100
  static const Color accentPurpleTint = Color(0xFFF3E8FF); // purple-100

  // Golden amber (Material `Colors.amber`) — theme-toggle sun icon.
  static const Color amber = Color(0xFFFFC107);

  // Role badge palette (staff list + user sheets) — per demo spec.
  //   Admin : purple-100 bg / violet-600 fg
  //   Seller: emerald-50 bg / emerald-700 fg
  static const Color roleAdminBg = accentPurpleTint; // purple-100
  static const Color roleAdminFg = accentPurple; // violet-600 (#7C3AED)
  static const Color roleSellerBg = Color(0xFFECFDF5); // emerald-50
  static const Color roleSellerFg = successDeep; // emerald-700 (#047857)

  // Report hero banner gradient (always-dark by design, both themes).
  static const Color heroGradientTop = Color(0xFF0F172A); // slate-900
  static const Color heroGradientBottom = Color(0xFF1E293B); // slate-800

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
  // Minimalist "deep navy + sky blue" family — recognisable to long-time
  // users of the legacy design (which used #1E3A8A blue) but tuned for the
  // new design's flat, low-contrast aesthetic. All backgrounds carry a
  // subtle blue tint instead of pure slate, so the accent sky-blue feels
  // like part of the surface rather than sitting on top of grey.
  //
  // Hierarchy (darkest → lightest):
  //   darkBg            : page background (under everything)
  //   darkSurface       : card / appbar surface
  //   darkSurface2      : raised surfaces (KPI cards, modals)
  //   darkInputFill     : input fields, switches
  //
  // Accent:
  //   darkPrimary       : deep navy for buttons, primary actions
  //   darkPrimaryLight  : light sky blue for active states, focus rings,
  //                       chart bars, hyperlinks
  static const Color darkPrimary = Color(0xFF1E3A8A); // navy-800
  static const Color darkPrimaryLight = Color(0xFF60A5FA); // sky-400 — softer
  static const Color darkBg = Color(0xFF0B1426); // deeper navy than slate-900
  static const Color darkSurface = Color(0xFF152238); // navy-tinted surface
  static const Color darkSurface2 = Color(0xFF1F2C44); // raised navy
  static const Color darkBorder = Color(0xFF243763); // subtle blue divider
  static const Color darkBorderSoft = Color(0xFF152238);
  static const Color darkText = Color(0xFFF1F5F9); // slate-100 — high contrast
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // slate-300
  static const Color darkTextMuted = Color(0xFF64748B); // slate-500
  static const Color darkInputFill = Color(
    0xFF2A3A55,
  ); // slightly above darkSurface2 so inputs stand out
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

/// Width breakpoints (logical px) for adaptive layouts. Below [compact],
/// app bars / headers collapse labelled actions to icon-only so they fit
/// narrow phones without clipping.
class AppBreakpoints {
  static const double compact = 380;
}
