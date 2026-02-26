import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/extensions/app_extensions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/user_service.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/profile_widgets.dart';
import '../../auth/screens/welcome_screen.dart';

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
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final primaryColor = AppColors.getPrimary(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDark, l10n),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ProfileImagePicker(
                        currentImageUrl: user?['profileImage'],
                        onImageUpdated: (url) =>
                            authProvider.fetchUserProfile(),
                      ),
                      32.height,
                      ProfileSectionTitle(title: l10n.info, isDark: isDark),
                      12.height,
                      ProfileGlassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _buildEditableRow(
                                Icons.alternate_email_rounded,
                                l10n.username,
                                _usernameController,
                                isDark,
                                primaryColor,
                                enabled: false),
                            const Divider(height: 32, thickness: 0.5),
                            _buildEditableRow(
                                Icons.person_outline_rounded,
                                l10n.fullName,
                                _fullNameController,
                                isDark,
                                primaryColor),
                            const Divider(height: 32, thickness: 0.5),
                            ProfileInfoRow(
                                icon: Icons.verified_user_outlined,
                                label: l10n.role,
                                value: user?['role'] ?? 'Seller',
                                isDark: isDark),
                          ],
                        ),
                      ),
                      24.height,
                      ProfileSectionTitle(title: l10n.security, isDark: isDark),
                      12.height,
                      ProfileGlassCard(
                        isDark: isDark,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.lock_reset_rounded,
                              color: primaryColor),
                          title: Text(l10n.changePassword,
                              style:
                                  AppStyles.cardTitle.copyWith(fontSize: 15)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16),
                          onTap: () => _showChangePasswordSheet(
                              context, l10n, primaryColor, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(primaryColor, l10n, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableRow(IconData icon, String label,
      TextEditingController controller, bool isDark, Color primary,
      {bool enabled = true}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black38),
        16.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppStyles.subtitle
                      .copyWith(fontSize: 10, color: Colors.grey)),
              TextField(
                controller: controller,
                enabled: enabled,
                style: AppStyles.cardTitle.copyWith(
                    fontSize: 15, color: enabled ? null : Colors.grey),
                decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
        if (enabled)
          Icon(Icons.edit_rounded, size: 14, color: primary.withOpacity(0.5)),
      ],
    );
  }

  void _showChangePasswordSheet(
      BuildContext context, var l10n, Color primary, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10))),
              24.height,
              Text(l10n.changePassword,
                  style: AppStyles.brandTitle.copyWith(fontSize: 18)),
              24.height,
              _buildDialogField(
                  _currentPasswordController, l10n.currentPassword, isDark),
              16.height,
              _buildDialogField(
                  _newPasswordController, l10n.newPassword, isDark),
              24.height,
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () => _changePassword(setModalState, l10n),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isChangingPassword
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(l10n.confirm,
                          style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword(Function setModalState, var l10n) async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) return;

    setModalState(() => _isChangingPassword = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await UserService(authProvider: auth).updateProfile(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.updateSuccess), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setModalState(() => _isChangingPassword = false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  PreferredSizeWidget _buildAppBar(bool isDark, var l10n) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(l10n.profile,
          style: AppStyles.brandTitle.copyWith(fontSize: 20)),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          onPressed: () => _handleLogout(l10n),
        ),
      ],
    );
  }

  Widget _buildBottomAction(Color primary, var l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: _isSaving
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(l10n.save,
                  style: AppStyles.cardTitle.copyWith(color: Colors.white)),
        ),
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.profileSaved), backgroundColor: Colors.green));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout(var l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.yes, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (r) => false);
    }
  }

  Widget _buildDialogField(
      TextEditingController controller, String label, bool isDark) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
