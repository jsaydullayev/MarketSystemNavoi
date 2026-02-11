/// Auth Screen Placeholder
/// Base auth screen for login/register
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../bloc/auth_provider.dart';

/// Auth Screen Placeholder
class AuthScreenPlaceholder extends StatelessWidget {
  const AuthScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName),
      ),
      body: BlocProvider(
        create: (_) => AuthProvider(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Auth feature is ready! 🎯'),
            ],
          ),
        ),
      ),
    );
  }
}
