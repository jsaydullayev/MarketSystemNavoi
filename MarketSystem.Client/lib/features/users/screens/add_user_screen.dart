import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/users_service.dart';
import '../../../core/providers/auth_provider.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Seller';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Role selection based on current user role
  List<String> _getAvailableRoles() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.user?['role'];

    if (currentUserRole == 'Owner') {
      return ['Seller', 'Admin', 'Owner'];
    } else if (currentUserRole == 'Admin') {
      // Admin faqat Seller va Admin qo'sha oladi (Owner emas!)
      return ['Seller', 'Admin'];
    }

    return ['Seller'];
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usersService = UsersService(authProvider: authProvider);

      final user = await usersService.createUser(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success dialog with credentials
        _showSuccessDialog(user);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        title: const Text('Foydalanuvchi muvaffaqiyatli yaratildi!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ism: ${user['fullName'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Username: ${user['username'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Role: ${user['role'] ?? ''}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Muhim!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu ma\'lumotlarni yangi foydalanuvchiga bering:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Username: ${user['username'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Password: (siz kiritgan password)'),
                  const SizedBox(height: 8),
                  const Text(
                    'U o\'sha ma\'lumotlar bilan tizimga kirishi mumkin.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back to users list
            },
            child: const Text('Tushunarli'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserRole = authProvider.user?['role'];
    final availableRoles = _getAvailableRoles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi foydalanuvchi'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentUserRole == 'Admin'
                          ? 'Admin sifatida siz Seller va Admin qo\'sha olasiz (Owner emas)'
                          : 'Owner sifatida siz hamma rollarni qo\'sha olasiz',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Full Name field
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'To\'liq ism',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'To\'liq ism kiritish shart';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.account_circle),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username kiritish shart';
                }
                if (value.length < 3) {
                  return 'Username kamida 3 ta belgi bo\'lishi kerak';
                }
                if (value.contains(' ')) {
                  return 'Username bo\'sh joy bo\'lmasligi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password kiritish shart';
                }
                if (value.length < 6) {
                  return 'Password kamida 6 ta belgi bo\'lishi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password tasdiqlash',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tasdiqlash shart';
                }
                if (value != _passwordController.text) {
                  return 'Passwordlar mos emas';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              items: availableRoles.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Create button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createUser,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Foydalanuvchi yaratish',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
