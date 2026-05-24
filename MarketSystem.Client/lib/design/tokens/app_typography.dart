// Typography scale: GoogleFonts.inter()-based text styles matching the HTML demo.
//
// IMPORTANT: these styles deliberately carry NO `color`. Colour comes from
// the active ThemeData.textTheme (see AppTheme.light / AppTheme.dark), so a
// plain `Text(..., style: AppTextStyles.bodyMedium())` inherits the right
// colour in both light and dark mode. Previously every style baked in the
// light-theme near-black `AppColors.text`, which made all text invisible on
// the dark background. Callers that need a specific colour (white on a
// coloured hero card, brand accent, etc.) still `.copyWith(color: ...)`.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle displayLarge() =>
      GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2);

  static TextStyle displayMedium() =>
      GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2);

  static TextStyle titleLarge() =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle titleMedium() =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle bodyLarge() =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle bodyMedium() =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodySmall() =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle labelLarge() =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle labelSmall() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static TextStyle caption() => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}
