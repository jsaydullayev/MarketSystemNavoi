import 'package:intl/intl.dart';

class NumberFormatter {
  /// Format number with space separator (e.g., 100000 -> "100 000")
  static String format(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      final cleanVal = value.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      number = num.tryParse(cleanVal) ?? 0;
    } else if (value is num) {
      number = value;
    } else {
      number = 0;
    }

    final bool hasDecimals = number is double && number != number.truncateToDouble();

    // Use NumberFormat.currency with custom symbol to get space separator
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: hasDecimals ? 2 : 0,
    );

    return formatter.format(number).trim();
  }

  /// Format decimal number with space separator (e.g., 15000.50 -> "15 000.50")
  static String formatDecimal(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      final cleanVal = value.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      number = num.tryParse(cleanVal) ?? 0;
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

  /// Format DateTime to GMT+5 (Tashkent time)
  /// Returns formatted string: "DD.MM.YYYY HH:MM" or "DD.MM.YYYY" (timeOnly=false)
  static String formatDateTime(dynamic dateTime, {bool showTime = true}) {
    if (dateTime == null) return 'Noma\'lum';

    DateTime date;
    if (dateTime is String) {
      try {
        date = DateTime.parse(dateTime);
      } catch (e) {
        return dateTime.toString();
      }
    } else if (dateTime is DateTime) {
      date = dateTime;
    } else {
      return 'Noma\'lum';
    }

    // Convert to GMT+5 (Tashkent time)
    final tashkentTime = date.toUtc().add(const Duration(hours: 5));

    if (showTime) {
      // Format: "23.02.2026 14:30"
      return '${tashkentTime.day.toString().padLeft(2, '0')}.'
          '${tashkentTime.month.toString().padLeft(2, '0')}.'
          '${tashkentTime.year} '
          '${tashkentTime.hour.toString().padLeft(2, '0')}:'
          '${tashkentTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Format: "23.02.2026"
      return '${tashkentTime.day.toString().padLeft(2, '0')}.'
          '${tashkentTime.month.toString().padLeft(2, '0')}.'
          '${tashkentTime.year}';
    }
  }

  /// Format time only (GMT+5): "14:30"
  static String formatTime(dynamic dateTime) {
    if (dateTime == null) return 'Noma\'lum';

    DateTime date;
    if (dateTime is String) {
      try {
        date = DateTime.parse(dateTime);
      } catch (e) {
        return dateTime.toString();
      }
    } else if (dateTime is DateTime) {
      date = dateTime;
    } else {
      return 'Noma\'lum';
    }

    // Convert to GMT+5 (Tashkent time)
    final tashkentTime = date.toUtc().add(const Duration(hours: 5));

    return '${tashkentTime.hour.toString().padLeft(2, '0')}:'
        '${tashkentTime.minute.toString().padLeft(2, '0')}';
  }
}

extension CartTotal on List<Map<String, dynamic>> {
  double get totalAmount {
    return fold(0.0, (sum, item) {
      final price = item['salePrice'] ?? 0.0;
      final qty = item['quantity'] ?? 0.0;
      return sum + (price * qty);
    });
  }
}
