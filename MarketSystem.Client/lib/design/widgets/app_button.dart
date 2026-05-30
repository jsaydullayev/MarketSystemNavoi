// Primary, secondary, and danger button widgets.
// Press animation: AnimationController drives scale (0.96) + bg-darken + shadow simultaneously.
// Haptic: lightImpact on press-down; disabled/loading states skip both.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

enum _AppButtonVariant { primary, secondary, danger }

class _AppButtonBase extends StatefulWidget {
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

  Color bg(bool isDark) {
    switch (variant) {
      case _AppButtonVariant.primary:
        return isDark ? AppColors.darkPrimaryLight : AppColors.brand;
      case _AppButtonVariant.secondary:
        return isDark ? AppColors.darkInputFill : AppColors.inputFill;
      case _AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color fg(bool isDark) {
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
  State<_AppButtonBase> createState() => _AppButtonBaseState();
}

class _AppButtonBaseState extends State<_AppButtonBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  bool get _interactive => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    // Controller value: 0.0 = released, 1.0 = fully pressed
    _ctrl = AnimationController(vsync: this, lowerBound: 0.0, upperBound: 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(PointerDownEvent _) {
    if (!_interactive) return;
    HapticFeedback.lightImpact();
    _ctrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeIn,
    );
  }

  void _onTapUp(PointerUpEvent _) => _release();
  void _onTapCancel(PointerCancelEvent _) => _release();

  void _release() {
    _ctrl.animateTo(
      0.0,
      duration: const Duration(milliseconds: 240),
      // easeOutBack: overshoot qilib qaytadi → "spring" his
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = widget.bg(isDark);
    final fg = widget.fg(isDark);

    return Listener(
      onPointerDown: _onTapDown,
      onPointerUp: _onTapUp,
      onPointerCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value; // 0 → 1

          // Scale: 1.0 → 0.96
          final scale = 1.0 - 0.04 * t;

          // Background: base → 12% qorong'i
          final pressedBg = Color.alphaBlend(
            Colors.black.withValues(alpha: 0.12 * t),
            baseBg,
          );

          // Shadow: release paytida yorqin shadow paydo bo'ladi
          // (press paytida "botadi", release paytida "ko'tariladi")
          final shadowOpacity = (1.0 - t) * (_interactive ? 0.18 : 0.0);

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: baseBg.withValues(alpha: shadowOpacity),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pressedBg,
                    foregroundColor: fg,
                    disabledBackgroundColor: baseBg.withValues(alpha: 0.5),
                    disabledForegroundColor: fg.withValues(alpha: 0.8),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    overlayColor: fg.withValues(alpha: 0.10),
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.isLoading
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
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  // Flexible + ellipsis so a long label (or a narrow,
                  // Expanded-in-a-Row button on a small phone / RU locale)
                  // degrades gracefully instead of overflowing the button.
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLarge().copyWith(color: fg),
                    ),
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
  Widget build(BuildContext context) => _AppButtonBase(
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    variant: _AppButtonVariant.primary,
  );
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
  Widget build(BuildContext context) => _AppButtonBase(
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    variant: _AppButtonVariant.secondary,
  );
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
  Widget build(BuildContext context) => _AppButtonBase(
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    variant: _AppButtonVariant.danger,
  );
}
