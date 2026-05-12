/// Build-time configuration baked into the binary via `--dart-define`.
///
/// These values are NOT meant to be secrets — anything compiled into a Flutter
/// app can be extracted from an APK or browser bundle. We use this file purely
/// for *deployment* knobs: backend URLs, the SuperAdmin console URL segment,
/// feature toggles. The real access control lives on the backend (JWT role
/// check + hidden URL segment gate).
class AppConfig {
  /// Opaque URL segment used by the hidden SuperAdmin console.
  ///
  /// The backend's [Route("api/_sa/{consoleSegment}")] middleware compares the
  /// path segment against the server's `SuperAdmin:ConsoleSegment` config
  /// (constant-time). Build the Flutter app with the SAME value the operator
  /// configured on the server, otherwise every SuperAdmin call 404s:
  ///
  ///   flutter build web --dart-define=SUPERADMIN_CONSOLE_SEGMENT=<value>
  ///
  /// Empty string means "console is unreachable from this build" — the screen
  /// still renders so a misconfigured deployment fails loudly instead of
  /// silently 404ing every request.
  static const String superAdminConsoleSegment = String.fromEnvironment(
    'SUPERADMIN_CONSOLE_SEGMENT',
    defaultValue: '',
  );

  /// True when the build was given a non-empty SuperAdmin segment — used by
  /// the console screen to gate API calls and show a friendly "console not
  /// configured" banner instead of repeatedly hitting 404s.
  static bool get hasSuperAdminConsole =>
      superAdminConsoleSegment.isNotEmpty;
}
