part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.profile,
    this.message,
    this.isProfileSaving = false,
    this.isPasswordSaving = false,
    this.isError = false,
    this.profileUpdated = false,
  });

  final SettingsAdminProfile profile;
  final String? message;
  final bool isProfileSaving;
  final bool isPasswordSaving;
  final bool isError;
  final bool profileUpdated;

  SettingsLoaded copyWith({
    SettingsAdminProfile? profile,
    String? message,
    bool clearMessage = false,
    bool? isProfileSaving,
    bool? isPasswordSaving,
    bool? isError,
    bool? profileUpdated,
  }) {
    return SettingsLoaded(
      profile: profile ?? this.profile,
      message: clearMessage ? null : message ?? this.message,
      isProfileSaving: isProfileSaving ?? this.isProfileSaving,
      isPasswordSaving: isPasswordSaving ?? this.isPasswordSaving,
      isError: isError ?? this.isError,
      profileUpdated: profileUpdated ?? this.profileUpdated,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    message,
    isProfileSaving,
    isPasswordSaving,
    isError,
    profileUpdated,
  ];
}

final class SettingsFailure extends SettingsState {
  const SettingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
