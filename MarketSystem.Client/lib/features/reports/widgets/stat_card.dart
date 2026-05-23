import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

/// KPI tile shown in 2x2 grids on the Reports hub.
///
/// Demo reference: `id="page-rpt-hub"` cards in `design-demo/index.html` —
/// white surface with a colored icon tile + label on top, then a big
/// brand-tinted value. The `color` parameter is the accent for the icon
/// tile and the value; the card itself stays neutral (AppColors.surface)
/// so a row of cards reads as a calm grid instead of a rainbow.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isClickable;
  final bool isLoading;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isClickable = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md - 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelSmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  else if (isClickable)
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: color),
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.titleMedium().copyWith(
                    fontSize: 20,
                    color: color,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (subtitle case final sub?) ...[
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: AppTextStyles.bodySmall().copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
