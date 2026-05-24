import 'package:flutter/material.dart';

/// Lightweight dashed-border painter used for the receipt card outline.
class SaleReceiptPainter extends CustomPainter {
  const SaleReceiptPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    const dashLen = 4.0;
    const gapLen = 3.0;
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLen).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SaleReceiptPainter old) =>
      old.color != color || old.radius != radius;
}
