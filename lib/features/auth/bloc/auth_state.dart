part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.role,
    required this.fullName,
  });

  final String userId;
  final String email;
  final String role;
  final String fullName;

  @override
  List<Object?> get props => [userId, email, role, fullName];
}

final class AuthAccessDenied extends AuthState {
  const AuthAccessDenied(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
