import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../models/dashboard_model.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({required this.activities, super.key});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.05),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.headingMedium),
          SizedBox(height: AppSpacing.lg),
          if (activities.isEmpty)
            const _ActivityEmptyState()
          else if (isMobile)
            _MobileActivityList(activities: activities)
          else
            _ActivityTable(activities: activities),
        ],
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_outlined,
              color: AppColors.primaryBlue,
              size: 24.r,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No recent activity',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'New bookings, users, pilots, orders and payments will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActivityRow(
          name: 'Name',
          action: 'Action',
          source: 'Source',
          status: 'Status',
          time: 'Date/Time',
          isHeader: true,
        ),
        for (final activity in activities)
          _ActivityRow(
            name: activity.name,
            action: activity.action,
            source: activity.source,
            status: activity.status,
            time: activity.time,
            color: _activityColor(activity.status),
          ),
      ],
    );
  }
}

class _MobileActivityList extends StatelessWidget {
  const _MobileActivityList({required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final activity in activities)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _StatusPill(
                        label: activity.status,
                        color: _activityColor(activity.status),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    activity.action,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${activity.time} | ${activity.source}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.name,
    required this.action,
    required this.source,
    required this.status,
    required this.time,
    this.color = AppColors.textMuted,
    this.isHeader = false,
  });

  final String name;
  final String action;
  final String source;
  final String status;
  final String time;
  final Color color;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 56.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.h),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.surface : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isHeader ? Colors.transparent : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _TableText(name, isHeader: isHeader)),
          Expanded(flex: 3, child: _TableText(action, isHeader: isHeader)),
          Expanded(flex: 2, child: _TableText(time, isHeader: isHeader)),
          Expanded(flex: 2, child: _TableText(source, isHeader: isHeader)),
          Expanded(
            flex: 2,
            child: isHeader
                ? _TableText(status, isHeader: true)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(label: status, color: color),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.text, {required this.isHeader});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isHeader ? AppColors.textMuted : AppColors.textDark,
        fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _activityColor(String status) {
  return switch (status.toLowerCase()) {
    'active' ||
    'approved' ||
    'completed' ||
    'successful' ||
    'success' => const Color(0xFF16A34A),
    'accepted' || 'processing' => const Color(0xFF0B5ED7),
    'pending' || 'created' || 'initiated' => const Color(0xFFF59E0B),
    'working' => const Color(0xFF7C3AED),
    'failed' || 'rejected' || 'declined' => const Color(0xFFDC2626),
    _ => AppColors.textMuted,
  };
}
