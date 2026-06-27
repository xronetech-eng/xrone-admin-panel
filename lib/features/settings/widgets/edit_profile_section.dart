import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/settings_bloc.dart';
import '../models/settings_model.dart';
import 'settings_section_card.dart';

class EditProfileSection extends StatefulWidget {
  const EditProfileSection({super.key});

  @override
  State<EditProfileSection> createState() => _EditProfileSectionState();
}

class _EditProfileSectionState extends State<EditProfileSection> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _loadedUserId = '';
  String _loadedName = '';
  String _loadedEmail = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final profile = state is SettingsLoaded
            ? state.profile
            : SettingsAdminProfile.empty;
        final isSaving = state is SettingsLoaded && state.isProfileSaving;
        _syncProfile(profile);

        return SettingsSectionCard(
          title: 'Edit Profile',
          child: Column(
            children: [
              _Field(label: 'Full Name', controller: _nameController),
              SizedBox(height: AppSpacing.md),
              _Field(
                label: 'Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: isSaving ? null : _saveProfile,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncProfile(SettingsAdminProfile profile) {
    if (profile.userId.isEmpty ||
        (_loadedUserId == profile.userId &&
            _loadedName == profile.fullName &&
            _loadedEmail == profile.email)) {
      return;
    }

    _loadedUserId = profile.userId;
    _loadedName = profile.fullName;
    _loadedEmail = profile.email;
    _nameController.text = profile.fullName;
    _emailController.text = profile.email;
  }

  void _saveProfile() {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty) {
      _showMessage('Enter full name.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Enter email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address.');
      return;
    }

    context.read<SettingsBloc>().add(
      SettingsProfileSaveRequested(fullName: fullName, email: email),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
