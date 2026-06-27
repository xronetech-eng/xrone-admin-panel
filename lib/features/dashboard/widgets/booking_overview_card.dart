import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/dashboard_model.dart';

class BookingOverviewCard extends StatelessWidget {
  const BookingOverviewCard({
    required this.summary,
    required this.selectedStatus,
    required this.onStatusTap,
    super.key,
  });

  final DashboardBookingsSummary summary;
  final String? selectedStatus;
  final ValueChanged<String> onStatusTap;

  @override
  Widget build(BuildContext context) {
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
          Text('Booking Overview', style: AppTextStyles.headingMedium),
          SizedBox(height: 6.h),
          Text(
            'Current operation status',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          SizedBox(height: AppSpacing.xl),
          _StatusRow(
            label: 'Pending',
            status: 'pending',
            value: _formatInt(summary.pending),
            color: const Color(0xFFF59E0B),
            selected: selectedStatus == 'pending',
            onTap: onStatusTap,
          ),
          _StatusRow(
            label: 'Accepted',
            status: 'accepted',
            value: _formatInt(summary.accepted),
            color: const Color(0xFF0B5ED7),
            selected: selectedStatus == 'accepted',
            onTap: onStatusTap,
          ),
          _StatusRow(
            label: 'Working',
            status: 'working',
            value: _formatInt(summary.working),
            color: const Color(0xFF7C3AED),
            selected: selectedStatus == 'working',
            onTap: onStatusTap,
          ),
          _StatusRow(
            label: 'Completed',
            status: 'completed',
            value: _formatInt(summary.completed),
            color: const Color(0xFF16A34A),
            selected: selectedStatus == 'completed',
            onTap: onStatusTap,
          ),
        ],
      ),
    );
  }
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final position = text.length - index;
    buffer.write(text[index]);
    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.status,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String status;
  final String value;
  final Color color;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: () => onTap(status),
          child: Container(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.16 : 0.09),
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: color, size: 18.r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
