// Smoke test placeholder so `flutter test` exits 0 when there are no real
// widget/unit tests yet. Without at least one test, Flutter exits with code 1
// ("Test directory 'test' not found") which breaks CI even on green code.
//
// Replace this with real widget/integration tests as the test suite grows.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke: arithmetic sanity', () {
    expect(2 + 2, equals(4));
  });
}
