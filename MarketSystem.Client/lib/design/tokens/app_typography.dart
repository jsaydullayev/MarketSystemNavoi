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

// PERF: each accessor used to call GoogleFonts.inter(...) on EVERY invocation
// — and these are called many times per widget build, on every scroll frame
// of paginated lists. GoogleFonts.inter builds a TextStyle, runs two internal
// copyWith calls, and schedules loadFontIfNecessary each time. The styles are
// static (no runtime input), so each is computed ONCE into a `static final`
// (lazily, on first read) and the accessor just returns the cached instance.
// Call sites are unchanged — callers still write `AppTextStyles.bodyMedium()`
// and `.copyWith(...)` on the result as before.
class AppTextStyles {
  static final TextStyle _displayLarge = GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static TextStyle displayLarge() => _displayLarge;

  static final TextStyle _displayMedium = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static TextStyle displayMedium() => _displayMedium;

  static final TextStyle _titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle titleLarge() => _titleLarge;

  static final TextStyle _titleMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle titleMedium() => _titleMedium;

  static final TextStyle _bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static TextStyle bodyLarge() => _bodyLarge;

  static final TextStyle _bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static TextStyle bodyMedium() => _bodyMedium;

  static final TextStyle _bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static TextStyle bodySmall() => _bodySmall;

  static final TextStyle _labelLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle labelLarge() => _labelLarge;

  static final TextStyle _labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
  static TextStyle labelSmall() => _labelSmall;

  static final TextStyle _caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  static TextStyle caption() => _caption;
}
