import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class LiveTrackingSection extends StatelessWidget {
  const LiveTrackingSection({required this.tracking, super.key});

  final PilotLiveTrackingData tracking;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Live Tracking',
      subtitle: 'Read only',
      child: Column(
        children: [
          Container(
            height: 170.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _TrackingMapPainter()),
                ),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark.withValues(alpha: 0.08),
                          blurRadius: 16.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryBlue,
                          size: 18.r,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          _trackingLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _Meta(label: 'Booking ID', value: tracking.bookingId),
              _Meta(label: 'Current Latitude', value: tracking.currentLatitude),
              _Meta(
                label: 'Current Longitude',
                value: tracking.currentLongitude,
              ),
              _Meta(label: 'Current Status', value: tracking.currentStatus),
              _Meta(
                label: 'Latest Tracking Update',
                value: tracking.latestTrackingUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _trackingLabel {
    final latitude = tracking.currentLatitude;
    final longitude = tracking.currentLongitude;
    final status = tracking.currentStatus;
    if (latitude == '-' || longitude == '-') {
      return 'No tracking coordinates';
    }

    return '$latitude, $longitude - $status';
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.42)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.18,
        size.width * 0.58,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.82,
        size.width * 0.88,
        size.height * 0.32,
      );

    canvas.drawPath(path, routePaint);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.32),
      7.r,
      Paint()..color = AppColors.primaryBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
