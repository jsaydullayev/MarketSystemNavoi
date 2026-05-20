// Auth Bloc Provider
// Provides AuthBloc to widget tree

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

/// Auth Bloc Provider
class AuthProvider extends BlocProvider<AuthBloc> {
  AuthProvider({super.key})
      : super(
          create: (_) => AuthBloc(),
        );
}
