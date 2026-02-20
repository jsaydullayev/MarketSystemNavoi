import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'core/app/main_app.dart';
import 'core/utils/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencyInjection();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MainApp(savedThemeMode: savedThemeMode));
}
