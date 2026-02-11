/// Auth Bloc Provider
/// Provides AuthBloc to widget tree
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/events/auth_event.dart';
import '../bloc/states/auth_state.dart';

/// Auth Bloc Provider
class AuthProvider extends BlocProvider<AuthBloc, AuthState> {
  AuthProvider({required super.key})
      : super(
          key: key,
          create: (context) => AuthBloc(
            // Dependencies will be injected via DI later
          ),
        );
}
