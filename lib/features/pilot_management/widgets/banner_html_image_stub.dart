import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';

Widget buildBannerHtmlImage(String url) {
  return DecoratedBox(
    decoration: const BoxDecoration(color: AppColors.primaryBlueLight),
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: AppColors.primaryBlue,
        size: 32.r,
      ),
    ),
  );
}
