import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:market_system_client/core/errors/api_exception.dart';

/// G4 — pins the parsing of the backend's structured error envelope so
/// the SHIFT_NOT_OPEN branch (and every other future `code`) survives
/// any refactor of ApiException.fromResponse.
void main() {
  group('ApiException.fromResponse', () {
    test('extracts message + code from JSON 409 body', () {
      final res = http.Response(
        '{"message":"Ochiq smena topilmadi. Avval smenani oching.",'
        '"code":"SHIFT_NOT_OPEN","traceId":"abc"}',
        409,
      );

      final ex = ApiException.fromResponse(res);

      expect(ex.statusCode, 409);
      expect(ex.code, 'SHIFT_NOT_OPEN');
      expect(ex.message, 'Ochiq smena topilmadi. Avval smenani oching.');
      expect(ex.isShiftNotOpen, isTrue);
      expect(ex.isConflict, isTrue);
    });

    test('isShiftNotOpen false when code is null', () {
      final res = http.Response('{"message":"Generic 409"}', 409);
      final ex = ApiException.fromResponse(res);
      expect(ex.isShiftNotOpen, isFalse);
      expect(ex.isConflict, isTrue);
    });

    test('falls back to fallbackMessage when body is not JSON', () {
      final res = http.Response('<html>502 Bad Gateway</html>', 502);
      final ex = ApiException.fromResponse(
        res,
        fallbackMessage: 'Server bilan ulanishda muammo.',
      );
      expect(ex.statusCode, 502);
      expect(ex.code, isNull);
      expect(ex.message, 'Server bilan ulanishda muammo.');
    });

    test('falls back to a generic message when body is empty and no fallback given', () {
      final res = http.Response('', 503);
      final ex = ApiException.fromResponse(res);
      expect(ex.statusCode, 503);
      expect(ex.message.contains('503'), isTrue);
    });

    test('captures full payload for callers that want it', () {
      final res = http.Response(
        '{"message":"Bloklangan","code":"MARKET_BLOCKED","blockedAt":"2026-01-01T00:00:00Z"}',
        423,
      );

      final ex = ApiException.fromResponse(res);

      expect(ex.code, ApiException.codeMarketBlocked);
      expect(ex.payload?['blockedAt'], '2026-01-01T00:00:00Z');
    });

    test('toString includes status code and code', () {
      final res = http.Response('{"message":"x","code":"ACCOUNT_LOCKED"}', 429);
      expect(
        ApiException.fromResponse(res).toString(),
        contains('ACCOUNT_LOCKED'),
      );
    });
  });
}
