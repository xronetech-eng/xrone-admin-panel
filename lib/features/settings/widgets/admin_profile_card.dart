import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/settings_bloc.dart';
import '../models/settings_model.dart';
import 'settings_section_card.dart';

class AdminProfileCard extends StatelessWidget {
  const AdminProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final profile = state is SettingsLoaded
            ? state.profile
            : SettingsAdminProfile.empty;

        return SettingsSectionCard(
          title: 'Admin Profile',
          child: Column(
            children: [
              CircleAvatar(
                radius: 42.r,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(profile.displayName, style: AppTextStyles.headingMedium),
              SizedBox(height: 8.h),
              Text(
                profile.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  profile.displayRole,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
