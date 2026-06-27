import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class StatCard extends StatefulWidget {
  const StatCard({
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
    required this.accentColor,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final String growth;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: _isHovered ? widget.accentColor : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isHovered ? widget.accentColor : AppColors.textDark)
                    .withValues(alpha: _isHovered ? 0.13 : 0.05),
                blurRadius: _isHovered ? 28.r : 18.r,
                offset: Offset(0, _isHovered ? 12.h : 8.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 23.r,
                    ),
                  ),
                  const Spacer(),
                  _GrowthBadge(value: widget.growth),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthBadge extends StatelessWidget {
  const _GrowthBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward, size: 12.r, color: const Color(0xFF16A34A)),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}
