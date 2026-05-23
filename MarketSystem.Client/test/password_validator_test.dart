import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/validators/password_validator.dart';

/// G2 — pins the client-side password policy so it stays in lockstep with
/// the backend StrongPasswordAttribute. Whenever someone changes one side
/// they have to run these tests and see the other side fail.
void main() {
  group('PasswordValidator.isStrong', () {
    test('accepts 8+ chars with letter and digit', () {
      expect(PasswordValidator.isStrong('Password1'), isTrue);
      expect(PasswordValidator.isStrong('ab1cdefg'), isTrue);
      expect(PasswordValidator.isStrong('Parol2026!'), isTrue, reason: 'symbols allowed but not required');
    });

    test('rejects too-short passwords', () {
      expect(PasswordValidator.isStrong('short1'), isFalse, reason: '6 chars');
      expect(PasswordValidator.isStrong('1234567'), isFalse, reason: '7 chars');
    });

    test('rejects passwords missing a digit', () {
      expect(PasswordValidator.isStrong('alllettersnodigit'), isFalse);
    });

    test('rejects passwords missing a letter', () {
      expect(PasswordValidator.isStrong('12345678'), isFalse);
    });

    test('accepts Cyrillic letters', () {
      // Mirror StrongPasswordAttribute's Unicode-letter check — uz / ru
      // locales include Cyrillic content.
      expect(PasswordValidator.isStrong('Парол123ru'), isTrue);
    });

    test('rejects over-long passwords (> 100 chars)', () {
      // 101 chars: 100 letters + 1 digit
      final tooLong = '${'A' * 100}1';
      expect(PasswordValidator.isStrong(tooLong), isFalse);
    });

    test('accepts exactly 100 chars', () {
      final atMax = '${'A' * 99}1';
      expect(PasswordValidator.isStrong(atMax), isTrue);
    });
  });
}
