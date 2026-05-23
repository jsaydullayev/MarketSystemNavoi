// Primary, secondary, and danger button widgets matching the demo's button styles.

import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

enum _AppButtonVariant { primary, secondary, danger }

class _AppButtonBase extends StatelessWidget {
  const _AppButtonBase({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final _AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Background colour, resolved against the active theme.
  ///   light primary   → brand orange
  ///   dark  primary   → light "sky" blue (per the dark palette)
  ///   secondary       → the theme's input-fill grey
  ///   danger          → red (same in both themes)
  Color _bg(bool isDark) {
    switch (variant) {
      case _AppButtonVariant.primary:
        return isDark ? AppColors.darkPrimaryLight : AppColors.brand;
      case _AppButtonVariant.secondary:
        return isDark ? AppColors.darkInputFill : AppColors.inputFill;
      case _AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  /// Foreground (text/icon) colour.
  ///   light primary → white on orange
  ///   dark  primary → dark navy on light-blue — white text fails the
  ///                   contrast check against #60A5FA, navy passes.
  Color _fg(bool isDark) {
    switch (variant) {
      case _AppButtonVariant.secondary:
        return isDark ? AppColors.darkText : AppColors.text;
      case _AppButtonVariant.primary:
        return isDark ? AppColors.darkBg : Colors.white;
      case _AppButtonVariant.danger:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _bg(isDark);
    final fg = _fg(isDark);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: fg.withValues(alpha: 0.8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.labelLarge().copyWith(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      variant: _AppButtonVariant.primary,
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      variant: _AppButtonVariant.secondary,
    );
  }
}

class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      variant: _AppButtonVariant.danger,
    );
  }
}
