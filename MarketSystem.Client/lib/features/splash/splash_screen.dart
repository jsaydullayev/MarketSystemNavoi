import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/core/routes/app_routes.dart';
import 'package:market_system_client/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:market_system_client/features/auth/screens/welcome_screen.dart';
import 'package:market_system_client/screens/dashboard_screen.dart';
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
    await Future.delayed(const Duration(milliseconds: 1500));

    final authRepo = di.sl<AuthRepositoryInterface>();
    final bool isAuth = await authRepo.isAuthenticated();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuth ? const DashboardScreen() : const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color.fromARGB(255, 5, 9, 30) : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: const AlwaysStoppedAnimation(1.0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              // decoration: BoxDecoration(
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black.withOpacity(0.05),
              //       blurRadius: 20,
              //       offset: const Offset(0, 10),
              //     ),
              //   ],
              // ),
              child: Image.asset(
                isDark ? 'assets/images/blue.png' : 'assets/images/splash.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
