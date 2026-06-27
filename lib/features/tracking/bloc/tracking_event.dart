part of 'tracking_bloc.dart';

sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object> get props => [];
}

final class TrackingRequested extends TrackingEvent {
  const TrackingRequested();
}
