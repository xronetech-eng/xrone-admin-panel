import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/navigation/navigation_logger.dart';
import '../repository/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isSending = false;
  String? _message;
  bool _hasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Text('Forgot Password', style: AppTextStyles.headingLarge),
                SizedBox(height: 8.h),
                Text(
                  'Enter email to receive reset link.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(color: AppColors.primaryBlue),
                  ),
                ),
                if (_message != null) ...[
                  SizedBox(height: AppSpacing.md),
                  Text(
                    _message!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _hasError
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: FilledButton(
                    onPressed: _isSending ? null : _sendResetLink,
                    child: const Text('Send Reset Link'),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () {
                      NavigationLogger.source(
                        'ForgotPasswordScreen.backToLogin',
                        action: 'pushReplacementNamed',
                        to: AppRoutes.authLogin,
                      );
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.authLogin);
                    },
                    child: const Text('Back To Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Enter email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Enter a valid email address.');
      return;
    }

    debugPrint('[ForgotPassword] send:start');
    setState(() {
      _isSending = true;
      _message = null;
      _hasError = false;
    });

    try {
      await _authRepository.sendPasswordResetLink(email: email);
      debugPrint('[ForgotPassword] send:success');
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Password reset link sent to your email.';
        _hasError = false;
      });
    } on Object catch (error) {
      debugPrint('[ForgotPassword] error=$error');
      if (!mounted) {
        return;
      }
      setState(() {
        _message = _messageFromError(error);
        _hasError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _message = message;
      _hasError = true;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String _messageFromError(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }

    return 'Unable to send password reset link.';
  }
}

OutlineInputBorder _border({Color color = AppColors.borderLight}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14.r),
    borderSide: BorderSide(color: color),
  );
}
