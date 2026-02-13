import 'package:flutter/material.dart';

import 'core/app/main_app.dart';
import 'core/utils/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependency Injectionni sozlash
  await setupDependencyInjection();

  runApp(const MainApp());
}
