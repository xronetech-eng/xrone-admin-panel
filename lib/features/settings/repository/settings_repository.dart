import 'package:flutter/foundation.dart';

import '../../auth/repository/auth_repository.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  SettingsRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<SettingsAdminProfile> loadProfile() async {
    debugPrint('[Profile] load:start');

    try {
      final profile = await _authRepository.loadCurrentAdminProfile();
      final settingsProfile = _fromAuthProfile(profile);

      debugPrint('[Profile] userId=${settingsProfile.userId}');
      debugPrint('[Profile] name=${settingsProfile.fullName}');
      debugPrint('[Profile] email=${settingsProfile.email}');
      debugPrint('[Profile] load:success');

      return settingsProfile;
    } on Object catch (error) {
      debugPrint('[Profile] error=$error');
      rethrow;
    }
  }

  Future<SettingsAdminProfile> updateProfile({
    required SettingsAdminProfile currentProfile,
    required String fullName,
    required String email,
  }) async {
    debugPrint('[Profile] update:start');
    debugPrint('[Profile] oldName=${currentProfile.fullName}');
    debugPrint('[Profile] newName=$fullName');
    debugPrint('[Profile] oldEmail=${currentProfile.email}');
    debugPrint('[Profile] newEmail=$email');

    try {
      final profile = await _authRepository.updateCurrentAdminProfile(
        fullName: fullName,
        email: email,
      );
      final settingsProfile = _fromAuthProfile(profile);
      debugPrint('[Profile] update:success');
      return settingsProfile;
    } on Object catch (error) {
      debugPrint('[Profile] error=$error');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    debugPrint('[Profile] password:update:start');

    try {
      await _authRepository.updateCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      debugPrint('[Profile] password:update:success');
    } on Object catch (error) {
      debugPrint('[Profile] error=$error');
      rethrow;
    }
  }

  SettingsAdminProfile _fromAuthProfile(AuthAdminProfile profile) {
    return SettingsAdminProfile(
      userId: profile.userId,
      fullName: profile.fullName,
      email: profile.email,
      role: profile.role,
      profileImage: profile.profileImage,
      createdDate: profile.createdDate,
      lastSignInDate: profile.lastSignInDate,
    );
  }
}

class SettingsRepositoryException implements Exception {
  const SettingsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
