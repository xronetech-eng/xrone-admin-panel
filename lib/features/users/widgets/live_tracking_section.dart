import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/users_model.dart';

class LiveTrackingSection extends StatelessWidget {
  const LiveTrackingSection({required this.tracking, super.key});

  final UserLiveTrackingData tracking;

  @override
  Widget build(BuildContext context) {
    final marker = _markerFrom(tracking.latitude, tracking.longitude);
    final hasLocation = marker != null;
    return _SectionCard(
      title: 'Live Tracking',
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
                  child: CustomPaint(
                    painter: _LiveTrackingPainter(marker: marker),
                  ),
                ),
                Align(
                  alignment: hasLocation ? Alignment.topLeft : Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
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
                        children: [
                          Icon(
                            hasLocation
                                ? Icons.my_location_rounded
                                : Icons.location_off_outlined,
                            color: hasLocation
                                ? AppColors.primaryBlue
                                : AppColors.textMuted,
                            size: 18.r,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              hasLocation
                                  ? 'Live pilot location'
                                  : 'Location unavailable',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: hasLocation
                                    ? AppColors.primaryBlue
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              _Meta(label: 'Current Booking', value: tracking.currentBooking),
              _Meta(label: 'Pilot Name', value: tracking.pilotName),
              _Meta(label: 'Current Status', value: tracking.currentStatus),
              _Meta(label: 'Latitude', value: tracking.latitude),
              _Meta(label: 'Longitude', value: tracking.longitude),
              _Meta(label: 'Tracking Status', value: tracking.trackingStatus),
              _Meta(label: 'Last Updated', value: tracking.lastUpdated),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveTrackingPainter extends CustomPainter {
  const _LiveTrackingPainter({required this.marker});

  final Offset? marker;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = AppColors.primaryBlue.withValues(
        alpha: marker == null ? 0.18 : 0.4,
      )
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.24,
        size.width * 0.56,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.78,
        size.width * 0.86,
        size.height * 0.34,
      );
    canvas.drawPath(path, routePaint);
    final point = marker == null
        ? Offset(size.width * 0.5, size.height * 0.5)
        : Offset(size.width * marker!.dx, size.height * marker!.dy);
    canvas.drawCircle(
      point,
      marker == null ? 6.r : 9.r,
      Paint()
        ..color = marker == null ? AppColors.textMuted : AppColors.primaryBlue,
    );
    if (marker != null) {
      canvas.drawCircle(
        point,
        18.r,
        Paint()..color = AppColors.primaryBlue.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveTrackingPainter oldDelegate) {
    return oldDelegate.marker != marker;
  }
}

Offset? _markerFrom(String latitude, String longitude) {
  final lat = double.tryParse(latitude);
  final lng = double.tryParse(longitude);
  if (lat == null || lng == null) {
    return null;
  }
  final normalizedX = ((lng + 180) / 360).clamp(0.08, 0.92).toDouble();
  final normalizedY = ((90 - lat) / 180).clamp(0.12, 0.88).toDouble();
  return Offset(normalizedX, normalizedY);
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170.w,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title, style: AppTextStyles.headingMedium),
          SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
