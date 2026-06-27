import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class DefaultMarketPriceSection extends StatelessWidget {
  const DefaultMarketPriceSection({required this.services, super.key});

  final List<PilotServiceData> services;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Default Market Price',
      child: services.isEmpty
          ? const PilotEmptyState(message: 'No market price data found.')
          : SizedBox(
              width: 260.w,
              child: TextFormField(
                key: ValueKey(_marketPriceValue),
                initialValue: _marketPriceValue,
                readOnly: true,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Default Market Price'),
              ),
            ),
    );
  }

  String get _marketPriceValue {
    final service = services.firstWhere(
      (service) => service.marketPrice.trim().isNotEmpty,
      orElse: () => services.first,
    );
    return service.marketPrice;
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
