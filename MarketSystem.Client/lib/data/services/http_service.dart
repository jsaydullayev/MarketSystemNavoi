import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'auth_service.dart';

/// Carries the reason a market was administratively blocked. Surfaced through
/// [HttpService.marketBlockedStream] so the app shell can show a dedicated
/// "contact admin" screen on top of whichever route the user was on.
class MarketBlockedInfo {
  MarketBlockedInfo({required this.message, this.reason, this.blockedAt});

  final String message;
  final String? reason;
  final DateTime? blockedAt;
}

/// Reasons the local session was terminated. Surfaced through
/// [HttpService.sessionEndedStream] so the app shell can show the right
/// recovery UX (snackbar + redirect to login) instead of dumping the user on
/// an empty screen full of failed requests.
enum SessionEndedReason {
  /// The refresh token was DEFINITIVELY refused (401 / 403 — see
  /// [RefreshOutcome.rejected]). Could mean the token was rotated by the
  /// backend's reuse detector (S1 — a stolen copy was used somewhere), that it
  /// expired, or that the row was invalidated server-side. Either way the user
  /// has to log in again.
  ///
  /// Explicitly NOT emitted for transient failures (offline, timeout, 5xx,
  /// 409 REFRESH_RACE): those keep the tokens and the session, and surface as
  /// a plain network error on the request that triggered the refresh.
  refreshFailed,

  /// Explicit user-initiated logout. Provided so listeners can route to
  /// /login without distinguishing the cause.
  loggedOut,
}

/// Emitted when local auth state must be discarded. See [SessionEndedReason].
class SessionEndedInfo {
  SessionEndedInfo({required this.reason});

  final SessionEndedReason reason;
}

class HttpService {
  String? _accessToken;
  AuthService? _authService;

  /// Single-flight token refresh. When the access token expires and a burst
  /// of requests fire in parallel (e.g. the dashboard's ~12 concurrent
  /// loads), every one of them gets a 401 at nearly the same instant. They
  /// must all funnel through ONE refresh and then retry — never race.
  ///
  /// The previous implementation used a `bool _isRefreshing` flag: the first
  /// 401 set it and refreshed, but every other concurrent 401 saw the flag
  /// already true, skipped the refresh block entirely, and returned its raw
  /// 401. That's why a parallel dashboard load rendered all-zeros after a
  /// token expiry — only one request was ever retried.
  ///
  /// Holds the in-flight refresh Future; concurrent 401s await the same one.
  /// Cleared when the refresh settles so a later expiry can refresh again.
  Future<RefreshOutcome>? _refreshInFlight;

  /// Oxirgi MUVAFFAQIYATSIZ (transient) refresh vaqti — cooldown uchun.
  /// Muvaffaqiyatli refresh buni null qiladi.
  DateTime? _lastRefreshFailureAt;

  /// Transient xatodan keyin yangi refresh urinishi boshlanmaydigan muddat.
  static const Duration _refreshCooldown = Duration(seconds: 5);

  /// Latched true the instant a refresh is DEFINITIVELY rejected (401 / 403 —
  /// see [RefreshOutcome.rejected]) — the session is dead. A transient failure
  /// (offline, 502 mid-deploy, timeout) must NOT latch this: the refresh token
  /// is still valid and the next request simply retries the refresh.
  ///
  /// Without the latch, every request that 401s in a LATER wave (a dashboard
  /// full of pollers keeps firing after the token dies) started its own doomed
  /// refresh and emitted ANOTHER sessionEnded event — so the logout/redirect
  /// ran 4-5 times in a row. While latched, 401s short-circuit: no refresh, no
  /// duplicate event (also spares the network the doomed refresh calls). Reset
  /// in [saveTokens] when a fresh login/refresh revives the session.
  bool _sessionEnded = false;

  // Broadcast so multiple listeners (auth provider, app shell, login screen)
  // can react. Late events do not need to be replayed — a fresh login attempt
  // will surface the 423 again.
  static final StreamController<MarketBlockedInfo> _marketBlockedController =
      StreamController<MarketBlockedInfo>.broadcast();
  static Stream<MarketBlockedInfo> get marketBlockedStream =>
      _marketBlockedController.stream;

  /// G1 — broadcast when the local session ends. Fires from the 401-refresh
  /// path when the refresh attempt itself fails (either the backend rotated
  /// the token under us — see S1 / reuse detection — or the K1 deploy
  /// invalidated every plaintext refresh-token row in the database, which
  /// will happen ONCE per user the moment the backend ships).
  ///
  /// The app shell listens to this and routes to /login with a localized
  /// "session ended" snackbar instead of leaving the user on whatever
  /// dashboard / report they were viewing while every parallel request
  /// silently 401s.
  static final StreamController<SessionEndedInfo> _sessionEndedController =
      StreamController<SessionEndedInfo>.broadcast();
  static Stream<SessionEndedInfo> get sessionEndedStream =>
      _sessionEndedController.stream;

  /// Emitted after a successful token refresh with the new AuthResponse data.
  /// AuthProvider subscribes to update _user['permissions'] so permission
  /// changes granted by the Owner take effect at the next refresh cycle
  /// (≤30 min) without requiring a full re-login.
  static final StreamController<Map<String, dynamic>>
  _tokenRefreshedController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get tokenRefreshedStream =>
      _tokenRefreshedController.stream;

  String get baseUrl => ApiConstants.baseUrl;

  // ── Singleton ───────────────────────────────────────────────
  // HttpService MUST be a singleton. The DI wiring calls
  // `setAuthService()` exactly once (di.dart) so the 401 / refresh path
  // has an AuthService to call. But the data services
  // (ReportService, CustomerService, DebtService, …) each did
  // `_httpService = httpService ?? HttpService()` — creating their OWN
  // fresh instance whose `_authService` was null. Those instances could
  // never refresh a token: the dashboard's requests would 401 and fail,
  // while NotificationService (which used the wired instance) succeeded.
  // That's the "data only appears on the 2nd refresh" bug — the wired
  // instance refreshed the token as a side effect, so the next load
  // found a valid token already in storage.
  //
  // A factory-singleton means every `HttpService()` call — no matter
  // which service makes it — returns the one wired instance, with a
  // shared `_authService` and a shared single-flight `_refreshInFlight`.
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  /// Single keep-alive HTTP client reused for every request so sequential /
  /// repeated calls (dashboard load + refresh, navigation between screens)
  /// reuse the warm TCP connection instead of paying a fresh handshake per
  /// call. The package-level `http.get/post/…` helpers create and tear down a
  /// client EACH call — no connection reuse. This singleton lives for the
  /// whole app, so the client is intentionally never closed.
  final http.Client _client = http.Client();

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  // Tokenlarni saqlash
  //
  // FAZA 2 — both tokens now live in platform-secure storage (Keychain /
  // EncryptedSharedPreferences) via TokenStorage. The previous version
  // wrote them in plain SharedPreferences AND logged the first 20 chars
  // of each — a rooted device or a stray logcat dump on dev hardware
  // surfaced enough of the token to be a real risk. The "saved YES/NO"
  // confirmation read was theatre (the write above had just completed
  // synchronously); it's removed along with the token-prefix logs.
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await TokenStorage.instance.save(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _accessToken = accessToken;
    // A live session again (login or successful refresh) — re-arm the refresh
    // path and the one-shot sessionEnded event.
    _sessionEnded = false;
  }

  Future<String?> getAccessToken() async {
    _accessToken = await TokenStorage.instance.readAccess();
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    return TokenStorage.instance.readRefresh();
  }

  // Tokenlarni tozalash
  Future<void> clearTokens() async {
    await TokenStorage.instance.clear();
    _accessToken = null;
  }

  // Memoised decoded `exp` for the current access token. A dashboard load
  // fires ~10 requests in parallel and each used to base64+JSON-decode the
  // same JWT just to read its expiry. Keying the cache on the token string
  // means the decode runs once per token and every other request is a cheap
  // string compare; rotating the token (refresh / login) is a natural cache
  // miss, so there's nothing to invalidate.
  String? _expCacheToken;
  DateTime? _expCacheExpiry;

  /// Decoded `exp` (UTC) for [token], or null when the token can't be read.
  /// Result is memoised for the current token string.
  DateTime? _accessTokenExpiry(String token) {
    if (token == _expCacheToken) return _expCacheExpiry;
    DateTime? expiry;
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        final exp = payload is Map ? payload['exp'] : null;
        if (exp is int) {
          expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
        }
      }
    } catch (_) {
      expiry = null;
    }
    _expCacheToken = token;
    _expCacheExpiry = expiry;
    return expiry;
  }

  /// True when the JWT's `exp` claim is in the past (with a 15-second
  /// leeway so a token about to expire mid-request is renewed now). On any
  /// decode failure returns false — we then proceed and let the reactive
  /// 401 handler deal with it rather than blocking on an unreadable token.
  bool _isAccessTokenExpired(String token) {
    final expiry = _accessTokenExpiry(token);
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(
      expiry.subtract(const Duration(seconds: 15)),
    );
  }

  /// `exp` HAQIQATAN o'tganmi — 15 soniyalik zaxira oynasisiz.
  ///
  /// [_isAccessTokenExpired] "tez orada tugaydi"ni ham true deb beradi (shuning
  /// uchun oldindan yangilaymiz). Lekin yangilash tarmoq sababli muvaffaqiyatsiz
  /// bo'lsa, token HALI AMAL QILIB TURGAN bo'lishi mumkin — o'shanda foydalanuvchiga
  /// bekorga xato ko'rsatmaslik uchun shu qat'iy tekshiruv kerak.
  bool _isAccessTokenTrulyExpired(String token) {
    final expiry = _accessTokenExpiry(token);
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// Returns a non-expired access token, refreshing PROACTIVELY (single-
  /// flight) when the stored one has already expired.
  ///
  /// This is the key fix for the "dashboard intermittently shows no data"
  /// bug: a screen like the dashboard fires ~12 requests in parallel. With
  /// a stale token they would ALL 401 at once, and the reactive refresh +
  /// retry path is racy — requests whose 401 lands after the shared refresh
  /// future already settled would start a second refresh or fail to retry.
  /// Checking expiry up-front means the dozen requests funnel through ONE
  /// refresh BEFORE they're sent, so there's no 401-storm to recover from.
  ///
  /// `/Auth/` endpoints skip this — Login carries no token and RefreshToken
  /// must not recurse.
  Future<String?> _freshAccessToken(String endpoint) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return token;
    if (endpoint.contains('/Auth/')) return token;
    if (_isAccessTokenExpired(token)) {
      debugPrint('Access token expired — proactive refresh before $endpoint');
      final outcome = await _refreshTokenOnce();
      if (outcome == RefreshOutcome.renewed) return await getAccessToken();
      if (outcome == RefreshOutcome.transient) {
        // Tokenlar joyida, sessiya tirik — shunchaki hozir yangilay olmadik.
        //
        // MUHIM: bu yerga 15 soniyalik ZAXIRA oynasi tufayli ham kelamiz, ya'ni
        // token hali AMAL QILIB TURGAN bo'lishi mumkin. Bunday paytda bir soniyalik
        // uzilish yoki bitta 502 uchun foydalanuvchiga xato ko'rsatish — mantiqsiz:
        // hali tirik token bilan so'rovni yuboraveramiz, u muvaffaqiyatli o'tadi.
        if (!_isAccessTokenTrulyExpired(token)) return token;

        // Token haqiqatan muddati o'tgan — uni yuborsak 401 qaytaradi va yana
        // shu yo'lga tushardi. Oddiy tarmoq xatosi bilan tugatamiz.
        throw _refreshUnavailable(endpoint);
      }
      // rejected — _doRefresh sessiyani tugatdi va tokenlarni tozaladi;
      // so'rov 401 oladi, app shell esa /login'ga o'tkazadi.
    }
    return token;
  }

  // ✅ 401 xatolikni qayta ishlash va token refresh
  Future<http.Response> _handleResponse(
    http.Response response,
    String method,
    String endpoint, {
    Object? body,
  }) async {
    // 423 Locked = market was blocked by a SuperAdmin. The session is now
    // unusable — wipe tokens so the user can't keep retrying on a doomed
    // JWT, and emit the reason so the app shell can pop to a block screen.
    // Parse defensively: an upstream proxy returning 423 with no JSON body
    // shouldn't crash the client.
    if (response.statusCode == 423) {
      MarketBlockedInfo info;
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        info = MarketBlockedInfo(
          message:
              decoded['message'] as String? ??
              'Do\'kon administrator tomonidan bloklangan.',
          reason: decoded['reason'] as String?,
          blockedAt: decoded['blockedAt'] is String
              ? DateTime.tryParse(decoded['blockedAt'] as String)
              : null,
        );
      } catch (_) {
        info = MarketBlockedInfo(
          message: 'Do\'kon administrator tomonidan bloklangan.',
        );
      }
      await clearTokens();
      _marketBlockedController.add(info);
      return response;
    }

    // 401 — the access token expired. Refresh once (shared across every
    // concurrent 401), then retry THIS request with the fresh token.
    //
    // Auth endpoints are excluded: a 401 from Login / RefreshToken / Logout
    // is a genuine credential failure, not an expiry to transparently paper
    // over — retrying it would just loop.
    if (response.statusCode == 401 && !endpoint.contains('/Auth/')) {
      debugPrint('Access token expired (401 on $endpoint) — refreshing...');

      final outcome = await _refreshTokenOnce();

      // Renewed — either we rotated the pair ourselves, or a concurrent caller
      // won the race (409 REFRESH_RACE) and left a fresher token in the shared
      // storage. Either way _retryRequest re-reads storage and replays this
      // request ONCE with the new token.
      if (outcome == RefreshOutcome.renewed) {
        debugPrint('Token refreshed — retrying $method $endpoint');
        return _retryRequest(method, endpoint, body);
      }

      // Transient — the refresh couldn't be COMPLETED (offline, timeout, 502
      // mid-deploy). The tokens are untouched and the session is still alive,
      // so this must read as a network error, NOT a logout.
      if (outcome == RefreshOutcome.transient) {
        throw _refreshUnavailable(endpoint);
      }

      debugPrint('Token refresh rejected — user must login again');
      return response; // surface the 401 so the app shell can route to login
    }

    return response;
  }

  /// Refresh the access token, shared single-flight across concurrent 401s.
  /// The first caller starts the refresh; everyone else awaits the same
  /// Future — and therefore the same [RefreshOutcome].
  Future<RefreshOutcome> _refreshTokenOnce() {
    // Session already ended — don't start another doomed refresh (or emit a
    // duplicate sessionEnded). Cleared by saveTokens on the next login.
    if (_sessionEnded) {
      return Future<RefreshOutcome>.value(RefreshOutcome.rejected);
    }

    // Cooldown. Transient xato sessiyani o'ldirmagani uchun (bu ataylab shunday),
    // internet uzilganda HAR BIR so'rov yangi refresh boshlab yuborardi: o'nlab
    // 15-soniyalik so'rov, batareya va serverga bekorga yuk. Muvaffaqiyatsiz
    // urinishdan keyin qisqa muddat yangi urinish boshlamaymiz — kutayotgan
    // so'rovlar darhol "tarmoq xatosi" oladi. Muvaffaqiyatli refresh cooldown'ni
    // tozalaydi, ya'ni tarmoq tiklanishi bilan hammasi normal ishlaydi.
    final lastFailure = _lastRefreshFailureAt;
    if (_refreshInFlight == null &&
        lastFailure != null &&
        DateTime.now().difference(lastFailure) < _refreshCooldown) {
      return Future<RefreshOutcome>.value(RefreshOutcome.transient);
    }

    return _refreshInFlight ??= _doRefresh();
  }

  /// Runs ONE refresh and decides what it means for the session. The session
  /// is torn down ONLY on [RefreshOutcome.rejected]; a transient failure keeps
  /// both tokens on the device so the user isn't logged out by a flaky network
  /// or a redeploy.
  Future<RefreshOutcome> _doRefresh() async {
    // The token this refresh started from — used to detect whether a racing
    // caller has since written a NEWER one to the shared storage (409 below).
    final staleToken = _accessToken ?? await getAccessToken();
    var outcome = RefreshOutcome.transient;
    try {
      final auth = _authService;
      if (auth == null) {
        // DI not wired yet — retryable, definitely not a credential failure.
        debugPrint('HttpService._doRefresh: no AuthService wired');
        return outcome;
      }

      final result = await auth.refreshToken();
      outcome = result.outcome;

      if (outcome == RefreshOutcome.renewed) {
        final data = result.data;
        if (data != null) _tokenRefreshedController.add(data);
        return outcome;
      }

      // 409 REFRESH_RACE — a concurrent caller rotated the family first and
      // already saved the fresh pair to the SHARED storage. Re-read it: if the
      // access token really did change, this request can just go out again
      // with it. If storage still holds the old token, there's nothing to
      // retry with — fall back to an ordinary transient failure.
      if (result.isRace) {
        final fresh = await getAccessToken();
        if (fresh != null && fresh.isNotEmpty && fresh != staleToken) {
          debugPrint('Refresh race — a fresher token is in storage, retrying');
          outcome = RefreshOutcome.renewed;
        } else {
          debugPrint('Refresh race — storage still stale, treating as transient');
          outcome = RefreshOutcome.transient;
        }
      }

      return outcome;
    } catch (e) {
      // AuthService already classifies its own failures; anything escaping it
      // is unexpected — never destroy a session over it.
      debugPrint('HttpService._doRefresh error: $e');
      outcome = RefreshOutcome.transient;
      return outcome;
    } finally {
      // ALWAYS clear, on every path — a hung or failed refresh must never
      // wedge the app by leaving a dead Future for the next request to await.
      _refreshInFlight = null;

      // Cooldown hisobi: transient bo'lsa vaqtni belgilaymiz (keyingi so'rovlar
      // darhol yangi refresh boshlamasin), muvaffaqiyatda esa tozalaymiz —
      // tarmoq tiklangan zahoti hech qanday kechikish qolmasin.
      _lastRefreshFailureAt = outcome == RefreshOutcome.transient
          ? DateTime.now()
          : null;

      // G1 — emit ONCE per rejected refresh, not once per waiting request. The
      // single-flight gate above means every concurrent 401 awaited THIS
      // Future, so firing the event here keeps listeners from receiving a
      // duplicate "session ended" event for every parallel call. The first
      // listener (AuthProvider) navigates to /login and clears state;
      // subsequent listeners are idempotent.
      //
      // Only `rejected` gets here: a transient failure leaves the tokens in
      // place and emits NOTHING — the waiting request surfaces a normal
      // network error instead, and the next request retries the refresh.
      if (outcome == RefreshOutcome.rejected) {
        // Latch the dead session BEFORE the await below, so any request that
        // 401s while we're clearing tokens short-circuits in _refreshTokenOnce
        // instead of racing in a fresh refresh + emitting a second event.
        _sessionEnded = true;
        // Wipe any stale local copies so a navigator pop back to a protected
        // route can't re-authorize with the dead token.
        await clearTokens();
        _sessionEndedController.add(
          SessionEndedInfo(reason: SessionEndedReason.refreshFailed),
        );
      }
    }
  }

  /// The error a pending request gets when its refresh failed TRANSIENTLY:
  /// an ordinary network error, not a logout. Mirrors the timeout path's
  /// `ApiException(statusCode: 0)` so call sites branch uniformly.
  ApiException _refreshUnavailable(String endpoint) {
    debugPrint('Refresh temporarily unavailable — $endpoint surfaces a network error');
    return ApiException(
      statusCode: 0,
      message: 'Tarmoq xatosi. Internetni tekshirib, qayta urinib ko\'ring.',
      code: 'NETWORK',
    );
  }

  // So'rovni qayta yuborish
  Future<http.Response> _retryRequest(
    String method,
    String endpoint,
    Object? body,
  ) async {
    final token = await getAccessToken();

    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
      case 'POST':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return _client.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      case 'PUT':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return _client.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      case 'DELETE':
        return _client.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
      case 'PATCH':
        final encodedBody = body != null ? jsonEncode(body) : null;
        return _client.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        );
      default:
        // ApiException-2 — programmer error (the switch only covers GET /
        // POST / PUT / PATCH / DELETE; any other verb is a coding mistake
        // upstream). Surface as ArgumentError so a future static analyser
        // can flag it separately from network failures.
        throw ArgumentError('Unsupported method: $method');
    }
  }

  // GET request
  Future<http.Response> get(String endpoint) async {
    final response = await _performGet(endpoint);
    return _handleResponse(response, 'GET', endpoint);
  }

  Future<http.Response> _performGet(String endpoint) async {
    final token = await _freshAccessToken(endpoint);

    debugPrint('=== HTTP GET ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('Auth: ${token != null ? 'Bearer [•••]' : 'NO TOKEN'}');
    debugPrint('================');

    return _client
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(
          const Duration(seconds: 30),
          // ApiException-2 — surface timeouts as typed ApiException with
          // statusCode 0 so callers can branch on `e is ApiException`
          // without a separate catch arm for raw Exception.
          onTimeout: () {
            throw ApiException(
              statusCode: 0,
              message: 'Request timeout after 30 seconds',
              code: 'TIMEOUT',
            );
          },
        );
  }

  // POST request
  Future<http.Response> post(String endpoint, {Object? body}) async {
    final response = await _performPost(endpoint, body: body);
    return _handleResponse(response, 'POST', endpoint, body: body);
  }

  Future<http.Response> _performPost(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP POST ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('Auth: ${token != null ? 'Bearer [•••]' : 'NO TOKEN'}');
    debugPrint('Body: $encodedBody');
    debugPrint('================');

    return _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        )
        .timeout(
          const Duration(seconds: 30),
          // ApiException-2 — surface timeouts as typed ApiException with
          // statusCode 0 so callers can branch on `e is ApiException`
          // without a separate catch arm for raw Exception.
          onTimeout: () {
            throw ApiException(
              statusCode: 0,
              message: 'Request timeout after 30 seconds',
              code: 'TIMEOUT',
            );
          },
        );
  }

  // PUT request
  Future<http.Response> put(String endpoint, {Object? body}) async {
    final response = await _performPut(endpoint, body: body);
    return _handleResponse(response, 'PUT', endpoint, body: body);
  }

  Future<http.Response> _performPut(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP PUT ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('Has body: ${body != null}');
    debugPrint('Has token: ${token != null}');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      debugPrint('Body: $encodedBody');
    } else if (body != null) {
      debugPrint(
        'Body length: ${encodedBody?.length ?? 0} bytes (too large to display)',
      );
    }
    debugPrint('================');

    // For large bodies, stream the request via the shared keep-alive client
    // (Request API) instead of buffering through the put() convenience helper.
    if (encodedBody != null && encodedBody.length > 100000) {
      final request = http.Request('PUT', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      request.body = encodedBody;

      final streamedResponse = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw ApiException(
                statusCode: 0,
                message: 'Request timeout after 60 seconds',
                code: 'TIMEOUT',
              );
            },
          );
      return http.Response.fromStream(streamedResponse);
    }

    return _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: encodedBody,
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw ApiException(
              statusCode: 0,
              message: 'Request timeout after 60 seconds',
              code: 'TIMEOUT',
            );
          },
        );
  }

  // DELETE request (optionally with a JSON body — used by the SuperAdmin
  // owner-delete endpoint, which carries a typed-confirmation payload).
  Future<http.Response> delete(String endpoint, {Object? body}) async {
    final response = await _performDelete(endpoint, body);
    return _handleResponse(response, 'DELETE', endpoint, body: body);
  }

  Future<http.Response> _performDelete(String endpoint, Object? body) async {
    final token = await _freshAccessToken(endpoint);

    final fullUrl = '$baseUrl$endpoint';
    debugPrint('=== HTTP DELETE ===');
    debugPrint('Full URL: $fullUrl');
    debugPrint('==================');

    // The http package's delete() convenience method doesn't accept a body, so
    // hand-roll the request when one is supplied. RFC 7231 permits a body on
    // DELETE — ASP.NET Core accepts it with [FromBody].
    if (body == null) {
      return _client.delete(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    }

    final request = http.Request('DELETE', Uri.parse(fullUrl));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.body = jsonEncode(body);
    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }

  // PATCH request
  Future<http.Response> patch(String endpoint, {Object? body}) async {
    final response = await _performPatch(endpoint, body: body);
    return _handleResponse(response, 'PATCH', endpoint, body: body);
  }

  Future<http.Response> _performPatch(String endpoint, {Object? body}) async {
    final token = await _freshAccessToken(endpoint);
    final encodedBody = body != null ? jsonEncode(body) : null;

    debugPrint('=== HTTP PATCH ===');
    debugPrint('URL: $baseUrl$endpoint');
    if (body != null && encodedBody != null && encodedBody.length < 500) {
      debugPrint('Body: $encodedBody');
    }
    debugPrint('================');

    return _client.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: encodedBody,
    );
  }

  // Multipart file upload (for images, etc.)
  Future<http.Response> uploadFile(
    String endpoint, {
    required String filePath,
    String? fileFieldName,
    Map<String, String>? fields,
  }) async {
    final token = await _freshAccessToken(endpoint);
    final file = File(filePath);

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl$endpoint'),
    );

    // Add headers - use addAll instead of direct assignment
    request.headers.addAll({'Authorization': 'Bearer $token'});

    // Add file
    final fileStream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(
      fileFieldName ?? 'file',
      fileStream,
      length,
      filename: filePath.split('/').last,
    );
    request.files.add(multipartFile);

    // Add additional fields
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
    }

    debugPrint('=== HTTP MULTIPART UPLOAD ===');
    debugPrint('URL: $baseUrl$endpoint');
    debugPrint('File: $filePath');
    debugPrint('File size: ${(length / 1024).toStringAsFixed(2)} KB');
    debugPrint('================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Upload uchun ham 401 handle qilish
    return _handleResponse(response, 'PUT', endpoint);
  }

  // Fayl yuklab olish (byte array qaytaradi)
  Future<List<int>?> downloadBytes(String endpoint) async {
    try {
      final token = await _freshAccessToken(endpoint);

      debugPrint('=== HTTP DOWNLOAD BYTES ===');
      debugPrint('URL: $baseUrl$endpoint');
      debugPrint('================');

      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      // 401 xatolikni handle qilish
      final handledResponse = await _handleResponse(response, 'GET', endpoint);

      if (handledResponse.statusCode == 200) {
        return handledResponse.bodyBytes;
      }
      debugPrint('Download failed with status: ${handledResponse.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Download bytes error: $e');
      return null;
    }
  }
}
