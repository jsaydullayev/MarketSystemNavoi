import 'package:flutter/material.dart';

class PaymentTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PaymentTypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    {'value': 'Cash', 'label': 'Naqd', 'icon': Icons.payments_rounded},
    {
      'value': 'Terminal',
      'label': 'Plastik',
      'icon': Icons.credit_card_rounded
    },
    {
      'value': 'Transfer',
      'label': 'Transfer',
      'icon': Icons.swap_horiz_rounded
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((type) {
        final isSelected = selected == type['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF3B82F6).withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected ? Colors.white : const Color(0xFF3B82F6),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
