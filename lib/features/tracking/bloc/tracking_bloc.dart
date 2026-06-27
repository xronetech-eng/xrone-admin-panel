import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/tracking_model.dart';
import '../repository/tracking_repository.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc({required TrackingRepository repository})
    : _repository = repository,
      super(const TrackingInitial()) {
    on<TrackingRequested>(_onTrackingRequested);
  }

  final TrackingRepository _repository;

  Future<void> _onTrackingRequested(
    TrackingRequested event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingLoading());

    try {
      final data = await _repository.load();
      emit(TrackingLoaded(data));
    } on Object catch (error) {
      emit(TrackingFailure(_errorMessage(error)));
    }
  }

  String _errorMessage(Object error) {
    if (error is TrackingRepositoryException) {
      return error.message;
    }

    return 'Unable to load tracking data.';
  }
}
