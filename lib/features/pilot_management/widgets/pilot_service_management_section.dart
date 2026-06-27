import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilot_management_model.dart';

class PilotServiceManagementSection extends StatelessWidget {
  const PilotServiceManagementSection({
    required this.controller,
    required this.services,
    required this.onAdd,
    required this.onRemove,
    required this.onSave,
    this.isSaving = false,
    super.key,
  });

  final TextEditingController controller;
  final List<PilotServiceChipData> services;
  final VoidCallback onAdd;
  final ValueChanged<PilotServiceChipData> onRemove;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.design_services_outlined,
      title: 'Services',
      subtitle: 'Create the visible service catalogue for the pilot app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320.w,
                child: SettingsInput(
                  controller: controller,
                  label: 'Add Service',
                  icon: Icons.add_circle_outline,
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded, size: 18.r),
                label: const Text('Add Service'),
              ),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(strokeWidth: 2.r),
                      )
                    : Icon(Icons.save_outlined, size: 18.r),
                label: Text(isSaving ? 'Saving' : 'Save Services'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final service in services)
                ServiceChipCard(
                  service: service,
                  onRemove: () => onRemove(service),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceChipCard extends StatelessWidget {
  const ServiceChipCard({
    required this.service,
    required this.onRemove,
    super.key,
  });

  final PilotServiceChipData service;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(service.icon, color: AppColors.primaryBlue, size: 20.r),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              service.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete service',
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18.r),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18.r),
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
          Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 22.r),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headingMedium),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class SettingsInput extends StatelessWidget {
  const SettingsInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 19.r),
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
      ),
    );
  }
}
