import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/utils/route_helper.dart';
import 'package:market_system_client/data/services/auth_service.dart';
import 'package:market_system_client/features/auth/presentation/screens/login_screen.dart';
import 'package:market_system_client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:market_system_client/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/di.dart' as di;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // CRITICAL: Check current route BEFORE async delay
    // This prevents the BuildContext across async gap warning
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final shouldSkipRedirect = isPublicRoute(currentRoute);

    if (shouldSkipRedirect) {
      debugPrint('🛑 Splash: Skipping auto-redirect - current route is public: $currentRoute');
      return;
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    final authService = di.sl<AuthService>();
    final bool isAuth = await authService.isAuthenticated();

    if (isAuth && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = prefs.getString('user_role');
      final fullName = prefs.getString('user_full_name');
      final username = prefs.getString('user_username');

      if (role != null) {
        authProvider.setUserFromStorage({
          'role': role,
          'fullName': fullName,
          'username': username,
        });
      }
    }

    if (!mounted) return;

    Widget nextScreen;
    if (isFirstTime) {
      nextScreen = const WelcomeScreen();
    } else {
      nextScreen = isAuth ? const DashboardScreen() : const LoginScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: Center(
        child: FadeTransition(
          opacity: const AlwaysStoppedAnimation(1.0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              isDark ? 'assets/images/blue.png' : 'assets/images/splash.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
