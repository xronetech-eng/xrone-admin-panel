import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/account_information_section.dart';
import '../widgets/admin_profile_card.dart';
import '../widgets/change_password_section.dart';
import '../widgets/edit_profile_section.dart';
import '../widgets/settings_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocProvider(
      create: (_) => SettingsBloc()..add(const SettingsProfileRequested()),
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is! SettingsLoaded) {
            return;
          }

          if (state.profileUpdated) {
            debugPrint('[Profile] sidebar:refresh');
            debugPrint('[Profile] dashboard:refresh');
            debugPrint('[Profile] header:refresh');
            context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
          }

          final message = state.message;
          if (message == null || message.isEmpty) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsHeader(),
              SizedBox(height: AppSpacing.xl),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 380.w, child: const AdminProfileCard()),
                    SizedBox(width: AppSpacing.lg),
                    const Expanded(child: _SettingsSections()),
                  ],
                )
              else
                const Column(
                  children: [
                    AdminProfileCard(),
                    SizedBox(height: 24),
                    _SettingsSections(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSections extends StatelessWidget {
  const _SettingsSections();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EditProfileSection(),
        SizedBox(height: AppSpacing.lg),
        const ChangePasswordSection(),
        SizedBox(height: AppSpacing.lg),
        const AccountInformationSection(),
      ],
    );
  }
}
