import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/settings_bloc.dart';
import 'settings_section_card.dart';

class ChangePasswordSection extends StatefulWidget {
  const ChangePasswordSection({super.key});

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final isSaving = state is SettingsLoaded && state.isPasswordSaving;

        return SettingsSectionCard(
          title: 'Change Password',
          child: Column(
            children: [
              _PasswordField(
                label: 'Current Password',
                controller: _currentPasswordController,
              ),
              SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: 'New Password',
                controller: _newPasswordController,
              ),
              SizedBox(height: AppSpacing.md),
              _PasswordField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
              ),
              SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: isSaving ? null : _updatePassword,
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updatePassword() {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Enter current password, new password, and confirmation.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('New password and confirm password do not match.');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('Enter a stronger password.');
      return;
    }

    context.read<SettingsBloc>().add(
      SettingsPasswordUpdateRequested(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14.h,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppColors.primaryBlue),
      ),
    );
  }

  OutlineInputBorder _border({Color color = AppColors.borderLight}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: color),
    );
  }
}
