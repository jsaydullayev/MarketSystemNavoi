/// Build-time configuration baked into the binary via `--dart-define`.
///
/// These values are NOT meant to be secrets — anything compiled into a Flutter
/// app can be extracted from an APK or browser bundle. We use this file purely
/// for *deployment* knobs: backend URLs, the SuperAdmin console URL segment,
/// feature toggles. The real access control lives on the backend (JWT role
/// check + hidden URL segment gate).
class AppConfig {
  /// Raw env value supplied at build time, e.g.
  ///   flutter build appbundle --dart-define=SUPERADMIN_CONSOLE_SEGMENT=<value>
  /// When set, it overrides [_defaultSegment] (use it only if a deployment
  /// runs a different `SuperAdmin:ConsoleSegment` than the default below).
  static const String _envSegment = String.fromEnvironment(
    'SUPERADMIN_CONSOLE_SEGMENT',
    defaultValue: '',
  );

  /// Default console segment, used whenever no `--dart-define` override is
  /// supplied — so EVERY build (IDE, plain `flutter build`, CI) reaches the
  /// console without remembering a flag. Safe to ship: this is not a secret
  /// (any compiled binary leaks it) and the real gate is the backend's JWT
  /// SuperAdmin check. MUST equal the production server's
  /// `SuperAdmin:ConsoleSegment` (verified live: correct → 401, wrong → 404).
  static const String _defaultSegment = '0cdecf78d9ebba28ff6c18dd3d5af47b';

  /// Opaque URL segment used by the hidden SuperAdmin console.
  ///
  /// The backend's [Route("api/_sa/{consoleSegment}")] middleware compares the
  /// path segment against the server's `SuperAdmin:ConsoleSegment` config
  /// (constant-time); a mismatch 404s every SuperAdmin call. Returns the
  /// dart-define override if present, otherwise the baked default.
  static String get superAdminConsoleSegment =>
      _envSegment.isNotEmpty ? _envSegment : _defaultSegment;

  /// True when this build has a non-empty SuperAdmin segment — used by the
  /// console screen to gate API calls and show a friendly "console not
  /// configured" banner instead of repeatedly hitting 404s.
  static bool get hasSuperAdminConsole => superAdminConsoleSegment.isNotEmpty;
}
