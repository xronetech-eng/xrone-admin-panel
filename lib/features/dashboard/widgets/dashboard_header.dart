import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/bloc/auth_bloc.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final adminName = authState is AuthAuthenticated
        ? (authState.fullName.isEmpty ? authState.email : authState.fullName)
        : '';

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back 👋',
          style: AppTextStyles.headingLarge.copyWith(fontSize: 30.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          adminName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Manage bookings, pilots, users and store operations.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      ],
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthUnauthenticated) {
          return;
        }

        debugPrint('[Logout] redirect:login');
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(AppRoutes.authLogin, (_) => false);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: heading),
          SizedBox(width: AppSpacing.xl),
          const _ProfileLogoutButton(),
        ],
      ),
    );
  }
}

class _ProfileLogoutButton extends StatelessWidget {
  const _ProfileLogoutButton();

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.background,
      shape: CircleBorder(side: BorderSide(color: AppColors.borderLight)),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashFactory: NoSplash.splashFactory,
        hoverColor: AppColors.primaryBlueLight,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: () => _showLogoutDialog(context),
        child: SizedBox(
          width: 48.r,
          height: 48.r,
          child: Icon(
            Icons.account_circle_outlined,
            color: AppColors.primaryBlue,
            size: 26.r,
          ),
        ),
      ),
    );

    return Tooltip(message: 'Account', child: button);
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text('Logout', style: AppTextStyles.headingMedium),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
