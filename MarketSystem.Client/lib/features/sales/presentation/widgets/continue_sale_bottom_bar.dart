import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';

class ContinueSaleBottomBar extends StatelessWidget {
  final double totalAmount;
  final bool cartIsEmpty;
  final bool isClosed;
  final VoidCallback onCheckout;

  const ContinueSaleBottomBar({
    super.key,
    required this.totalAmount,
    required this.cartIsEmpty,
    required this.isClosed,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          // Jami summa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jami summa',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
                Text(
                  NumberFormatter.formatDecimal(totalAmount),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // To'lov tugmasi (faqat yopilmagan savdo uchun)
          if (!isClosed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: cartIsEmpty ? null : onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cartIsEmpty
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text(
                  'TO\'LOV QILISH',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
