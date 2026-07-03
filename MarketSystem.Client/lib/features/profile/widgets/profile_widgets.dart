// Shared profile/settings building blocks mapped to the demo `id="page-sett-hub"`:
// - [ProfileSectionTitle] -> `.settings-section-title` uppercase muted label
// - [ProfileSettingsCard] -> `.settings-section` rounded surface that groups rows
// - [ProfileSettingsRow]  -> `.settings-row` with colored 32x32 icon tile + meta
// - [ProfileTopCard]      -> `.settings-profile` brand-light avatar header card
//
// All widgets are light-only and rely on the design system tokens.

import 'package:flutter/material.dart';

import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';

/// Color presets for the 32x32 icon tile in [ProfileSettingsRow].
/// Mirrors `.settings-row .ic.<name>` background tints in the demo.
enum ProfileRowIconTone { brand, green, blue, purple, pink, gray, red }

class ProfileSectionTitle extends StatelessWidget {
  final String title;
  const ProfileSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // Demo `.settings-section-title`: 10px, weight 700, letter-spacing 1.2px,
    // muted color, rendered against a faint section background.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.caption().copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.colors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Grouped settings card matching demo `.settings-section`:
/// white surface, 1px border, 14px radius, dividers between children.
class ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Widget? header;
  const ProfileSettingsCard({super.key, required this.children, this.header});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(height: 1, thickness: 1, color: context.colors.border),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header case final h?)
              Container(color: context.colors.bg, child: h),
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// Single settings row matching demo `.settings-row`:
/// 32x32 colored icon tile + title (13/600) + optional meta (11/muted) + value + chevron.
class ProfileSettingsRow extends StatelessWidget {
  final IconData icon;
  final ProfileRowIconTone tone;
  final String title;
  final String? meta;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  const ProfileSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.tone = ProfileRowIconTone.brand,
    this.meta,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  // A method (not a getter) so the brand / gray tones can resolve against
  // the active theme — those two reference the surface/accent family which
  // differs between light and dark.
  ({Color bg, Color fg}) _toneColors(BuildContext context) {
    switch (tone) {
      case ProfileRowIconTone.brand:
        return (bg: context.colors.brandLight, fg: context.colors.brand);
      case ProfileRowIconTone.green:
        return (bg: AppColors.successLight, fg: AppColors.success);
      case ProfileRowIconTone.blue:
        return (bg: AppColors.accentBlueTint, fg: AppColors.accentBlue);
      case ProfileRowIconTone.purple:
        return (bg: AppColors.accentPurpleTint, fg: AppColors.accentPurple);
      case ProfileRowIconTone.pink:
        return (bg: AppColors.accentPinkTint, fg: AppColors.accentPinkStrong);
      case ProfileRowIconTone.gray:
        return (bg: context.colors.inputFill, fg: context.colors.textSecondary);
      case ProfileRowIconTone.red:
        return (bg: AppColors.dangerLight, fg: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context);
    final titleColor = danger ? AppColors.danger : context.colors.text;

    return Material(
      color: context.colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md - 1),
                ),
                child: Icon(icon, size: 16, color: colors.fg),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (meta case final m?) ...[
                      const SizedBox(height: 2),
                      Text(
                        m,
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value case final v?) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  v,
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
              if (trailing case final t?) ...[
                const SizedBox(width: AppSpacing.sm),
                t,
              ] else if (onTap != null && !danger) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: context.colors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-light avatar header card matching demo `.settings-profile`.
/// 48x48 brand-light circle with first letter + name (14/800) + role chip + arrow.
class ProfileTopCard extends StatelessWidget {
  final String? fullName;
  final String? role;
  final String? marketName;
  final VoidCallback? onTap;

  const ProfileTopCard({
    super.key,
    this.fullName,
    this.role,
    this.marketName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (fullName ?? '').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final greeting = name.isEmpty ? 'Salom' : 'Salom, $name';
    final roleLabel = (role ?? '').trim();
    final market = (marketName ?? '').trim();
    final roleText = [
      if (roleLabel.isNotEmpty) roleLabel.toUpperCase(),
      if (market.isNotEmpty) market,
    ].join(' · ');

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg + 2),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.brandLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: AppTextStyles.titleMedium().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colors.brand,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.colors.text,
                      ),
                    ),
                    if (roleText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleText,
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editable single-line field used inside profile info card.
/// Renders an underline-less TextField with a small label above.
class ProfileEditableField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const ProfileEditableField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = context.colors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 16,
              color: context.colors.brand,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: context.colors.textMuted,
                  ),
                ),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled ? context.colors.text : disabledColor,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 18, color: context.colors.textMuted),
        ],
      ),
    );
  }
}

/// Read-only info row using the same visual shape as [ProfileEditableField].
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
            ),
            child: Icon(icon, size: 16, color: context.colors.brand),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption().copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
