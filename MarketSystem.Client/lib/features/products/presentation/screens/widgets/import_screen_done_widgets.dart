import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_theme_colors.dart';
import '../../../../../design/tokens/app_tokens.dart';
import '../../../../../design/tokens/app_typography.dart';

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatRow(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textSecondary,
            )),
        Text(value,
            style: AppTextStyles.bodyMedium().copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            )),
      ],
    ),
  );
}
