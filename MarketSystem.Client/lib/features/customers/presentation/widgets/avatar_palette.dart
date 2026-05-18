// Centralised colour palette + name-hash strategy for customer avatars.
//
// The demo cycles five accent colours (orange / blue / green / purple / pink)
// across customer rows. We hash by the customer's display label so the same
// customer keeps the same colour in the list, the detail hero and the
// "qarzdorlar" page — switching strategies (index, random, hash) only here
// keeps the rest of the migration trivial.

import 'package:flutter/material.dart';

class CustomerAvatarPalette {
  static const _palette = <Color>[
    Color(0xFFF97316), // orange
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // green
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
  ];

  /// Stable colour for a customer based on a hash of the label string.
  /// Empty / null labels fall back to the first palette entry so we never
  /// hand back a transparent or wildly off-brand colour.
  static Color pick(String? label) {
    if (label == null || label.isEmpty) return _palette.first;
    var hash = 0;
    for (final code in label.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }
}
