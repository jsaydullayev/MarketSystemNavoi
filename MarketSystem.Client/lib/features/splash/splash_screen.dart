import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/providers/auth_provider.dart';
import 'package:market_system_client/core/constants/public_routes.dart';
import 'package:market_system_client/core/managers/route_state_manager.dart';
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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  /// Initialize app state and navigate to appropriate screen
  /// This is now purely UI-driven, no auto-redirect logic from public routes
  Future<void> _initializeAndNavigate() async {
    // Prevent multiple navigations
    if (_isNavigating) return;
    _isNavigating = true;

    // CRITICAL: Check if we should skip auto-navigation
    // /privacy and other public routes should stay where they are
    // /splash should check auth and redirect
    final currentRoute = RouteStateManager.instance.currentRoute ?? '';
    final shouldSkipAutoNav = PublicRoutes.shouldSkipAutoNavigation(currentRoute);

    if (shouldSkipAutoNav) {
      debugPrint('🛑 Splash: Route should skip auto-navigation: $currentRoute');
      return;
    }

    // Small delay for splash screen effect
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Initialize auth state
    final authService = di.sl<AuthService>();
    final prefs = await SharedPreferences.getInstance();

    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;
    final bool isAuth = await authService.isAuthenticated();

    // Load user data if authenticated
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

    // Determine next screen
    Widget nextScreen;
    if (isFirstTime) {
      nextScreen = const WelcomeScreen();
    } else {
      nextScreen = isAuth ? const DashboardScreen() : const LoginScreen();
    }

    // Navigate
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
