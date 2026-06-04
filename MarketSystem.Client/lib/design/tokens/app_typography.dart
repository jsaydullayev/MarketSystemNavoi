// Typography scale: Inter-based text styles matching the HTML demo.
//
// PERF: Inter is now BUNDLED (assets/fonts/Inter-Variable.ttf, registered in
// pubspec as family 'Inter') and used via a plain const TextStyle. Previously
// this called GoogleFonts.inter(), which fetches the font from fonts.gstatic.com
// at runtime on first launch — adding a network round-trip (competing with the
// API) and a font-swap flash to EVERY screen (welcome / login / dashboard).
// Bundling removes that network dependency entirely and lets text paint
// instantly in Inter from the first frame.
//
// IMPORTANT: these styles deliberately carry NO `color`. Colour comes from the
// active ThemeData.textTheme (see AppTheme.light / AppTheme.dark), so a plain
// `Text(..., style: AppTextStyles.bodyMedium())` inherits the right colour in
// both light and dark mode. Callers that need a specific colour still
// `.copyWith(color: ...)` on the result.

import 'package:flutter/material.dart';

class AppTextStyles {
  static const String _family = 'Inter';

  static const TextStyle _displayLarge = TextStyle(
    fontFamily: _family,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static TextStyle displayLarge() => _displayLarge;

  static const TextStyle _displayMedium = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static TextStyle displayMedium() => _displayMedium;

  static const TextStyle _titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle titleLarge() => _titleLarge;

  static const TextStyle _titleMedium = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle titleMedium() => _titleMedium;

  static const TextStyle _bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static TextStyle bodyLarge() => _bodyLarge;

  static const TextStyle _bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static TextStyle bodyMedium() => _bodyMedium;

  static const TextStyle _bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static TextStyle bodySmall() => _bodySmall;

  static const TextStyle _labelLarge = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle labelLarge() => _labelLarge;

  static const TextStyle _labelSmall = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
  static TextStyle labelSmall() => _labelSmall;

  static const TextStyle _caption = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  static TextStyle caption() => _caption;
}
