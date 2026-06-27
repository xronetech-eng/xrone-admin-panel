part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

final class UsersRequested extends UsersEvent {
  const UsersRequested();
}

final class UserSelected extends UsersEvent {
  const UserSelected(this.index);

  final int index;

  @override
  List<Object> get props => [index];
}
