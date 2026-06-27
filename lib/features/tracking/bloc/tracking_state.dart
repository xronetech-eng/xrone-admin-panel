part of 'tracking_bloc.dart';

sealed class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

final class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

final class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

final class TrackingLoaded extends TrackingState {
  const TrackingLoaded(this.data);

  final TrackingData data;

  @override
  List<Object?> get props => [data];
}

final class TrackingFailure extends TrackingState {
  const TrackingFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
