part of 'pilots_bloc.dart';

sealed class PilotsEvent extends Equatable {
  const PilotsEvent();

  @override
  List<Object?> get props => [];
}

final class PilotsRequested extends PilotsEvent {
  const PilotsRequested();
}

final class PilotsRefreshRequested extends PilotsEvent {
  const PilotsRefreshRequested();
}

final class PilotSelected extends PilotsEvent {
  const PilotSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class PilotServicePricesSaved extends PilotsEvent {
  const PilotServicePricesSaved({
    required this.serviceId,
    required this.price,
    required this.marketPrice,
  });

  final String serviceId;
  final String price;
  final String marketPrice;

  @override
  List<Object?> get props => [serviceId, price, marketPrice];
}

final class PilotServiceCreated extends PilotsEvent {
  const PilotServiceCreated(this.service);

  final PilotServiceMutationData service;

  @override
  List<Object?> get props => [service];
}

final class PilotServiceSaved extends PilotsEvent {
  const PilotServiceSaved({required this.serviceId, required this.service});

  final String serviceId;
  final PilotServiceMutationData service;

  @override
  List<Object?> get props => [serviceId, service];
}

final class PilotServiceDeleted extends PilotsEvent {
  const PilotServiceDeleted(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}

final class PilotBannerUploaded extends PilotsEvent {
  const PilotBannerUploaded(this.image);

  final PickedBannerImage image;

  @override
  List<Object?> get props => [image];
}

final class PilotBannerDeleted extends PilotsEvent {
  const PilotBannerDeleted(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}
