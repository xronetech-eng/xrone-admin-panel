import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class PilotDetailsPanel extends StatelessWidget {
  const PilotDetailsPanel({required this.pilot, super.key});

  final PilotAdminViewData pilot;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Pilot Details',
      subtitle: 'Read only',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34.r,
                backgroundColor: AppColors.primaryBlue,
                backgroundImage: pilot.profileImage.trim().isEmpty
                    ? null
                    : NetworkImage(pilot.profileImage.trim()),
                child: pilot.profileImage.trim().isEmpty
                    ? Text(
                        pilot.profileLabel,
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium,
                    ),
                    SizedBox(height: 8.h),
                    PilotStatusPill(
                      label: pilot.status.label,
                      color: pilot.status.color,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          PilotInfoRow(label: 'Name', value: pilot.name),
          PilotInfoRow(label: 'Email', value: pilot.email),
          PilotInfoRow(label: 'Gender', value: pilot.gender),
          PilotInfoRow(label: 'Contact Number', value: pilot.contactNumber),
          PilotInfoRow(label: 'Created Date', value: pilot.createdDate),
        ],
      ),
    );
  }
}
