import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../models/tracking_model.dart';

class TrackingDetailsPanel extends StatelessWidget {
  const TrackingDetailsPanel({required this.row, super.key});

  final TrackingRowData? row;

  @override
  Widget build(BuildContext context) {
    final data = row;
    final padding = ResponsiveHelper.value<double>(
      context,
      mobile: AppSpacing.lg,
      tablet: AppSpacing.xl,
      desktop: 32.w,
    );
    final titleSpacing = ResponsiveHelper.value<double>(
      context,
      mobile: AppSpacing.lg,
      tablet: AppSpacing.xl,
      desktop: 28.h,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
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
      child: data == null
          ? Text('No tracking selected', style: AppTextStyles.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking Details',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  data.bookingId,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: titleSpacing),
                for (final info in _details(data))
                  _Info(label: info.label, value: info.value),
                SizedBox(height: AppSpacing.sm),
                _Timeline(row: data),
              ],
            ),
    );
  }
}

List<_DetailInfo> _details(TrackingRowData data) {
  return switch (data.type) {
    TrackingTabType.bookings => [
      _DetailInfo('Booking ID', data.id),
      _DetailInfo('User Name', data.primaryName),
      _DetailInfo('Pilot Name', data.secondaryName),
      _DetailInfo('Pickup Location', data.firstDetail),
      _DetailInfo('Drop Location', data.secondDetail),
      _DetailInfo('Booking Status', data.status),
      _DetailInfo('Created Date', data.createdDate),
    ],
    TrackingTabType.pilots => [
      _DetailInfo('Pilot Name', data.primaryName),
      _DetailInfo('Assigned Orders', data.assignedOrders.toString()),
      _DetailInfo('Active Deliveries', data.activeDeliveries.toString()),
      _DetailInfo('Current Status', data.status),
      _DetailInfo('Last Activity', data.createdDate),
    ],
    TrackingTabType.store => [
      _DetailInfo('Order Number', data.id),
      _DetailInfo('Customer', data.primaryName),
      _DetailInfo('Total Amount', data.amount),
      _DetailInfo('Payment Status', data.paymentStatus),
      _DetailInfo('Order Status', data.status),
      _DetailInfo('Created Date', data.createdDate),
    ],
  };
}

class _DetailInfo {
  const _DetailInfo(this.label, this.value);

  final String label;
  final String value;
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.row});

  final TrackingRowData row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking Timeline',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        for (var index = 0; index < row.timelineSteps.length; index++)
          _TimelineStep(
            label: row.timelineSteps[index],
            isActive: index <= row.currentStepIndex,
            isCurrent: index == row.currentStepIndex,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isActive,
    required this.isCurrent,
  });

  final String label;
  final bool isActive;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryBlue : AppColors.borderLight;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.h,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.textDark : AppColors.textMuted,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
