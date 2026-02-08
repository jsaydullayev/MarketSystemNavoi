import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'data/services/http_service.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final httpService = HttpService();
    final authService = AuthService(httpService: httpService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
      ],
      child: MaterialApp(
        title: 'Market System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
