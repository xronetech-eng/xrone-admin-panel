import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../auth/repository/auth_repository.dart';
import '../models/settings_model.dart';
import '../repository/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository(),
      super(const SettingsInitial()) {
    on<SettingsProfileRequested>(_onProfileRequested);
    on<SettingsProfileSaveRequested>(_onProfileSaveRequested);
    on<SettingsPasswordUpdateRequested>(_onPasswordUpdateRequested);
    on<SettingsCleared>(_onSettingsCleared);
  }

  void _onSettingsCleared(SettingsCleared event, Emitter<SettingsState> emit) {
    emit(const SettingsInitial());
  }

  final SettingsRepository _repository;

  Future<void> _onProfileRequested(
    SettingsProfileRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      final profile = await _repository.loadProfile();
      emit(SettingsLoaded(profile: profile));
    } on Object catch (error) {
      emit(SettingsFailure(_messageFromError(error)));
    }
  }

  Future<void> _onProfileSaveRequested(
    SettingsProfileSaveRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) {
      return;
    }

    emit(
      current.copyWith(
        clearMessage: true,
        isProfileSaving: true,
        isError: false,
        profileUpdated: false,
      ),
    );

    try {
      final profile = await _repository.updateProfile(
        currentProfile: current.profile,
        fullName: event.fullName,
        email: event.email,
      );
      emit(
        SettingsLoaded(
          profile: profile,
          message: _profileSuccessMessage(current.profile.email, event.email),
          profileUpdated: true,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          message: _messageFromError(error),
          isProfileSaving: false,
          isError: true,
          profileUpdated: false,
        ),
      );
    }
  }

  Future<void> _onPasswordUpdateRequested(
    SettingsPasswordUpdateRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) {
      return;
    }

    emit(
      current.copyWith(
        clearMessage: true,
        isPasswordSaving: true,
        isError: false,
        profileUpdated: false,
      ),
    );

    try {
      await _repository.updatePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(
        current.copyWith(
          message: 'Password updated successfully.',
          isPasswordSaving: false,
          isError: false,
          profileUpdated: false,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          message: _messageFromError(error),
          isPasswordSaving: false,
          isError: true,
          profileUpdated: false,
        ),
      );
    }
  }

  String _profileSuccessMessage(String oldEmail, String newEmail) {
    if (oldEmail != newEmail) {
      return 'Profile updated. Check your email to verify this change.';
    }

    return 'Profile updated successfully.';
  }

  String _messageFromError(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }

    if (error is SettingsRepositoryException) {
      return error.message;
    }

    return 'Unable to update settings.';
  }
}
