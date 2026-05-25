// Thin adapter over the design-system AppTextInput so the existing customers
// forms keep their `CustomTextField(controller, label, icon, …)` API while we
// migrate the visuals. New code should use `AppTextInput` directly.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.helperText,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final AutovalidateMode autovalidateMode;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: context.colors.textSecondary,
            ),
            filled: true,
            fillColor: context.colors.inputFill,
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
              borderSide: BorderSide(color: context.colors.brand, width: 1.5),
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
        if (helperText case final helper?) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            helper,
            style: AppTextStyles.bodySmall().copyWith(
              color: context.colors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
