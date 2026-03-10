import 'package:flutter/material.dart';
import 'package:market_system_client/core/utils/number_formatter.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class ContinueSaleProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const ContinueSaleProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quantity = (product['quantity'] as num?)?.toDouble() ?? 0.0;
    final isInStock = quantity > 0;
    final isLow = quantity > 0 && quantity <= 5;
    final l10n = AppLocalizations.of(context)!;

    final stockColor = isLow
        ? Colors.orange
        : isInStock
            ? const Color(0xFF10B981)
            : Colors.grey;

    return GestureDetector(
      onTap: isInStock ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E)
              : isInStock
                  ? Colors.white
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : isInStock
                    ? const Color(0xFFE5E7EB)
                    : Colors.grey.shade200,
          ),
          boxShadow: [
            if (!isDark && isInStock)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mahsulot nomi
              Text(
                product['name'] ?? l10n.unknown,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? Colors.white
                      : isInStock
                          ? const Color(0xFF1F2937)
                          : Colors.grey,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Narx
              Text(
                NumberFormatter.format(product['salePrice']),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isInStock
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade400,
                ),
              ),

              // Qoldiq + Tugma
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Qoldiq
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 10,
                          color: stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Qo'shish tugmasi
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isInStock
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: isInStock ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
