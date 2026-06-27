import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/users_model.dart';
import '../repository/users_repository.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({required UsersRepository repository})
    : _repository = repository,
      super(const UsersInitial()) {
    on<UsersRequested>(_onUsersRequested);
    on<UserSelected>(_onUserSelected);
  }

  final UsersRepository _repository;

  Future<void> _onUsersRequested(
    UsersRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UsersLoading());

    try {
      final users = await _repository.fetchUsers();

      if (users.isEmpty) {
        emit(const UsersEmpty());
        return;
      }

      emit(UsersSuccess(users: users));
    } on Object catch (error) {
      emit(UsersFailure(_errorMessage(error)));
    }
  }

  Future<void> _onUserSelected(
    UserSelected event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    if (current is! UsersSuccess || current.users.isEmpty) {
      return;
    }

    final index = event.index.clamp(0, current.users.length - 1);
    final selectedUser = current.users[index];

    emit(
      current.copyWith(
        selectedIndex: index,
        detailsStatus: UserDetailsStatus.loading,
        clearDetailsError: true,
      ),
    );

    try {
      final detailedUser = await _repository.fetchUserDetails(selectedUser);
      final users = [...current.users]..[index] = detailedUser;

      emit(
        current.copyWith(
          users: users,
          selectedIndex: index,
          detailsStatus: UserDetailsStatus.success,
          clearDetailsError: true,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          selectedIndex: index,
          detailsStatus: UserDetailsStatus.failure,
          detailsError: _errorMessage(error),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is UsersRepositoryException) {
      return error.message;
    }

    return 'Unable to load users data.';
  }
}
