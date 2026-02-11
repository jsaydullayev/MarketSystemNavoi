/// Auth Bloc
/// State management for authentication using BLoC pattern

import 'package:flutter_bloc/flutter_bloc.dart';

import 'events/auth_event.dart';
import 'states/auth_state.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../../../core/handlers/auth_handler.dart';
import '../../../../core/utils/di.dart' as di;

/// Auth Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthHandler _authHandler;

  AuthBloc()
      : _loginUseCase = di.sl<LoginUseCase>(),
        _registerUseCase = di.sl<RegisterUseCase>(),
        _authHandler = di.sl<AuthHandler>(),
        super(const AuthInitialState()) {
    // Register event handlers
    on<AppStartedEvent>(_onAppStarted);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
  }

  /// App started - check auth status
  Future<void> _onAppStarted(
    AppStartedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final isAuthenticated = await _authHandler.isAuthenticated();

    if (isAuthenticated) {
      emit(const AuthAuthenticatedState());
    } else {
      emit(const AuthUnauthenticatedState());
    }
  }

  /// Handle login event
  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final result = await _loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    if (result.isSuccess) {
      emit(const AuthAuthenticatedState());
    } else {
      emit(AuthErrorState(result.error ?? 'Login failed'));
    }
  }

  /// Handle register event
  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    final result = await _registerUseCase(
      RegisterParams(
        userName: event.userName,
        email: event.email,
        password: event.password,
      ),
    );

    if (result.isSuccess) {
      emit(const AuthAuthenticatedState());
    } else {
      emit(AuthErrorState(result.error ?? 'Registration failed'));
    }
  }

  /// Handle logout event
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());

    await _authHandler.clearAuth();

    emit(const AuthUnauthenticatedState());
  }
}
