import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../../design/tokens/app_theme_colors.dart';
import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/widgets/app_button.dart';
import '../../l10n/app_localizations.dart';
import '../constants/api_constants.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const NetworkWrapper({super.key, required this.child, this.onRetry});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _isConnected = true;
  late StreamSubscription _subscription; // ✅ declare qilindi

  // Throttle the /health probe across ALL NetworkWrapper mounts. Every wrapped
  // screen (dashboard, products, sales, reports, …) used to fire a fresh
  // /health GET on navigation, racing a round-trip against the screen's real
  // data fetch. Caching the last result for a short TTL makes navigation reuse
  // it. Device connectivity changes still update instantly via the stream
  // below (no network cost).
  static DateTime? _lastProbe;
  static bool _lastReachable = true;
  static const Duration _probeTtl = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Paint immediately from the cached probe; only re-probe if it's stale.
    _isConnected = _lastReachable;
    _checkConnection();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      final connected = result != ConnectivityResult.none;
      setState(() => _isConnected = connected);
      if (connected) widget.onRetry?.call();
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // ✅ memory leak yo'q
    super.dispose();
  }

  Future<void> _checkConnection({bool force = false}) async {
    // Reuse a recent probe (from any wrapped screen) so navigation doesn't fire
    // a fresh /health GET every time. `force: true` (Retry button) bypasses it.
    final last = _lastProbe;
    if (!force && last != null && DateTime.now().difference(last) < _probeTtl) {
      if (mounted) setState(() => _isConnected = _lastReachable);
      return;
    }
    try {
      final result = await Connectivity().checkConnectivity();
      final hasNetwork = result != ConnectivityResult.none;

      if (hasNetwork) {
        // API serverga test qilamiz - /health endpoint'ini ishlatamiz
        try {
          final healthUrl = ApiConstants.baseUrl == '/api'
              ? '/health' // Production: relative URL
              : '${ApiConstants.baseUrl}/health'; // Dev: full URL
          final response = await http
              .get(Uri.parse(healthUrl))
              .timeout(const Duration(seconds: 5)); // 5 sekund timeout
          // 200, 401, 403, 404 - bularning barchasi server ishlayapti degani
          final apiConnected =
              response.statusCode >= 200 && response.statusCode < 500;

          _lastProbe = DateTime.now();
          _lastReachable = apiConnected;
          if (mounted) setState(() => _isConnected = apiConnected);
        } catch (apiError) {
          // API serverga ulana olmasa, lekin internet bor deb hisoblaymiz
          // Chunki server vaqtncha javob bermashi mumkin
          _lastProbe = DateTime.now();
          _lastReachable = true;
          if (mounted) setState(() => _isConnected = true);
        }
      } else {
        _lastProbe = DateTime.now();
        _lastReachable = false;
        if (mounted) setState(() => _isConnected = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) return widget.child;
    return _buildNoInternet();
  }

  Widget _buildNoInternet() {
    // D2 — replace the hardcoded #1A1A2E / #F5F5F5 / Colors.red / Colors.blue
    // palette with the design-system tokens so this screen tracks the active
    // theme correctly and matches every other "we couldn't load" surface
    // (ErrorRetryView, dashboard _RetryBanner, etc.).
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                l10n.noInternetTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge().copyWith(
                  color: context.colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.noInternetDescription,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall().copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              AppPrimaryButton(
                label: l10n.retry,
                icon: Icons.refresh_rounded,
                onPressed: () async {
                  await _checkConnection(force: true);
                  if (_isConnected) {
                    widget.onRetry?.call();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
