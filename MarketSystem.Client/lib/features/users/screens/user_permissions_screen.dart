import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/common_app_bar.dart';
import '../../../core/widgets/network_wrapper.dart';
import '../../../data/services/user_service.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_button.dart';
import '../../../design/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';
import '../permissions/permission_catalog.dart';

/// Owner-only screen: toggle one user's fine-grained permissions.
///
/// Loads the user's effective set + role defaults from the backend, lets the
/// Owner flip individual switches, and saves the explicit set back. "Reset to
/// default" clears the customisation (sends an empty list server-side).
class UserPermissionsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const UserPermissionsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  late final UserService _userService;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// Currently selected permission keys (the working copy the switches edit).
  final Set<String> _selected = {};

  /// Role default set — used by "Reset to default".
  List<String> _roleDefaults = const [];

  /// True when the backend already has an explicit (customised) set saved.
  bool _isCustomized = false;

  @override
  void initState() {
    super.initState();
    _userService = UserService(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _userService.getUserPermissions(widget.userId);
      final effective =
          (data['effectivePermissions'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [];
      _roleDefaults =
          (data['roleDefaults'] as List?)?.whereType<String>().toList() ??
          const [];
      _isCustomized = data['isCustomized'] == true;
      _selected
        ..clear()
        ..addAll(effective);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _userService.updateUserPermissions(
        widget.userId,
        _selected.toList(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isCustomized = true;
      });
      _snack(l10n.permissionsSaved, isError: false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('${l10n.error}: $e', isError: true);
    }
  }

  void _resetToDefault() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_roleDefaults);
    });
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return NetworkWrapper(
      onRetry: _load,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: CommonAppBar(title: l10n.permissionsTitle),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError(context, l10n)
            : _buildBody(context, l10n, lang),
        bottomNavigationBar: _loading || _error != null
            ? null
            : _buildSaveBar(context, l10n),
      ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        '${l10n.error}: $_error',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium(),
      ),
    ),
  );

  Widget _buildBody(BuildContext context, AppLocalizations l10n, String lang) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl4,
      ),
      children: [
        _buildHeader(context, l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildNote(context, l10n),
        const SizedBox(height: AppSpacing.lg),
        for (final group in permissionGroups) ...[
          _buildGroup(context, group, lang),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: AppTextStyles.bodyLarge().copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.userRole} · '
                  '${_isCustomized ? l10n.permissionsCustomized : l10n.permissionsUsingRoleDefaults}',
                  style: AppTextStyles.caption().copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resetToDefault,
            child: Text(l10n.resetToDefault),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.permissionsNextLoginNote,
              style: AppTextStyles.caption().copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, PermissionGroup group, String lang) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xs,
            ),
            child: Text(
              group.title(lang).toUpperCase(),
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          for (final entry in group.entries)
            SwitchListTile(
              value: _selected.contains(entry.key),
              onChanged: (on) => setState(() {
                if (on) {
                  _selected.add(entry.key);
                } else {
                  _selected.remove(entry.key);
                }
              }),
              title: Text(entry.label(lang), style: AppTextStyles.bodyMedium()),
              activeTrackColor: context.colors.brand,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppPrimaryButton(
          label: l10n.save,
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }
}
