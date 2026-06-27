import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class RequestRadiusSection extends StatelessWidget {
  const RequestRadiusSection({required this.services, super.key});

  final List<PilotServiceData> services;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Request Radius',
      child: services.isEmpty
          ? const PilotEmptyState(message: 'No service radius data found.')
          : SizedBox(
              width: 260.w,
              child: TextFormField(
                key: ValueKey(_radiusValue),
                initialValue: _radiusValue,
                readOnly: true,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Request Radius'),
              ),
            ),
    );
  }

  String get _radiusValue {
    final service = services.firstWhere(
      (service) => service.serviceRadius.trim().isNotEmpty,
      orElse: () => services.first,
    );
    return service.serviceRadius;
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.bodySmall,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14.h,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.primaryBlue),
    ),
  );
}
