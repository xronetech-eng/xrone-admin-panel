part of 'pilots_bloc.dart';

enum PilotDetailsStatus { initial, loading, loaded, error, refreshing }

sealed class PilotsState extends Equatable {
  const PilotsState();

  @override
  List<Object?> get props => [];
}

final class PilotsInitial extends PilotsState {
  const PilotsInitial();
}

final class PilotsLoading extends PilotsState {
  const PilotsLoading();
}

final class PilotsRefreshing extends PilotsState {
  const PilotsRefreshing({required this.pilots, this.selectedIndex});

  final List<PilotAdminViewData> pilots;
  final int? selectedIndex;

  @override
  List<Object?> get props => [pilots, selectedIndex];
}

final class PilotsError extends PilotsState {
  const PilotsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PilotsLoaded extends PilotsState {
  const PilotsLoaded({
    required this.pilots,
    this.selectedIndex,
    this.detailsStatus = PilotDetailsStatus.initial,
    this.detailsError,
    this.mutationMessage,
    this.mutatingServiceId,
    this.isUploadingBanner = false,
    this.deletingBannerPath,
  });

  final List<PilotAdminViewData> pilots;
  final int? selectedIndex;
  final PilotDetailsStatus detailsStatus;
  final String? detailsError;
  final String? mutationMessage;
  final String? mutatingServiceId;
  final bool isUploadingBanner;
  final String? deletingBannerPath;

  PilotAdminViewData? get selectedPilot {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= pilots.length) {
      return null;
    }

    return pilots[index];
  }

  PilotsLoaded copyWith({
    List<PilotAdminViewData>? pilots,
    int? selectedIndex,
    bool clearSelectedIndex = false,
    PilotDetailsStatus? detailsStatus,
    String? detailsError,
    bool clearDetailsError = false,
    String? mutationMessage,
    bool clearMutationMessage = false,
    String? mutatingServiceId,
    bool clearMutatingServiceId = false,
    bool? isUploadingBanner,
    String? deletingBannerPath,
    bool clearDeletingBannerPath = false,
  }) {
    return PilotsLoaded(
      pilots: pilots ?? this.pilots,
      selectedIndex: clearSelectedIndex
          ? null
          : selectedIndex ?? this.selectedIndex,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      detailsError: clearDetailsError
          ? null
          : detailsError ?? this.detailsError,
      mutationMessage: clearMutationMessage
          ? null
          : mutationMessage ?? this.mutationMessage,
      mutatingServiceId: clearMutatingServiceId
          ? null
          : mutatingServiceId ?? this.mutatingServiceId,
      isUploadingBanner: isUploadingBanner ?? this.isUploadingBanner,
      deletingBannerPath: clearDeletingBannerPath
          ? null
          : deletingBannerPath ?? this.deletingBannerPath,
    );
  }

  @override
  List<Object?> get props => [
    pilots,
    selectedIndex,
    detailsStatus,
    detailsError,
    mutationMessage,
    mutatingServiceId,
    isUploadingBanner,
    deletingBannerPath,
  ];
}
