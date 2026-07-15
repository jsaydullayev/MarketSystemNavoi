import 'package:flutter/services.dart';

/// Numeric input normaliser for quantity/stock-style fields:
///  • rejects any non-numeric character (letters can't be typed at all),
///  • drops a leading zero once another digit follows: "0"+"5" → "5",
///    "0500" → "500", while keeping a lone "0" and decimals like "0.5".
/// Allows a single decimal separator ('.' or ',').
class NoLeadingZeroFormatter extends TextInputFormatter {
  const NoLeadingZeroFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits and separators — this is what blocks letters.
    var result = newValue.text.replaceAll(RegExp(r'[^0-9.,]'), '');

    if (result.length >= 2 &&
        result[0] == '0' &&
        result[1] != '.' &&
        result[1] != ',') {
      final stripped = result.replaceFirst(RegExp(r'^0+'), '');
      result = stripped.isEmpty ? '0' : stripped;
    }

    if (result == newValue.text) return newValue;
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Groups the integer part with thin spaces as the user types so large amounts
/// stay readable: "100000" → "100 000". Preserves a trailing decimal part and
/// strips any non-numeric characters. Read the raw value back with
/// `double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'))` — or use
/// [unformat].
class ThousandsSeparatorFormatter extends TextInputFormatter {
  const ThousandsSeparatorFormatter();

  /// Strip grouping spaces and normalise the decimal separator to '.'.
  static String unformat(String text) =>
      text.replaceAll(' ', '').replaceAll(',', '.');

  /// Group a raw numeric string for an initial controller value:
  /// "100000" → "100 000". Empty in, empty out.
  static String group(String raw) {
    if (raw.trim().isEmpty) return '';
    return const ThousandsSeparatorFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: raw),
        )
        .text;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (raw.isEmpty) return const TextEditingValue(text: '');

    final sepIdx = raw.indexOf(RegExp(r'[.,]'));
    String intPart;
    String rest;
    if (sepIdx >= 0) {
      intPart = raw.substring(0, sepIdx);
      rest = raw.substring(sepIdx); // keeps the separator + decimals
    } else {
      intPart = raw;
      rest = '';
    }

    // Drop leading zeros on the integer part (but keep a single 0).
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final grouped = _group(intPart);
    final text = '$grouped$rest';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _group(String digits) {
    if (digits.length <= 3) return digits;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
