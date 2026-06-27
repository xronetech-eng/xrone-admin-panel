import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/dashboard_model.dart';
import '../repository/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required DashboardRepository repository})
    : _repository = repository,
      super(const DashboardInitial()) {
    on<DashboardRequested>(_onDashboardRequested);
  }

  final DashboardRepository _repository;

  Future<void> _onDashboardRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      final data = await _repository.load();
      emit(DashboardLoaded(data));
    } on Object catch (error) {
      emit(DashboardFailure(_errorMessage(error)));
    }
  }

  String _errorMessage(Object error) {
    if (error is DashboardRepositoryException) {
      return error.message;
    }

    return 'Unable to load dashboard data.';
  }
}
