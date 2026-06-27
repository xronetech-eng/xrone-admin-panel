import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
    : _repository = repository,
      super(const AuthInitial()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);
  }

  final AuthRepository _repository;

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthChecking());

    try {
      final result = await _repository.restoreAdminSession();
      emit(_stateFromResult(result));
    } on Object catch (error) {
      emit(AuthFailure(_messageFromError(error)));
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSubmitting());

    try {
      final result = await _repository.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      emit(_stateFromResult(result));
    } on Object catch (error) {
      emit(AuthFailure(_messageFromError(error)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[Logout] start');

    try {
      await _repository.signOut();
      debugPrint('[Logout] signout:success');
      emit(const AuthUnauthenticated());
      debugPrint('[Logout] auth:cleared');
    } on Object catch (error) {
      debugPrint('[Logout] error=$error');
      emit(AuthFailure(_messageFromError(error)));
    }
  }

  Future<void> _onProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await _repository.loadCurrentAdminProfile();
      emit(
        AuthAuthenticated(
          userId: profile.userId,
          email: profile.email,
          role: profile.role,
          fullName: profile.fullName,
        ),
      );
    } on Object catch (error) {
      emit(AuthFailure(_messageFromError(error)));
    }
  }

  AuthState _stateFromResult(AdminAuthResult result) {
    return switch (result.status) {
      AdminAuthStatus.authenticated => AuthAuthenticated(
        userId: result.userId ?? '',
        email: result.email ?? '',
        role: result.role ?? '',
        fullName: result.fullName ?? '',
      ),
      AdminAuthStatus.accessDenied => const AuthAccessDenied(
        'Access denied. This account is not an admin.',
      ),
      AdminAuthStatus.unauthenticated => const AuthUnauthenticated(),
    };
  }

  String _messageFromError(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }

    return 'Unable to authenticate admin.';
  }
}
