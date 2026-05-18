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

  Color get _bg {
    switch (variant) {
      case _AppButtonVariant.primary:
        return AppColors.brand;
      case _AppButtonVariant.secondary:
        return AppColors.inputFill;
      case _AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color get _fg {
    switch (variant) {
      case _AppButtonVariant.secondary:
        return AppColors.text;
      case _AppButtonVariant.primary:
      case _AppButtonVariant.danger:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bg,
          foregroundColor: _fg,
          disabledBackgroundColor: _bg.withValues(alpha: 0.5),
          disabledForegroundColor: _fg.withValues(alpha: 0.8),
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
                  valueColor: AlwaysStoppedAnimation<Color>(_fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: _fg),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.labelLarge().copyWith(color: _fg),
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
