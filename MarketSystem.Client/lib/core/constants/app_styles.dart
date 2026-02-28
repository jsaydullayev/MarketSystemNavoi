import 'package:flutter/material.dart';

class AppStyles {
  static BoxDecoration cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
      ),
    );
  }

  static const TextStyle brandTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 22,
    letterSpacing: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
