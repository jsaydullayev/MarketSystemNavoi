import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/auth/permissions.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/users_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/features/users/screens/user_permissions_screen.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// User detail bottom sheet matching the staff-detail hero card from
/// `id="page-staff-detail"`: 72x72 avatar tile with role-tinted background,
/// full name + `@username`, role + status info rows, and — for Admin/Owner
/// viewing a Seller — a shift-management section (Active / Blocked /
/// Scheduled). The sheet is scroll-controlled so the content never overflows.
class UserInfoSheet extends StatefulWidget {
  final dynamic user;

  /// Called after a successful shift change so the caller can refresh its
  /// user list.
  final VoidCallback? onChanged;

  const UserInfoSheet({super.key, required this.user, this.onChanged});

  static void show(
    BuildContext context, {
    required dynamic user,
    VoidCallback? onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Scroll-controlled so the sheet grows to its content instead of being
      // clipped at the default ~50% cap (the old "BOTTOM OVERFLOWED" bug).
      isScrollControlled: true,
      builder: (_) => UserInfoSheet(user: user, onChanged: onChanged),
    );
  }

  @override
  State<UserInfoSheet> createState() => _UserInfoSheetState();
}

class _UserInfoSheetState extends State<UserInfoSheet> {
  // Mutable copy so a shift change re-renders the sheet without a reload.
  late Map<String, dynamic> _user;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user as Map);
  }

  // Role chip colors (mirror UserCard so chips read consistently).
  static const _adminBg = Color(0xFFF3E8FF);
  static const _adminFg = Color(0xFF7C3AED);
  static const _sellerBg = Color(0xFFECFDF5);
  static const _sellerFg = Color(0xFF047857);

  ({Color bg, Color fg}) _roleColors(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (bg: context.colors.brandLight, fg: context.colors.brandDark);
      case 'admin':
        return (bg: _adminBg, fg: _adminFg);
      case 'seller':
        return (bg: _sellerBg, fg: _sellerFg);
      default:
        return (bg: context.colors.inputFill, fg: context.colors.textSecondary);
    }
  }

  /// Push a shift change to the backend, then refresh local + parent state.
  Future<void> _applyShift(
    String status, {
    DateTime? start,
    DateTime? end,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final updated = await UsersService(authProvider: auth).updateShift(
        id: _user['id'].toString(),
        status: status,
        startUtc: start,
        endUtc: end,
      );
      if (!mounted) return;
      setState(() {
        if (updated is Map) {
          _user = Map<String, dynamic>.from(updated);
        }
        _busy = false;
      });
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shiftUpdated),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Pick a custom [start, end] window via date + time pickers, then apply
  /// it as a Scheduled shift.
  Future<void> _pickWindow() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (startDate == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (startTime == null || !mounted) return;
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final defaultEnd = start.add(const Duration(hours: 8));
    final endDate = await showDatePicker(
      context: context,
      initialDate: defaultEnd,
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
    );
    if (endDate == null || !mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(defaultEnd),
    );
    if (endTime == null || !mounted) return;
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shiftInvalidWindow),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _applyShift('Scheduled', start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = _user['isActive'] ?? false;
    final role = (_user['role'] ?? '').toString();
    final fullName = (_user['fullName'] ?? l10n.unknown).toString();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final colors = _roleColors(context, role);

    // The shift section is shown only when the viewer holds users.shift and
    // the viewed user is a Seller.
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canManageShift = auth.can(Permissions.usersShift);
    final isSellerViewed = role.toLowerCase() == 'seller';
    // Permission management is Owner-only (backend endpoint is OwnerOnly) and
    // only meaningful for the gateable roles — Admin and Seller.
    final roleLower = role.toLowerCase();
    final canManagePermissions =
        auth.role == 'Owner' && (roleLower == 'admin' || roleLower == 'seller');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.lg,
        AppSpacing.xl2,
        AppSpacing.xl4,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2 + 10),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl3),

            // Hero avatar (72x72 tile, role-tinted)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(AppRadius.xl + 4),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.displayMedium().copyWith(
                    color: colors.fg,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Full name
            Text(
              fullName,
              style: AppTextStyles.titleLarge().copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.xs),

            // @username
            Text(
              '@${_user['username'] ?? ''}',
              style: AppTextStyles.bodySmall().copyWith(
                fontSize: 13,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Info rows: role + status
            _InfoTile(
              icon: Icons.badge_rounded,
              label: l10n.role,
              value: role,
              valueColor: colors.fg,
            ),
            _InfoTile(
              icon: Icons.circle,
              label: l10n.status,
              value: isActive ? l10n.active : l10n.inactive,
              valueColor: isActive ? AppColors.success : AppColors.danger,
            ),

            // Shift management — Admin/Owner only, for Sellers.
            if (canManageShift && isSellerViewed) ...[
              const SizedBox(height: AppSpacing.lg),
              _ShiftSection(
                user: _user,
                busy: _busy,
                onActivate: () => _applyShift('Active'),
                onBlock: () => _applyShift('Blocked'),
                onOpen24h: () {
                  final now = DateTime.now();
                  _applyShift(
                    'Scheduled',
                    start: now,
                    end: now.add(const Duration(hours: 24)),
                  );
                },
                onSetWindow: _pickWindow,
              ),
            ],
            // Owner → fine-grained permission matrix for this user.
            if (canManagePermissions) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSecondaryButton(
                label: l10n.managePermissions,
                icon: Icons.shield_outlined,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserPermissionsScreen(
                      userId: (_user['id'] ?? '').toString(),
                      userName: (_user['fullName'] ?? '').toString(),
                      userRole: role,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            AppPrimaryButton(
              label: l10n.closed,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.textMuted),
          const SizedBox(width: AppSpacing.md + 2),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shift-management block: current state card + 4 action buttons. Shown only
/// to Admin/Owner viewing a Seller.
class _ShiftSection extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool busy;
  final VoidCallback onActivate;
  final VoidCallback onBlock;
  final VoidCallback onOpen24h;
  final VoidCallback onSetWindow;

  const _ShiftSection({
    required this.user,
    required this.busy,
    required this.onActivate,
    required this.onBlock,
    required this.onOpen24h,
    required this.onSetWindow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = (user['shiftStatus'] ?? 'Active').toString();
    final isActiveNow = user['isShiftActive'] == true;

    final Color stateColor;
    final String stateLabel;
    switch (status.toLowerCase()) {
      case 'blocked':
        stateColor = AppColors.danger;
        stateLabel = l10n.shiftStateBlocked;
        break;
      case 'scheduled':
        stateColor = AppColors.warning;
        stateLabel = l10n.shiftStateScheduled;
        break;
      default:
        stateColor = AppColors.success;
        stateLabel = l10n.shiftStateActive;
    }

    // Scheduled window, formatted in local time.
    String? windowText;
    if (status.toLowerCase() == 'scheduled') {
      final s = _parseLocal(user['shiftStartUtc']);
      final e = _parseLocal(user['shiftEndUtc']);
      if (s != null && e != null) {
        final fmt = DateFormat('dd MMM · HH:mm');
        windowText = '${fmt.format(s)}  —  ${fmt.format(e)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: context.colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.shiftSection.toUpperCase(),
              style: AppTextStyles.caption().copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Current-state card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: stateColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            border: Border.all(color: stateColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActiveNow
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 18,
                    color: stateColor,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      stateLabel,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w700,
                        color: stateColor,
                      ),
                    ),
                  ),
                  Text(
                    isActiveNow ? l10n.shiftActiveNow : l10n.shiftInactiveNow,
                    style: AppTextStyles.caption().copyWith(
                      color: stateColor,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              if (windowText != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    windowText,
                    style: AppTextStyles.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Action buttons (2x2). A spinner replaces them while a call is live.
        if (busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _ShiftActionButton(
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.shiftActivate,
                  color: AppColors.success,
                  onTap: onActivate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ShiftActionButton(
                  icon: Icons.block_rounded,
                  label: l10n.shiftBlock,
                  color: AppColors.danger,
                  onTap: onBlock,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShiftActionButton(
                  icon: Icons.timelapse_rounded,
                  label: l10n.shiftOpen24h,
                  color: context.colors.brand,
                  onTap: onOpen24h,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ShiftActionButton(
                  icon: Icons.date_range_rounded,
                  label: l10n.shiftSetWindow,
                  color: context.colors.brand,
                  onTap: onSetWindow,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static DateTime? _parseLocal(dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    return dt?.toLocal();
  }
}

class _ShiftActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShiftActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg - 1,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall().copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
