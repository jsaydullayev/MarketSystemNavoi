import 'package:intl/intl.dart';

class NumberFormatter {
  /// Format number with space separator (e.g., 100000 -> "100 000")
  static String format(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      number = num.tryParse(value) ?? 0;
    } else if (value is num) {
      number = value;
    } else {
      number = 0;
    }

    // Use NumberFormat.currency with custom symbol to get space separator
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );

    return formatter.format(number);
  }

  /// Format decimal number with space separator (e.g., 15000.50 -> "15 000.50")
  static String formatDecimal(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      number = num.tryParse(value) ?? 0;
    } else if (value is num) {
      number = value;
    } else {
      number = 0;
    }

    // Use NumberFormat.currency with custom symbol
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: number is int ? 0 : 2,
    );

    return formatter.format(number);
  }
}
