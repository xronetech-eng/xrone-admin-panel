import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/navigation_logger.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../bloc/auth_bloc.dart';
import '../pages/login_screen.dart';

class AdminGuard extends StatefulWidget {
  const AdminGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  String? _lastLoggedState;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthInitial || state is AuthUnauthenticated) {
      NavigationLogger.source(
        'AdminGuard',
        action: 'request-session-check',
        to: state.runtimeType.toString(),
      );
      context.read<AuthBloc>().add(const AuthSessionRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        _logState(state);

        if (state is AuthChecking || state is AuthInitial) {
          return const Scaffold(
            body: LoadingState(message: 'Checking admin session'),
          );
        }

        if (state is AuthAuthenticated) {
          return widget.child;
        }

        if (state is AuthAccessDenied) {
          return const Scaffold(
            body: EmptyState(
              title: 'Access denied',
              message: 'This account is not authorized for the admin panel.',
            ),
          );
        }

        return const LoginScreen();
      },
    );
  }

  void _logState(AuthState state) {
    final stateName = state.runtimeType.toString();
    if (_lastLoggedState == stateName) {
      return;
    }

    _lastLoggedState = stateName;
    NavigationLogger.source(
      'AdminGuard',
      action: 'render-auth-state',
      to: stateName,
    );
  }
}
