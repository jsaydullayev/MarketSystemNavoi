import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// G2 — single source of truth for the client-side password policy, kept in
/// lockstep with the backend's `StrongPasswordAttribute` (see
/// `MarketSystem.Application/Validation/StrongPasswordAttribute.cs`):
///
///   • length 8–100
///   • at least one letter (Unicode letter category — Cyrillic OK)
///   • at least one digit
///
/// Without this util every screen rolled its own check: `add_user_sheet.dart`
/// allowed 6 chars, `profile_screen.dart` checked only emptiness,
/// `create_owner_dialog.dart` enforced 8 but no letter+digit. After the
/// backend deploy any password the local validator accepts but the server
/// rejects would surface as a raw `Exception: ...` snackbar — confusing for
/// the user and an extra round-trip the field validator could have caught.
///
/// Validators that need a different "required" semantic — e.g. the
/// "current password" field on the change-password sheet must accept the
/// legacy 6-char hash to authenticate the change — should NOT use this
/// helper. Call [validateNew] only for fields where the value will become
/// the user's new password.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;
  static const int maxLength = 100;

  /// Returns null when the value is acceptable, or a localized error
  /// message ready to drop into a [TextFormField.validator] return.
  ///
  /// Use for fields whose value will be SET as the user's password
  /// (Register, CreateUser, change-password "new" field, etc.).
  static String? validateNew(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.passwordRequired ?? 'Parol majburiy';
    }
    if (!_isStrong(value)) {
      return l10n?.passwordMinLength
          ?? "Parol kamida 8 belgi, 1 harf va 1 raqam o'z ichiga olishi kerak";
    }
    return null;
  }

  /// True when the value meets the policy. Exposed so non-validator paths
  /// (e.g. enabling a "Save" button only when the field is valid, or
  /// computing a password-strength meter) can share the same logic.
  static bool isStrong(String value) => _isStrong(value);

  static bool _isStrong(String value) {
    if (value.length < minLength || value.length > maxLength) return false;
    var hasLetter = false;
    var hasDigit = false;
    for (final rune in value.runes) {
      final ch = String.fromCharCode(rune);
      // Use Dart's RegExp letter/digit matchers — they're Unicode-aware
      // when the source flag is set, but to keep it simple we check the
      // ASCII path plus Cyrillic range (the app's two locales).
      if (_isLetter(rune)) {
        hasLetter = true;
      } else if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
        hasDigit = true;
      }
      if (hasLetter && hasDigit) return true;
    }
    return hasLetter && hasDigit;
  }

  static bool _isLetter(int rune) {
    // ASCII A-Z / a-z
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
      return true;
    }
    // Cyrillic letters U+0400 – U+04FF (uz/ru content). Mirrors the
    // server-side `char.IsLetter` which is Unicode-category aware; this
    // covers the actual locales the app ships with.
    if (rune >= 0x0400 && rune <= 0x04FF) return true;
    // Uzbek Latin letters Ş, Ğ, etc. live in Latin Extended-A (0x0100 – 0x017F)
    // and Latin Extended-B (0x0180 – 0x024F). Cover both ranges.
    if (rune >= 0x0100 && rune <= 0x024F) return true;
    return false;
  }
}
