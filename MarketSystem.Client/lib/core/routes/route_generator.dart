/// Route Generator
/// Generates routes for navigation (simplified - no imports)
library;

import 'package:flutter/material.dart';

import 'app_routes.dart';

/// Generate route (temporary - without screen imports)
Route<dynamic> generateRoute(RouteSettings settings) {
  // TODO: Feature modules will be implemented here
  // For now, just return empty route
  return MaterialPageRoute(
    builder: (_) => const Scaffold(
      body: Center(
        child: Text('Routes will be implemented here'),
      ),
    ),
    settings: settings,
  );
}
