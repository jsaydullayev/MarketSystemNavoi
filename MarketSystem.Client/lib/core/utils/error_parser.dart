class ErrorParser {
  /// Serverdan kelgan xatolik matnini chiroyli ko'rinishga keltiradi
  static String parse(String raw) {
    // Agar serverda tranzaksiya yoki ulanish xatosi bo'lsa
    if (raw.contains('NpgsqlRetryingExecutionStrategy') ||
        raw.contains('execution strategy') ||
        raw.contains('CreateExecutionStrategy')) {
      return 'Server xatosi: to\'lov bajarilmadi.\nQayta urinib ko\'ring yoki administratorga murojaat qiling.';
    }

    // To'lov bilan bog'liq xatolarni ajratib olish
    if (raw.contains('Payment failed')) {
      final idx = raw.indexOf('Payment failed:');
      if (idx != -1) {
        final msg = raw.substring(idx + 'Payment failed:'.length).trim();
        // Agar xabar juda uzun yoki texnik bo'lsa, umumiy xabar qaytaramiz
        if (msg.contains('NpgsqlRetrying') || msg.length > 120) {
          return 'To\'lov amalga oshmadi. Server bilan muammo bor, qayta urinib ko\'ring.';
        }
        return 'To\'lov amalga oshmadi: $msg';
      }
    }

    // Agar xatolik matni juda uzun bo'lsa (masalan, HTML kod kelib qolsa)
    if (raw.length > 150) {
      return 'Kutilmagan xato yuz berdi. Qayta urinib ko\'ring.';
    }

    // "Exception: " so'zini olib tashlab qaytarish
    return raw.replaceFirst('Exception: ', '');
  }
}
