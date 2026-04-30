import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static TextStyle brandTitle = GoogleFonts.notoSans(
    fontWeight: FontWeight.bold,
    fontSize: 22,
    letterSpacing: 1.2,
  );

  static TextStyle cardTitle = GoogleFonts.notoSans(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static TextStyle subtitle = GoogleFonts.notoSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
