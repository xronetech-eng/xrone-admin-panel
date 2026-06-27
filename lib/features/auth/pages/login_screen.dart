import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/navigation/navigation_logger.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (context.read<AuthBloc>().state is AuthInitial) {
      context.read<AuthBloc>().add(const AuthSessionRequested());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          NavigationLogger.source(
            'LoginScreen.authenticated',
            action: 'pushReplacementNamed',
            to: AppRoutes.dashboard,
          );
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }

        if (state is AuthAccessDenied) {
          _showMessage(state.message);
        }

        if (state is AuthFailure) {
          _showMessage(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Container(
              width: 460.w,
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withValues(alpha: 0.06),
                    blurRadius: 28.r,
                    offset: Offset(0, 14.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: 250.w,
                      height: 100.h,
                      fit: BoxFit.contain,
                      semanticLabel: 'Xrone',
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Center(
                    child: Text(
                      'Login to continue to dashboard.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _AuthField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: AppSpacing.md),
                  _AuthField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isBusy =
                          state is AuthChecking || state is AuthSubmitting;
                      return SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: FilledButton(
                          onPressed: isBusy ? null : _login,
                          child: const Text('Login'),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        NavigationLogger.source(
                          'LoginScreen.forgotPassword',
                          action: 'pushNamed',
                          to: AppRoutes.authForgotPassword,
                        );
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.authForgotPassword);
                      },
                      child: const Text('Forgot Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter admin email and password.');
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginSubmitted(email: email, password: password),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppColors.primaryBlue),
      ),
    );
  }
}

OutlineInputBorder _border({Color color = AppColors.borderLight}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14.r),
    borderSide: BorderSide(color: color),
  );
}
