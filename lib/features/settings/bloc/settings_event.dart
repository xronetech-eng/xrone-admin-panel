part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsProfileRequested extends SettingsEvent {
  const SettingsProfileRequested();
}

final class SettingsProfileSaveRequested extends SettingsEvent {
  const SettingsProfileSaveRequested({
    required this.fullName,
    required this.email,
  });

  final String fullName;
  final String email;

  @override
  List<Object?> get props => [fullName, email];
}

final class SettingsPasswordUpdateRequested extends SettingsEvent {
  const SettingsPasswordUpdateRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

final class SettingsCleared extends SettingsEvent {
  const SettingsCleared();
}
