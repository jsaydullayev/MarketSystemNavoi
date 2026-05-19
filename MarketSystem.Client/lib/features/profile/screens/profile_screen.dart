// lib/features/profile/screens/profile_screen.dart
//
// Profile + Settings screen mapped to demo `id="page-sett-hub"`:
// - Settings-profile top card (48x48 brand-light circle + greeting + role)
// - Profile avatar picker (camera/gallery via [ProfileImagePicker])
// - Grouped settings sections (DO'KON / SOZLASH / QO'LLAB-QUVVATLASH / etc.)
// - Editable info card (username / fullName / role)
// - Change-password row opening a bottom-sheet flow
// - Theme toggle (AdaptiveTheme) and language switcher (LocaleProvider)
// - Tizimdan chiqish (logout) danger row at the bottom
//
// All business logic (auth provider, user service, image upload, snackbars,
// preferences) is preserved exactly as before.

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/common_app_bar.dart';
import '../../../data/services/user_service.dart';
import '../../../design/tokens/app_tokens.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/widgets/app_button.dart';
import '../../../design/widgets/app_text_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user['fullName'] ?? '';
      _usernameController.text = user['username'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: CommonAppBar(title: l10n.profile),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar picker (camera/gallery).
                      ProfileImagePicker(
                        currentImageUrl: user?['profileImage'],
                        onImageUpdated: (url) async {
                          if (user?['profileImage'] != null) {
                            await NetworkImage(user!['profileImage']).evict();
                          }
                          await authProvider.fetchUserProfile();
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Settings-profile top card.
                      ProfileTopCard(
                        fullName: user?['fullName'],
                        role: user?['role'],
                        marketName: user?['marketName'],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // MA'LUMOT (Info) — editable + read-only fields.
                      ProfileSettingsCard(
                        header: ProfileSectionTitle(title: l10n.info),
                        children: [
                          ProfileEditableField(
                            icon: Icons.lock_outline_rounded,
                            label: l10n.username,
                            controller: _usernameController,
                            enabled: false,
                          ),
                          ProfileEditableField(
                            icon: Icons.edit_rounded,
                            label: l10n.fullName,
                            controller: _fullNameController,
                          ),
                          ProfileInfoRow(
                            icon: Icons.verified_user_outlined,
                            label: l10n.role,
                            value: user?['role'] ?? 'Seller',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // XAVFSIZLIK (Security) — change password.
                      ProfileSettingsCard(
                        header: ProfileSectionTitle(title: l10n.security),
                        children: [
                          ProfileSettingsRow(
                            icon: Icons.lock_reset_rounded,
                            tone: ProfileRowIconTone.purple,
                            title: l10n.changePassword,
                            meta: l10n.changePasswordHint,
                            onTap: () =>
                                _showChangePasswordSheet(context, l10n),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // SOZLASH / НАСТРОЙКИ — language + theme.
                      ProfileSettingsCard(
                        header: ProfileSectionTitle(title: l10n.settingsSection),
                        children: [
                          _buildLanguageRow(context),
                          _buildThemeRow(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Tizimdan chiqish — danger row.
                      ProfileSettingsCard(
                        children: [
                          ProfileSettingsRow(
                            icon: Icons.logout_rounded,
                            tone: ProfileRowIconTone.red,
                            title: l10n.logout,
                            danger: true,
                            onTap: () => _handleLogout(l10n),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Settings rows: language + theme
  // ─────────────────────────────────────────────────────────────────────────

  String _languageLabel(String code) {
    switch (code) {
      case 'uz':
        return "O'zbekcha";
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  Widget _buildLanguageRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final code = localeProvider.locale.languageCode;
    return ProfileSettingsRow(
      icon: Icons.language_rounded,
      tone: ProfileRowIconTone.green,
      title: l10n.languageLabel,
      value: _languageLabel(code),
      onTap: () => _showLanguageSheet(context),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final localeProvider =
        Provider.of<LocaleProvider>(context, listen: false);
    final current = localeProvider.locale.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppLocalizations.of(context)!.languageLabel,
                style: AppTextStyles.titleMedium(),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final entry in const [
                ('uz', "O'zbekcha"),
                ('ru', 'Русский'),
                ('en', 'English'),
              ])
                _LanguageOption(
                  code: entry.$1,
                  label: entry.$2,
                  selected: current == entry.$1,
                  onTap: () => Navigator.pop(ctx, entry.$1),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await localeProvider.setLocale(selected);
    }
  }

  Widget _buildThemeRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mode = AdaptiveTheme.of(context).mode;
    return ProfileSettingsRow(
      icon: Icons.palette_outlined,
      tone: ProfileRowIconTone.gray,
      title: l10n.themeLabel,
      value: mode.isDark ? l10n.themeDark : l10n.themeLight,
      onTap: () {
        AdaptiveTheme.of(context).toggleThemeMode();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Change password bottom sheet (logic preserved from previous version)
  // ─────────────────────────────────────────────────────────────────────────

  void _showChangePasswordSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl3,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.changePassword,
                  style: AppTextStyles.titleMedium(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextInput(
                  label: l10n.currentPassword,
                  controller: _currentPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextInput(
                  label: l10n.newPassword,
                  controller: _newPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_rounded,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: l10n.confirm,
                  isLoading: _isChangingPassword,
                  onPressed: _isChangingPassword
                      ? null
                      : () => _changePassword(setModalState, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword(
      void Function(void Function()) setModalState, AppLocalizations l10n) async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      return;
    }

    setModalState(() => _isChangingPassword = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await UserService(authProvider: auth).updateProfile(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setModalState(() => _isChangingPassword = false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom save bar + profile save
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomAction(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: AppPrimaryButton(
        label: l10n.save,
        isLoading: _isSaving,
        onPressed: _isSaving ? null : _updateProfile,
      ),
    );
  }

  Future<void> _updateProfile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await UserService(authProvider: auth)
          .updateProfile(fullName: _fullNameController.text.trim());
      await auth.fetchUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleLogout(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(l10n.logout, style: AppTextStyles.titleMedium()),
        content: Text(
          l10n.logoutConfirm,
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.no,
              style: AppTextStyles.labelLarge()
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.yes,
              style:
                  AppTextStyles.labelLarge().copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false);
    }
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected ? AppColors.brandLight : AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brand : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    code.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.brandDark : AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.brand,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
