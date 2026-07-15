// Form field input with uppercase label, gray fill, and orange focus border per demo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_tokens.dart';
import '../tokens/app_typography.dart';

class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    // Resolve fill / text / focus colours against the active theme. The
    // focus border follows the theme accent: brand orange in light, the
    // light-blue dark-primary in dark.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final hintColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final fillColor = isDark ? AppColors.darkInputFill : AppColors.inputFill;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final focusColor = isDark ? AppColors.darkPrimaryLight : AppColors.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label case final lbl?) ...[
          Text(
            lbl.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTextStyles.bodyMedium().copyWith(
            fontSize: 15,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium().copyWith(
              color: hintColor,
              fontSize: 15,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: labelColor)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: BorderSide(color: focusColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
