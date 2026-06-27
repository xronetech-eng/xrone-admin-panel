import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({this.message = 'Loading', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.h,
            child: CircularProgressIndicator(strokeWidth: 3.r),
          ),
          SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
