// Seller shift open/close control for the dashboard.
//
// Loads the seller's current shift on mount and renders an open- or
// close-shift action. Self-contained: it manages its own load/open/close
// state so the dashboard doesn't have to thread shift data through.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/services/shift_service.dart';
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_button.dart';
import '../../design/widgets/app_card.dart';
import '../../l10n/app_localizations.dart';

class ShiftControlCard extends StatefulWidget {
  const ShiftControlCard({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<ShiftControlCard> createState() => _ShiftControlCardState();
}

class _ShiftControlCardState extends State<ShiftControlCard> {
  late final ShiftService _service = ShiftService(
    authProvider: widget.authProvider,
  );

  Shift? _shift;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shift = await _service.getCurrentShift();
    if (!mounted) return;
    setState(() {
      _shift = shift;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      // Open when none is running, otherwise close. The close response has
      // isOpen=false, so it collapses back to the "closed" state.
      final result = _shift == null
          ? await _service.openShift()
          : await _service.closeShift();
      if (!mounted) return;
      setState(() => _shift = result.isOpen ? result : null);
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // G4 — branch on the structured error code. The most common case here
      // is `closeShift` on a state where no shift is open (e.g. another
      // tab already closed it, or the local cache was stale). The backend
      // returns 409 + SHIFT_NOT_OPEN; show the dedicated message and
      // reload so the toggle flips back to "open" state.
      if (e.isShiftNotOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shiftNotOpenError),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
        return;
      }
      // Fall through to a generic localized snackbar for every other
      // status / code (rate-limit, market blocked, 5xx, …). We still use
      // the backend's `message` when present because it's already in the
      // user's locale.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.isNotEmpty ? e.message : l10n.errorOccurred),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorOccurred),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const AppCard(
        child: SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Snapshot the nullable field so the "started at" line below can read
    // it without `!` — `isOpen` is just a boolean and doesn't promote
    // `_shift` for Dart's flow analysis.
    final shift = _shift;
    final isOpen = shift != null;
    final accent = isOpen ? AppColors.success : context.colors.textSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isOpen ? Icons.timelapse_rounded : Icons.bedtime_outlined,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? l10n.shiftOpen : l10n.shiftClosed,
                      style: AppTextStyles.titleMedium().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (shift != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.shiftStartedAt(
                          DateFormat('HH:mm').format(shift.openedAt),
                        ),
                        style: AppTextStyles.caption().copyWith(
                          fontSize: 11,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isOpen)
            AppDangerButton(
              label: l10n.closeShift,
              icon: Icons.logout_rounded,
              onPressed: _busy ? null : _toggle,
              isLoading: _busy,
            )
          else
            AppPrimaryButton(
              label: l10n.openShift,
              icon: Icons.play_arrow_rounded,
              onPressed: _busy ? null : _toggle,
              isLoading: _busy,
            ),
        ],
      ),
    );
  }
}
