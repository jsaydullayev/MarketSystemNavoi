// Theme-resolved colour set.
//
// `AppColors` exposes raw constants for BOTH palettes (light + dark*). A
// `const Color` can't react to the active theme, so screens that referenced
// `AppColors.surface` / `.text` / `.bg` directly were frozen in light mode.
//
// This extension resolves the surface / text / accent family against the
// current `Theme.brightness`. Usage:
//
//   final c = context.colors;
//   Container(color: c.surface, child: Text('hi', style: TextStyle(color: c.text)))
//
// Semantic colours (danger / success / warning / info) are intentionally
// NOT exposed here — they read correctly on both backgrounds, so callers
// keep using `AppColors.danger` etc. directly.

import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppThemeColors {
  const AppThemeColors(this.isDark);

  final bool isDark;

  // ── Surfaces ────────────────────────────────────────────────
  /// Page background (Scaffold).
  Color get bg => isDark ? AppColors.darkBg : AppColors.bg;

  /// Card / sheet / app-bar surface.
  Color get surface => isDark ? AppColors.darkSurface : AppColors.surface;

  /// Raised surface (KPI cards, modals) — also used where the light theme
  /// used the pale brand tint as a chip background.
  Color get surface2 => isDark ? AppColors.darkSurface2 : AppColors.brandLight;

  /// Auxiliary input / secondary-button fill.
  Color get inputFill =>
      isDark ? AppColors.darkInputFill : AppColors.inputFill;

  // ── Borders ─────────────────────────────────────────────────
  Color get border => isDark ? AppColors.darkBorder : AppColors.border;
  Color get borderSoft =>
      isDark ? AppColors.darkBorderSoft : AppColors.borderSoft;

  // ── Text ────────────────────────────────────────────────────
  Color get text => isDark ? AppColors.darkText : AppColors.text;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.textMuted;

  // ── Accent ──────────────────────────────────────────────────
  /// Primary accent — brand orange in light, light "sky" blue in dark.
  Color get brand => isDark ? AppColors.darkPrimaryLight : AppColors.brand;

  /// Deeper accent (pressed states, etc.).
  Color get brandDark => isDark ? AppColors.darkPrimary : AppColors.brandDark;

  /// Pale accent tint used behind icons / chips. In dark mode a pale orange
  /// is wrong, so it resolves to a subtle raised navy instead.
  Color get brandLight =>
      isDark ? AppColors.darkSurface2 : AppColors.brandLight;
}

extension AppThemeColorsX on BuildContext {
  /// Theme-resolved colour set for the current brightness.
  AppThemeColors get colors =>
      AppThemeColors(Theme.of(this).brightness == Brightness.dark);
}
