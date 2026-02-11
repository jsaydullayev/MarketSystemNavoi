/// Dependency Injection Setup
/// Centralized service locator using get_it
library;

import 'package:get_it/get_it.dart';

import '../handlers/auth_handler.dart';
import '../handlers/navigation_handler.dart';
import '../handlers/network_handler.dart';
import '../handlers/storage_handler.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Dependency Injection setup
/// Call this in main.dart before runApp
Future<void> setupDependencyInjection() async {
  await _initCore();
}

/// Initialize core services
Future<void> _initCore() async {
  // Handlers - registered as singletons
  sl.registerLazySingleton<AuthHandler>(() => AuthHandler());
  sl.registerLazySingleton<StorageHandler>(() => StorageHandler());
  sl.registerLazySingleton<NetworkHandler>(
    () => NetworkHandler(
      baseUrl: 'http://localhost:5000/api', // TODO: Move to config
    ),
  );

  // Navigation handler is stateless, just register the type
  sl.registerLazySingleton(() => NavigationHandler());
}

/// Reset all registered services (for testing)
Future<void> resetDependencyInjection() async {
  await sl.reset();
}
