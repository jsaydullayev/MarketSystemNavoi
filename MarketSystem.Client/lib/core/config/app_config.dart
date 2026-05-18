import 'package:flutter/foundation.dart' show kDebugMode;

/// Build-time configuration baked into the binary via `--dart-define`.
///
/// These values are NOT meant to be secrets — anything compiled into a Flutter
/// app can be extracted from an APK or browser bundle. We use this file purely
/// for *deployment* knobs: backend URLs, the SuperAdmin console URL segment,
/// feature toggles. The real access control lives on the backend (JWT role
/// check + hidden URL segment gate).
class AppConfig {
  /// Raw env value supplied at build time:
  ///   flutter build web --dart-define=SUPERADMIN_CONSOLE_SEGMENT=<value>
  static const String _envSegment = String.fromEnvironment(
    'SUPERADMIN_CONSOLE_SEGMENT',
    defaultValue: '',
  );

  /// Dev fallback so `flutter run -d chrome` works without remembering to
  /// pass the dart-define every time. This MUST match the value the local
  /// backend reads from `appsettings.Development.json` under
  /// `SuperAdmin:ConsoleSegment`. Release builds ignore it (kDebugMode==false)
  /// so production deployments are forced to set the env explicitly.
  static const String _devFallbackSegment =
      '0cdecf78d9ebba28ff6c18dd3d5af47b';

  /// Opaque URL segment used by the hidden SuperAdmin console.
  ///
  /// The backend's [Route("api/_sa/{consoleSegment}")] middleware compares the
  /// path segment against the server's `SuperAdmin:ConsoleSegment` config
  /// (constant-time). Build the Flutter app with the SAME value the operator
  /// configured on the server, otherwise every SuperAdmin call 404s.
  ///
  /// Empty string in a release build means "console is unreachable from this
  /// binary" — the screen still renders so a misconfigured deployment fails
  /// loudly instead of silently 404ing every request.
  static String get superAdminConsoleSegment {
    if (_envSegment.isNotEmpty) return _envSegment;
    // Only use the hardcoded segment in debug — production must set the env.
    return kDebugMode ? _devFallbackSegment : '';
  }

  /// True when this build has a non-empty SuperAdmin segment — used by the
  /// console screen to gate API calls and show a friendly "console not
  /// configured" banner instead of repeatedly hitting 404s.
  static bool get hasSuperAdminConsole =>
      superAdminConsoleSegment.isNotEmpty;
}
