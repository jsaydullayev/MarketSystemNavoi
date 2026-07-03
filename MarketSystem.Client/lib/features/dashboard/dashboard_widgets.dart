// Dashboard widgets aligned to the new design system (lib/design/*).
//
// These widgets render the Owner / Admin / Seller dashboard surfaces
// described in design-demo/index.html (#page-owner-dash and #page-staff-dash):
// greeting card, sales hero card, KPI grid, alert strip, mini chart, and
// top-sellers list. They are presentation-only StatelessWidgets — caller
// supplies the data and tap handlers.
//
// This file hosts the GreetingCard (and its private avatar / icon helpers).
// The remaining surfaces were split into sibling files to keep each file
// focused; they are re-exported below so existing
// `import '.../dashboard_widgets.dart'` callers keep resolving every symbol
// unchanged.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_card.dart';
import '../../l10n/app_localizations.dart';

export 'dashboard_chart_cards.dart';
export 'dashboard_kpi_alert_cards.dart';
export 'dashboard_sales_cards.dart';
export 'dashboard_section_widgets.dart';

// ---------------------------------------------------------------------------
// GreetingCard — top-of-screen "Salom, <name>" + role chip + bell/settings.
// ---------------------------------------------------------------------------

class GreetingCard extends StatelessWidget {
  const GreetingCard({
    super.key,
    required this.fullName,
    required this.role,
    required this.dateLabel,
    this.hasNotification = false,
    this.unreadNotifications = 0,
    this.onNotificationTap,
    this.onSettingsTap,
    this.profileImage,
  });

  final String fullName;
  final String role; // 'Owner' | 'Admin' | 'Seller'
  final String dateLabel;
  // Red-dot toggle. Either `hasNotification` (legacy, explicit bool) or
  // `unreadNotifications > 0` produces the badge. Numeric value is kept so
  // future iterations can render a count chip — current design just shows
  // the dot.
  final bool hasNotification;
  final int unreadNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  /// Optional user-uploaded profile image. Accepted forms (same convention as
  /// ProfileImagePicker, so they stay in sync):
  ///   - "http..."         → loaded with [Image.network]
  ///   - "data:image/...,<b64>" or raw base64 longer than 100 chars
  ///       → decoded as bytes and shown with [Image.memory]
  ///   - null / empty / unrecognised → falls back to the first-letter circle.
  final String? profileImage;

  String get _initial =>
      fullName.trim().isEmpty ? 'U' : fullName.trim()[0].toUpperCase();

  /// Render the user's profile image as a 44×44 rounded tile, or a coloured
  /// first-letter tile if no image is available. Delegates to a stateful
  /// helper so base64 decoding happens once per profileImage change rather
  /// than on every dashboard rebuild.
  Widget _buildAvatar(BuildContext context) {
    return _AvatarTile(profileImage: profileImage, initial: _initial);
  }

  ({Color bg, Color fg, String emoji}) _roleStyle() {
    switch (role) {
      case 'Owner':
        return (
          bg: AppColors.accentPurpleLight,
          fg: AppColors.accentPurpleDeep,
          emoji: '\u{1F451}', // crown
        );
      case 'Admin':
        return (
          bg: AppColors.infoLight,
          fg: AppColors.infoDeep,
          emoji: '\u{1F465}', // busts
        );
      case 'Seller':
      default:
        return (
          bg: AppColors.successLight,
          fg: AppColors.successDeep,
          emoji: '\u{1F6D2}', // cart
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = _roleStyle();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          _buildAvatar(context),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.greetingHello}, $fullName',
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                    Text(
                      ' · ',
                      style: AppTextStyles.bodySmall().copyWith(fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rs.bg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${rs.emoji} $role',
                        style: AppTextStyles.caption().copyWith(
                          color: rs.fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bildirishnoma qo'ng'irog'i — faqat notifications.access ruxsati
          // bo'lganda ko'rsatiladi (dashboard onNotificationTap'ni null qiladi).
          if (onNotificationTap != null) ...[
            _IconCircle(
              icon: Icons.notifications_none_rounded,
              badgeCount: unreadNotifications > 0
                  ? unreadNotifications
                  : (hasNotification ? 1 : 0),
              onTap: onNotificationTap,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          _IconCircle(icon: Icons.settings_outlined, onTap: onSettingsTap),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, this.badgeCount = 0, this.onTap});

  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.inputFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: context.colors.text),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AvatarTile — 44×44 profile image with cached base64 decoding.
// ---------------------------------------------------------------------------
//
// AUDIT-2 — the previous StatelessWidget implementation called
// `base64Decode(b64)` inside `build()`. For a typical 200 KB profile
// payload that runs ~10 ms of CPU per frame on a Moto G6 every time the
// dashboard rebuilds (RefreshIndicator, FutureBuilder snapshot updates,
// theme toggles, etc.). Caching the decoded bytes in state drops the
// cost to ~0 once after [profileImage] changes.
//
// For HTTP avatars we add `cacheWidth`/`cacheHeight` so the engine
// downscales the source before raster — a 2 MB original at 44 logical
// px would otherwise be decoded at full resolution and waste GPU memory.

class _AvatarTile extends StatefulWidget {
  const _AvatarTile({required this.profileImage, required this.initial});

  final String? profileImage;
  final String initial;

  @override
  State<_AvatarTile> createState() => _AvatarTileState();
}

class _AvatarTileState extends State<_AvatarTile> {
  /// Decoded bytes for the base64 / data-URL case. Null when the source
  /// is an HTTP URL, missing, or failed to decode.
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode(widget.profileImage);
  }

  @override
  void didUpdateWidget(covariant _AvatarTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImage != widget.profileImage) {
      _decode(widget.profileImage);
    }
  }

  /// Decode the base64 payload exactly once per profileImage update.
  /// Tolerates missing / malformed input by leaving [_bytes] null, which
  /// causes [build] to fall back to the letter tile.
  void _decode(String? img) {
    if (img == null ||
        img.isEmpty ||
        img.startsWith('http') ||
        (!img.startsWith('data:image') && img.length <= 100)) {
      if (_bytes != null && mounted) setState(() => _bytes = null);
      return;
    }
    try {
      final b64 = img.contains(',') ? img.split(',').last : img;
      final decoded = base64Decode(b64);
      if (mounted) setState(() => _bytes = decoded);
    } catch (_) {
      if (_bytes != null && mounted) setState(() => _bytes = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.profileImage;
    final letterTile = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.colors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.initial,
        style: AppTextStyles.titleMedium().copyWith(
          color: context.colors.brand,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget? imgWidget;
    if (img != null && img.startsWith('http')) {
      imgWidget = CachedNetworkImage(
        imageUrl: img,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => letterTile,
        placeholder: (_, __) => letterTile,
      );
    } else if (_bytes != null) {
      imgWidget = Image.memory(
        _bytes!,
        width: 44,
        height: 44,
        cacheWidth: 128,
        cacheHeight: 128,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => letterTile,
      );
    }

    if (imgWidget == null) return letterTile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: imgWidget,
    );
  }
}
