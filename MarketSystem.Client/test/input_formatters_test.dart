// Qarz to'lov maydonining xatti-harakati: foydalanuvchi summa yozganda
// boshdagi nolni qo'lda o'chirishga majbur bo'lmasligi va raqam minglik
// ajratgich bilan ko'rinishi kerak ("50000" → "50 000").
import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/utils/input_formatters.dart';

void main() {
  const fmt = ThousandsSeparatorFormatter();

  /// Maydonga bitta belgi yozishni taqlid qiladi.
  String type(String current, String typed) => fmt
      .formatEditUpdate(
        TextEditingValue(text: current),
        TextEditingValue(text: current + typed),
      )
      .text;

  group('ThousandsSeparatorFormatter — to\'lov summasi', () {
    test('minglik ajratgich qo\'yadi', () {
      expect(fmt.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '50000'),
      ).text, '50 000');

      expect(ThousandsSeparatorFormatter.group('1000000'), '1 000 000');
      expect(ThousandsSeparatorFormatter.group('500'), '500');
    });

    test('bo\'sh maydonga raqam-raqam yozilganda to\'g\'ri guruhlanadi', () {
      var t = '';
      for (final ch in '50000'.split('')) {
        t = type(t, ch);
      }
      expect(t, '50 000');
    });

    test('boshdagi nol yozilgan raqam bilan almashadi ("0"+"5" → "5")', () {
      // Asosiy nosozlik: "Tozalash" maydonga '0' yozar, keyin foydalanuvchi
      // 5 bosganda "05" chiqardi va nolni qo'lda o'chirishga to'g'ri kelardi.
      expect(type('0', '5'), '5');
      expect(fmt.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '050000'),
      ).text, '50 000');
    });

    test('yolg\'iz nol va o\'nlik kasr saqlanadi', () {
      expect(type('', '0'), '0');
      expect(fmt.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1500.50'),
      ).text, '1 500.50');
    });

    test('harflar yozilmaydi', () {
      expect(type('50 000', 'a'), '50 000');
    });

    test('unformat — o\'qishga qaytarish', () {
      expect(double.parse(ThousandsSeparatorFormatter.unformat('50 000')), 50000);
      expect(double.parse(ThousandsSeparatorFormatter.unformat('1 500,50')), 1500.5);
    });

    test('bo\'sh maydon bo\'sh qoladi (to\'lov summasi 0 emas)', () {
      expect(ThousandsSeparatorFormatter.group(''), '');
      expect(fmt.formatEditUpdate(
        const TextEditingValue(text: '50 000'),
        TextEditingValue.empty,
      ).text, '');
    });
  });
}
