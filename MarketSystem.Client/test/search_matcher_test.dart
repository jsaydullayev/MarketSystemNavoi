// Qidiruv moslashtiruvchisi — sotuvchi tovar nomini aynan eslab qolmaydi,
// shuning uchun bu yerdagi holatlar amaldagi shikoyatlardan olingan.
import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/utils/search_matcher.dart';

void main() {
  group('yo / ye almashinuvi', () {
    test("'е' yozilsa 'ё' li tovar topiladi", () {
      expect(SearchMatcher.matches('Щётка металлическая', 'щетка'), isTrue);
      expect(SearchMatcher.matches('Щётка металлическая', 'щётка'), isTrue);
    });

    test("'ё' yozilsa 'е' li tovar ham topiladi (teskari)", () {
      expect(SearchMatcher.matches('Щетка металлическая', 'щётка'), isTrue);
    });

    test('bosh harf registri ahamiyatsiz', () {
      expect(SearchMatcher.matches('ЁЛКА', 'елка'), isTrue);
      expect(SearchMatcher.matches('елка', 'ЁЛКА'), isTrue);
    });
  });

  group("ko'p so'zli nom", () {
    const product = 'включатель 3 та VIKO';

    test("orasidagi so'z tashlab ketilsa ham topiladi", () {
      // Asosiy shikoyat: bu so'rov yaxlit bo'lak sifatida nomda YO'Q.
      expect(SearchMatcher.matches(product, 'включатель VIKO'), isTrue);
    });

    test("so'zlar tartibi muhim emas", () {
      expect(SearchMatcher.matches(product, 'VIKO включатель'), isTrue);
      expect(SearchMatcher.matches(product, 'viko 3'), isTrue);
    });

    test("bitta so'z ham yetadi", () {
      expect(SearchMatcher.matches(product, 'viko'), isTrue);
      expect(SearchMatcher.matches(product, 'включ'), isTrue);
    });

    test("nomda yo'q so'z bo'lsa topilmaydi", () {
      expect(SearchMatcher.matches(product, 'включатель LEGRAND'), isFalse);
      expect(SearchMatcher.matches(product, 'rozetka'), isFalse);
    });

    test("ortiqcha bo'shliqlar ahamiyatsiz", () {
      expect(SearchMatcher.matches(product, '  включатель    VIKO  '), isTrue);
      expect(
        SearchMatcher.matches('включатель   3   та   VIKO', 'включатель viko'),
        isTrue,
      );
    });
  });

  group('apostrof shakllari', () {
    test('turli apostroflar bir xil deb qaraladi', () {
      const queries = [
        "o'rindiq",
        'oʻrindiq',
        'o‘rindiq',
        'o’rindiq',
        'orindiq',
      ];
      for (final q in queries) {
        expect(
          SearchMatcher.matches("Yog'och o'rindiq", q),
          isTrue,
          reason: "so'rov: $q",
        );
      }
    });

    test("nomda apostrof bo'lmasa ham ishlaydi", () {
      expect(SearchMatcher.matches('Yogoch orindiq', "yog'och"), isTrue);
    });
  });

  group('chegaraviy holatlar', () {
    test("bo'sh so'rov hammaga mos (filtr o'chirilgan)", () {
      expect(SearchMatcher.matches('Sement', ''), isTrue);
      expect(SearchMatcher.matches('Sement', '   '), isTrue);
    });

    test("bo'sh yoki null nom faqat bo'sh so'rovga mos", () {
      expect(SearchMatcher.matches(null, 'sement'), isFalse);
      expect(SearchMatcher.matches('', 'sement'), isFalse);
      expect(SearchMatcher.matches(null, ''), isTrue);
    });

    test('normalize kutilgan natijani beradi', () {
      expect(SearchMatcher.normalize("  Щётка   O'RIN  "), 'щетка orin');
      expect(SearchMatcher.normalize(''), '');
    });

    test('tokenize', () {
      expect(SearchMatcher.tokenize('включатель VIKO'), ['включатель', 'viko']);
      expect(SearchMatcher.tokenize('   '), isEmpty);
    });
  });

  group('matchesAny — bir nechta maydon', () {
    test("so'zlar turli maydonlardan topilsa ham mos keladi", () {
      expect(
        SearchMatcher.matchesAny(
          ['Toshmat Qarzdor', '998901112233'],
          'toshmat 9989',
        ),
        isTrue,
      );
    });

    test("bitta so'z hech qaysi maydonda bo'lmasa mos kelmaydi", () {
      expect(
        SearchMatcher.matchesAny(
          ['Toshmat Qarzdor', '998901112233'],
          'toshmat 777',
        ),
        isFalse,
      );
    });

    test("null maydonlar e'tiborga olinmaydi", () {
      expect(SearchMatcher.matchesAny(['Sement', null], 'sement'), isTrue);
      expect(SearchMatcher.matchesAny([null, null], 'sement'), isFalse);
    });
  });
}
