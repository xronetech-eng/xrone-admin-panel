import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/settings_bloc.dart';
import '../models/settings_model.dart';
import 'settings_section_card.dart';

class AccountInformationSection extends StatelessWidget {
  const AccountInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final profile = state is SettingsLoaded
            ? state.profile
            : SettingsAdminProfile.empty;

        return SettingsSectionCard(
          title: 'Account Information',
          child: Column(
            children: [
              _InfoRow(
                label: 'Account Created Date',
                value: profile.createdDate,
              ),
              _InfoRow(label: 'Last Login', value: profile.lastSignInDate),
              const _InfoRow(
                label: 'Account Status',
                value: 'Active',
                isStatus: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  final String label;
  final String value;
  final bool isStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isStatus ? const Color(0xFF16A34A) : AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
