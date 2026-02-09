import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/user_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/screens/welcome_screen.dart';
import '../widgets/profile_image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      setState(() {
        _fullNameController.text = user['fullName'] ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, ismni kiriting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userService = UserService(authProvider: authProvider);

      await userService.updateProfile(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        currentPassword: _currentPasswordController.text.trim().isEmpty ? null : _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim().isEmpty ? null : _newPasswordController.text.trim(),
      );

      // Refresh auth provider data
      await authProvider.fetchUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil muvaffaqiyatli yangilandi!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearPasswordFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tizimdan chiqish'),
                  content: const Text('Rostdan ham tizimdan chiqmoqchimisiz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Yo\'q'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ha', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image Section
                  Center(
                    child: ProfileImagePicker(
                      currentImageUrl: user?['profileImage'],
                      onImageUpdated: (newImageUrl) {
                        // Image updated, refresh user data
                        authProvider.fetchUserProfile();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foydalanuvchi ma\'lumotlari',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Username (read-only)
                          TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Foydalanuvchi nomi',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            controller: TextEditingController(text: user?['username'] ?? ''),
                          ),
                          const SizedBox(height: 16),

                          // Full Name (editable)
                          TextField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'To\'liq ism',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Role (read-only)
                          TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              prefixIcon: const Icon(Icons.admin_panel_settings),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            controller: TextEditingController(text: user?['role'] ?? 'Seller'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Change Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parolni o\'zgartirish',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Parolni o\'zgartirish uchun hozirgi parolni kiriting',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Hozirgi parol',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Yangi parol',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Toggle Card
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Card(
                        elevation: 2,
                        child: SwitchListTile(
                          title: const Text(
                            'Qorong\'i rejim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            themeProvider.isDarkMode ? 'Qorong\'i tema yoqilgan' : 'Yorqin tema yoqilgan',
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: themeProvider.isDarkMode ? Colors.purple : Colors.amber,
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.setTheme(value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 20),
                      label: Text(_isSaving ? 'Saqlanmoqda...' : 'Saqlash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
