part of 'users_bloc.dart';

enum UserDetailsStatus { initial, loading, success, failure }

sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

final class UsersInitial extends UsersState {
  const UsersInitial();
}

final class UsersLoading extends UsersState {
  const UsersLoading();
}

final class UsersEmpty extends UsersState {
  const UsersEmpty();
}

final class UsersFailure extends UsersState {
  const UsersFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class UsersSuccess extends UsersState {
  const UsersSuccess({
    required this.users,
    this.selectedIndex,
    this.detailsStatus = UserDetailsStatus.initial,
    this.detailsError,
  });

  final List<UserAdminViewData> users;
  final int? selectedIndex;
  final UserDetailsStatus detailsStatus;
  final String? detailsError;

  UserAdminViewData? get selectedUser {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= users.length) {
      return null;
    }

    return users[index];
  }

  UsersSuccess copyWith({
    List<UserAdminViewData>? users,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    UserDetailsStatus? detailsStatus,
    String? detailsError,
    bool clearDetailsError = false,
  }) {
    return UsersSuccess(
      users: users ?? this.users,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      detailsError: clearDetailsError
          ? null
          : detailsError ?? this.detailsError,
    );
  }

  @override
  List<Object?> get props => [
    users,
    selectedIndex,
    detailsStatus,
    detailsError,
  ];
}
