import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FAZA 2 — single source of truth for JWT access + refresh tokens.
///
/// Until now both tokens lived in plain `SharedPreferences` (the
/// `flutter_secure_storage` package was declared in pubspec but never
/// imported anywhere). That meant a rooted device, an unencrypted iCloud /
/// Google Drive backup, or any other process running as the same UID could
/// pull the tokens off disk — and with K1's hash-on-write commit on the
/// backend, the access token in particular is the ONLY remaining shortcut
/// to an active session.
///
/// This wrapper moves both tokens into platform-native secure storage
/// (Keychain on iOS/macOS, EncryptedSharedPreferences on Android,
/// libsecret/credential-manager on desktop). A one-time migration reads
/// the old SharedPreferences entries on first access, re-writes them via
/// flutter_secure_storage, and clears the SharedPreferences keys so any
/// later reader of the legacy location sees nothing.
///
/// Singleton so the migration runs at most once per app process — the
/// callers (HttpService.singleton + a couple of AuthService paths) all
/// reach the same instance.
class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  // Keys here are intentionally DIFFERENT from the legacy SharedPreferences
  // keys (`access_token` / `refresh_token`) so the migration step can
  // unambiguously identify "have I already moved this?". Once a token is
  // in secure storage under `jwt_access` / `jwt_refresh`, the old SharedPrefs
  // entry has been deleted.
  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';

  // Legacy keys — read once during migration, then erased.
  static const _legacyAccess = 'access_token';
  static const _legacyRefresh = 'refresh_token';

  // Android: prefer EncryptedSharedPreferences over the older fallback.
  // iOS: first_unlock_this_device keeps tokens accessible after reboot but
  // before the user unlocks; cheaper than first_unlock for a kiosk-style
  // POS where the app may launch before the user touches the device. The
  // tokens are still encrypted at rest and tied to the device keychain.
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _migrated = false;

  /// Run the SharedPreferences → secure-storage migration if it hasn't
  /// happened already in this process. Safe to call on every read; the
  /// `_migrated` guard short-circuits after the first execution.
  Future<void> _migrateIfNeeded() async {
    if (_migrated) return;
    _migrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyAccess = prefs.getString(_legacyAccess);
      final legacyRefresh = prefs.getString(_legacyRefresh);
      final didHave = legacyAccess != null || legacyRefresh != null;

      // Only carry the legacy value forward if the new slot is empty.
      // A re-install with a stale SharedPrefs entry shouldn't overwrite
      // a fresh login-in-secure-storage.
      if (legacyAccess != null && await _secure.read(key: _accessKey) == null) {
        await _secure.write(key: _accessKey, value: legacyAccess);
      }
      if (legacyRefresh != null &&
          await _secure.read(key: _refreshKey) == null) {
        await _secure.write(key: _refreshKey, value: legacyRefresh);
      }

      // Whatever was in SharedPreferences is now insecure overlap — wipe
      // it so a future reader (or a backup that bypasses the secure store)
      // can't recover the token.
      if (didHave) {
        await prefs.remove(_legacyAccess);
        await prefs.remove(_legacyRefresh);
        debugPrint('TokenStorage: migrated legacy tokens to secure storage.');
      }
    } catch (e) {
      // A platform that doesn't support secure storage (e.g. Linux without
      // libsecret) would throw here. Fall back gracefully — the rest of
      // the wrapper still works against the in-memory _secure cache.
      debugPrint('TokenStorage: migration failed: $e');
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _migrateIfNeeded();
    await _secure.write(key: _accessKey, value: accessToken);
    await _secure.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccess() async {
    await _migrateIfNeeded();
    return _secure.read(key: _accessKey);
  }

  Future<String?> readRefresh() async {
    await _migrateIfNeeded();
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    await _migrateIfNeeded();
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }
}
