import 'package:intl/intl.dart';

class NumberFormatter {
  // Hoisted to class level so the hot paths (every product/sale/debt card,
  // re-run on each scroll frame and search keystroke) don't allocate a fresh
  // NumberFormat + compile a RegExp on every call. NumberFormat.format is a
  // pure read, so a single shared instance per decimal-mode is safe.
  static final NumberFormat _fmtInt = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 0,
  );
  static final NumberFormat _fmtDec = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 2,
  );
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _trailingZeros = RegExp(r'\.?0+$');

  /// Format number with space separator (e.g., 100000 -> "100 000")
  static String format(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      final cleanVal = value.replaceAll(_whitespace, '').replaceAll(',', '.');
      number = num.tryParse(cleanVal) ?? 0;
    } else if (value is num) {
      number = value;
    } else {
      number = 0;
    }

    final bool hasDecimals =
        number is double && number != number.truncateToDouble();

    // Shared NumberFormat.currency instances (space separator via ru_RU).
    return (hasDecimals ? _fmtDec : _fmtInt).format(number).trim();
  }

  /// Format decimal number with space separator (e.g., 15000.50 -> "15 000.50")
  static String formatDecimal(dynamic value) {
    if (value == null) return '0';

    num number;
    if (value is String) {
      final cleanVal = value.replaceAll(_whitespace, '').replaceAll(',', '.');
      number = num.tryParse(cleanVal) ?? 0;
    } else if (value is num) {
      number = value;
    } else {
      number = 0;
    }

    // Decide on decimal digits by VALUE, not by source type. `100` (int)
    // and `100.0` (double) should format identically; using `number is int`
    // made the result depend on whether JSON parsed it as int or double.
    final bool hasDecimals =
        number is double && number != number.truncateToDouble();

    return (hasDecimals ? _fmtDec : _fmtInt).format(number);
  }

  /// Format a quantity for display.
  /// Whole numbers render without decimals ("5"); fractional kg/m amounts
  /// keep up to 3 decimals with trailing zeros stripped ("1.5", "1.25").
  /// Using `.toStringAsFixed(0)` on a quantity would silently turn 1.5 kg
  /// into "1 kg" — that's a real-world money bug when users see less than
  /// they bought.
  static String formatQuantity(dynamic value) {
    if (value == null) return '0';
    num n;
    if (value is num) {
      n = value;
    } else if (value is String) {
      n = num.tryParse(value.replaceAll(',', '.')) ?? 0;
    } else {
      return '0';
    }
    final d = n.toDouble();
    if (d == d.truncateToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(3).replaceAll(_trailingZeros, '');
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
  /// Sum of `salePrice * quantity` across every cart row. Forces both fields
  /// through `.toDouble()` so a JSON integer (`price: 80000`) and a JSON
  /// double (`price: 80000.0`) produce the same total — dynamic numeric
  /// multiplication in Dart can otherwise stay as int and lose the running
  /// double sum's precision on later rows.
  double get totalAmount {
    return fold(0.0, (sum, item) {
      final price = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      return sum + (price * qty);
    });
  }
}
