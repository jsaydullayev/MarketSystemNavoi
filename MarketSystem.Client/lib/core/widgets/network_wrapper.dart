import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const NetworkWrapper({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _isConnected = true;
  late StreamSubscription _subscription; // ✅ declare qilindi

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
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

  Future<void> _checkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasNetwork = result != ConnectivityResult.none;

      if (hasNetwork) {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        final connected = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        if (mounted) setState(() => _isConnected = connected);
      } else {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Internet yo\'q',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Internet aloqasini tekshiring va qayta urinib ko\'ring',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await _checkConnection();
                  if (_isConnected) {
                    widget.onRetry?.call();
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Qayta urinish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
