// Splash screen — initial loading screen with auth-state check. Uses the new
// design system tokens while preserving all routing logic: optimistic restore,
// first-time visitor → Welcome, SuperAdmin → console, default → Dashboard.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/public_routes.dart';
import '../../core/managers/route_state_manager.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/network_wrapper.dart';
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../auth/presentation/screens/welcome_screen.dart';
import '../dashboard/dashboard_screen.dart';

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

  /// Initialize app state and navigate to the appropriate screen.
  /// This is purely UI-driven; no auto-redirect logic from public routes.
  Future<void> _initializeAndNavigate() async {
    // Prevent multiple navigations.
    if (_isNavigating) return;
    _isNavigating = true;

    // /privacy and other public routes should stay where they are.
    // /splash should check auth and redirect.
    final currentRoute = RouteStateManager.instance.currentRoute ?? '';
    final shouldSkipAutoNav = PublicRoutes.shouldSkipAutoNavigation(
      currentRoute,
    );

    if (shouldSkipAutoNav) {
      debugPrint('🛑 Splash: Route should skip auto-navigation: $currentRoute');
      return;
    }

    // Brief splash visibility before navigating away.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Initialize auth state.
    //
    // Optimistic restore: if a token + cached role exist in shared_preferences
    // we treat the session as authenticated and navigate to the role's home
    // screen IMMEDIATELY, without a backend round-trip. If the token turns out
    // to be expired, the next API call will get a 401 and http_service will
    // transparently refresh — or, if refresh also fails, the user lands back
    // on the login screen on demand. This keeps Flutter hot restart instant
    // (no network wait) and survives transient backend outages.
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;
    final accessToken = prefs.getString('access_token');
    final cachedRole = prefs.getString('user_role');
    final hasSession =
        (accessToken != null && accessToken.isNotEmpty) &&
        (cachedRole != null && cachedRole.isNotEmpty);

    if (hasSession && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUserFromStorage({
        'role': cachedRole,
        'fullName': prefs.getString('user_full_name'),
        'username': prefs.getString('user_username'),
      });
      // SharedPreferences only stores role/fullName/username — the profile
      // image lives only on the server. Pull the full profile so the avatar
      // doesn't vanish on browser refresh. Runs in background; if it 401s,
      // the global handler will refresh or redirect as needed.
      // ignore: unawaited_futures
      authProvider.fetchUserProfile();
    }

    if (!mounted) return;
    final bool isAuth = hasSession;

    // Determine next screen.
    //   - First-time visitor → welcome (locale/theme selector).
    //   - Unauthenticated → login.
    //   - SuperAdmin → hidden console (Owner Dashboard is meaningless for a
    //     cross-tenant account, so dropping them there showed empty/error
    //     widgets and an irrelevant side drawer).
    //   - Everyone else → Owner/Seller Dashboard.
    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }
    if (!isAuth) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    // isAuth = true — branch on cached role.
    final role = prefs.getString('user_role');
    if (role == 'SuperAdmin') {
      Navigator.pushReplacementNamed(context, AppRoutes.superAdminConsole);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // D2 — wrap so the very first frame on a cold boot without internet
    // shows the localized no-internet panel instead of a spinner that
    // never resolves. onRetry re-runs the auth-restore + navigation
    // flow so the splash recovers automatically when the connection
    // comes back.
    return NetworkWrapper(
      onRetry: () {
        _isNavigating = false;
        _initializeAndNavigate();
      },
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DecoratedBox(
          // Same gradient as the auth screens for a consistent first impression.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [context.colors.surface, context.colors.brandLight],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Existing orange logo asset (kept per user preference).
                  Image.asset(
                    'assets/images/orangeLogo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.xl3),
                  Text(
                    'Strotech',
                    style: AppTextStyles.displayLarge().copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: context.colors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Kichik do'konlar uchun savdo tizimi",
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl4),
                  // Subtle loading indicator below the brand block.
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.colors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
