import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({required this.services, super.key});

  final List<PilotServiceData> services;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Services',
      subtitle: 'Read only',
      child: services.isEmpty
          ? const PilotEmptyState(message: 'No services found.')
          : Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final service in services) _ServiceCard(service: service),
              ],
            ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final PilotServiceData service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          PilotInfoRow(label: 'Category', value: service.category),
          PilotInfoRow(label: 'Price', value: service.price),
          PilotInfoRow(label: 'Market Price', value: service.marketPrice),
          PilotInfoRow(label: 'Area', value: service.area),
          PilotInfoRow(label: 'Radius', value: service.serviceRadius),
        ],
      ),
    );
  }
}
