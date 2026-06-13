import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/data/services/shift_service.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

/// Read-only bottom sheet listing a seller's worked-shift sessions (open/close
/// times + duration), most recent first. Opened from the user-detail shift
/// section so an Owner/Admin can review how long the seller actually worked.
///
/// The backend gates `/Shifts/user/{id}` on `users.shift`, and the service
/// degrades to an empty list on any error — so this sheet only ever shows a
/// spinner, the rows, or a friendly empty state, never an exception.
class ShiftHistorySheet extends StatefulWidget {
  final String userId;
  final String userName;

  const ShiftHistorySheet({
    super.key,
    required this.userId,
    required this.userName,
  });

  static void show(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShiftHistorySheet(userId: userId, userName: userName),
    );
  }

  @override
  State<ShiftHistorySheet> createState() => _ShiftHistorySheetState();
}

class _ShiftHistorySheetState extends State<ShiftHistorySheet> {
  late final Future<List<Shift>> _future;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _future = ShiftService(authProvider: auth).getUserShifts(widget.userId);
  }

  String _duration(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '$h ${l10n.hour} $m ${l10n.minuteShort}';
    if (h > 0) return '$h ${l10n.hour}';
    return '$m ${l10n.minuteShort}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.lg,
        AppSpacing.xl2,
        AppSpacing.xl3,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2 + 10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: AppSpacing.xl2),
          Text(
            l10n.workedShifts,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            widget.userName,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall().copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: FutureBuilder<List<Shift>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl3),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final shifts = snap.data ?? const <Shift>[];
                if (shifts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl3),
                    child: Text(
                      l10n.workedShiftsEmpty,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _ShiftHistoryRow(
                    shift: shifts[i],
                    durationText: _duration(l10n, shifts[i].durationMinutes),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: l10n.closed,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ShiftHistoryRow extends StatelessWidget {
  final Shift shift;
  final String durationText;

  const _ShiftHistoryRow({required this.shift, required this.durationText});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd MMM');
    final timeFmt = DateFormat('HH:mm');
    final opened = timeFmt.format(shift.openedAt);
    final closed = shift.closedAt == null
        ? l10n.shiftStillOpen
        : timeFmt.format(shift.closedAt!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: shift.isOpen
            ? Border.all(color: AppColors.success.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            shift.isOpen
                ? Icons.timelapse_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: shift.isOpen ? AppColors.success : context.colors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(shift.openedAt),
                  style: AppTextStyles.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$opened – $closed',
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            durationText,
            style: AppTextStyles.labelSmall().copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.brand,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
