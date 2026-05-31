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
  // Web: flutter_secure_storage 9.x uses IndexedDB (persistent across
  // refreshes) — no special WebOptions needed.
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _migrated = false;

  /// Flutter Web's flutter_secure_storage encrypts via the Web Crypto API
  /// (`window.crypto.subtle`), which the browser ONLY exposes in a *secure
  /// context* — HTTPS or http://localhost. Served over plain HTTP on a bare
  /// IP (e.g. http://158.220.123.53 before the domain's TLS is wired up),
  /// crypto.subtle is undefined and every secure-storage call throws. That
  /// previously bubbled up through saveTokens() into AuthService.login()'s
  /// catch block and surfaced as the misleading "Tarmoq xatosi" — even
  /// though the login API itself returned 200.
  ///
  /// When that happens we flip this flag and fall back to plain
  /// SharedPreferences so the app stays usable. Tokens are then NOT encrypted
  /// at rest — an explicit, logged trade-off for HTTP/IP deployments that
  /// self-corrects the moment the app is served over HTTPS or localhost.
  bool _secureUnavailable = false;

  // ── Fallback-aware primitives ────────────────────────────────────
  // Each tries secure storage first; on the first failure it latches
  // _secureUnavailable and routes to SharedPreferences from then on.

  Future<void> _write(String key, String value) async {
    if (!_secureUnavailable) {
      try {
        await _secure.write(key: key, value: value);
        return;
      } catch (e) {
        debugPrint(
          'TokenStorage: secure write failed ($e) — '
          'falling back to SharedPreferences.',
        );
        _secureUnavailable = true;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> _read(String key) async {
    if (!_secureUnavailable) {
      try {
        final v = await _secure.read(key: key);
        if (v != null) return v;
      } catch (e) {
        debugPrint(
          'TokenStorage: secure read failed ($e) — '
          'falling back to SharedPreferences.',
        );
        _secureUnavailable = true;
      }
    }
    // Secure store was empty OR unavailable — check the fallback location too,
    // so a token written during a non-secure session is still found.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _delete(String key) async {
    if (!_secureUnavailable) {
      try {
        await _secure.delete(key: key);
      } catch (e) {
        _secureUnavailable = true;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

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
    await _write(_accessKey, accessToken);
    await _write(_refreshKey, refreshToken);
  }

  Future<String?> readAccess() async {
    await _migrateIfNeeded();
    return _read(_accessKey);
  }

  Future<String?> readRefresh() async {
    await _migrateIfNeeded();
    return _read(_refreshKey);
  }

  Future<void> clear() async {
    await _migrateIfNeeded();
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  // ── "Remember me" credentials ────────────────────────────────────
  // Saved in the SAME platform-secure store as the tokens, so the remembered
  // password is encrypted at rest (EncryptedSharedPreferences / Keychain) with
  // the same plain-SharedPreferences fallback on HTTP-web. Kept SEPARATE from
  // the session tokens: [clear] (logout) wipes the session but leaves these, so
  // the login form can still prefill on the next visit.
  static const _rememberUserKey = 'remember_username';
  static const _rememberPassKey = 'remember_password';

  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _write(_rememberUserKey, username);
    await _write(_rememberPassKey, password);
  }

  /// The remembered (username, password), or null if either was never saved.
  Future<({String username, String password})?> readCredentials() async {
    final u = await _read(_rememberUserKey);
    final p = await _read(_rememberPassKey);
    if (u == null || u.isEmpty || p == null || p.isEmpty) return null;
    return (username: u, password: p);
  }

  Future<void> clearCredentials() async {
    await _delete(_rememberUserKey);
    await _delete(_rememberPassKey);
  }
}
