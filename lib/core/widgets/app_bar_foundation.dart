import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

class AppBarFoundation extends StatelessWidget implements PreferredSizeWidget {
  const AppBarFoundation({required this.title, this.onMenuPressed, super.key});

  final String title;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => Size.fromHeight(72.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onMenuPressed == null
          ? null
          : IconButton(
              tooltip: 'Open navigation',
              icon: Icon(Icons.menu, size: 24.r),
              onPressed: onMenuPressed,
            ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingMedium,
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.primaryBlueLight,
            child: Icon(
              Icons.person_outline,
              color: AppColors.primaryBlue,
              size: 20.r,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Divider(height: 1.h),
      ),
    );
  }
}
