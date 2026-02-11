/// Auth Bloc Provider
/// Provides AuthBloc to widget tree

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

/// Auth Bloc Provider
class AuthProvider extends BlocProvider<AuthBloc> {
  AuthProvider({Key? key})
      : super(
          key: key,
          create: (_) => AuthBloc(),
        );
}
