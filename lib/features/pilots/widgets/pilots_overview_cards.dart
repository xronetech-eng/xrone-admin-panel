import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../models/pilots_model.dart';

class PilotsOverviewCards extends StatelessWidget {
  const PilotsOverviewCards({required this.pilots, super.key});

  final List<PilotAdminViewData> pilots;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );
    final activeServices = pilots.fold<int>(
      0,
      (total, pilot) =>
          total + pilot.services.where((service) => service.isActive).length,
    );
    final activeBookings = pilots.fold<int>(
      0,
      (total, pilot) => total + pilot.activeBookings.length,
    );
    final cards = [
      _OverviewData(
        title: 'Total Pilots',
        value: pilots.length.toString(),
        icon: Icons.badge_outlined,
        color: AppColors.primaryBlue,
      ),
      _OverviewData(
        title: 'Active Pilots',
        value: pilots
            .where((pilot) => pilot.status == PilotStatus.active)
            .length
            .toString(),
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF16A34A),
      ),
      _OverviewData(
        title: 'Active Services',
        value: activeServices.toString(),
        icon: Icons.miscellaneous_services_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _OverviewData(
        title: 'Active Bookings',
        value: activeBookings.toString(),
        icon: Icons.event_available_outlined,
        color: const Color(0xFF0891B2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 138.h,
      ),
      itemBuilder: (context, index) => _OverviewCard(data: cards[index]),
    );
  }
}

class _OverviewData {
  const _OverviewData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.h,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(data.icon, color: data.color, size: 24.r),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
