import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

/// Visual tone of an [showAppSnackBar] toast.
enum AppSnackKind { success, error, warning, info }

/// Shows a beautiful, consistent app toast instead of the plain edge-to-edge
/// Material `SnackBar(content: Text(...), backgroundColor: ...)` that spans the
/// whole screen bottom with square corners.
///
/// The toast floats above the bottom with a margin, is fully rounded, carries a
/// tone-coloured icon in a soft circle, and casts a matching soft shadow. Any
/// currently-visible toast is cleared first so they never stack up.
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.success,
  Duration duration = const Duration(seconds: 3),
}) {
  final (Color color, IconData icon) = switch (kind) {
    AppSnackKind.success => (AppColors.success, Icons.check_circle_rounded),
    AppSnackKind.error => (AppColors.danger, Icons.error_rounded),
    AppSnackKind.warning => (AppColors.warning, Icons.warning_amber_rounded),
    AppSnackKind.info => (AppColors.info, Icons.info_rounded),
  };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Transparent + zero padding so ONLY the rounded card below is visible
        // (the default Material bar is square and edge-to-edge).
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        content: _AppSnackContent(message: message, color: color, icon: icon),
      ),
    );
}

class _AppSnackContent extends StatelessWidget {
  const _AppSnackContent({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
