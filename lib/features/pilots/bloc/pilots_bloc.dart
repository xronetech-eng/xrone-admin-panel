import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/pilots_model.dart';
import '../repository/pilots_repository.dart';
import '../widgets/banner_image_picker.dart';

part 'pilots_event.dart';
part 'pilots_state.dart';

class PilotsBloc extends Bloc<PilotsEvent, PilotsState> {
  PilotsBloc({required PilotsRepository repository})
    : _repository = repository,
      super(const PilotsInitial()) {
    on<PilotsRequested>(_onPilotsRequested);
    on<PilotsRefreshRequested>(_onPilotsRefreshRequested);
    on<PilotSelected>(_onPilotSelected);
    on<PilotServicePricesSaved>(_onPilotServicePricesSaved);
    on<PilotServiceCreated>(_onPilotServiceCreated);
    on<PilotServiceSaved>(_onPilotServiceSaved);
    on<PilotServiceDeleted>(_onPilotServiceDeleted);
    on<PilotBannerUploaded>(_onPilotBannerUploaded);
    on<PilotBannerDeleted>(_onPilotBannerDeleted);
  }

  final PilotsRepository _repository;

  Future<void> _onPilotsRequested(
    PilotsRequested event,
    Emitter<PilotsState> emit,
  ) async {
    emit(const PilotsLoading());
    await _loadPilots(emit);
  }

  Future<void> _onPilotsRefreshRequested(
    PilotsRefreshRequested event,
    Emitter<PilotsState> emit,
  ) async {
    final current = state;
    if (current is PilotsLoaded) {
      emit(
        PilotsRefreshing(
          pilots: current.pilots,
          selectedIndex: current.selectedIndex,
        ),
      );
    } else {
      emit(const PilotsLoading());
    }

    await _loadPilots(emit);
  }

  Future<void> _loadPilots(Emitter<PilotsState> emit) async {
    try {
      final pilots = await _repository.fetchPilots();
      emit(PilotsLoaded(pilots: pilots));
    } on Object catch (error) {
      emit(PilotsError(_errorMessage(error)));
    }
  }

  Future<void> _onPilotSelected(
    PilotSelected event,
    Emitter<PilotsState> emit,
  ) async {
    final current = state;
    if (current is! PilotsLoaded || current.pilots.isEmpty) {
      return;
    }

    final index = event.index.clamp(0, current.pilots.length - 1);
    final pilot = current.pilots[index];

    emit(
      current.copyWith(
        selectedIndex: index,
        detailsStatus: PilotDetailsStatus.loading,
        clearDetailsError: true,
        clearMutationMessage: true,
      ),
    );

    try {
      final detailedPilot = await _repository.fetchPilotDetails(pilot.id);
      final pilots = [...current.pilots]..[index] = detailedPilot;

      emit(
        current.copyWith(
          pilots: pilots,
          selectedIndex: index,
          detailsStatus: PilotDetailsStatus.loaded,
          clearDetailsError: true,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          selectedIndex: index,
          detailsStatus: PilotDetailsStatus.error,
          detailsError: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> _onPilotServicePricesSaved(
    PilotServicePricesSaved event,
    Emitter<PilotsState> emit,
  ) async {
    final current = state;
    final selectedPilot = current is PilotsLoaded
        ? current.selectedPilot
        : null;
    final selectedIndex = current is PilotsLoaded
        ? current.selectedIndex
        : null;
    if (current is! PilotsLoaded ||
        selectedPilot == null ||
        selectedIndex == null) {
      return;
    }

    emit(
      current.copyWith(
        mutatingServiceId: event.serviceId,
        clearMutationMessage: true,
      ),
    );

    try {
      await _repository.updateServicePrices(
        serviceId: event.serviceId,
        price: event.price,
        marketPrice: event.marketPrice,
      );
      final detailedPilot = await _repository.fetchPilotDetails(
        selectedPilot.id,
      );
      emit(
        current.copyWith(
          pilots: _replacePilot(current.pilots, selectedIndex, detailedPilot),
          detailsStatus: PilotDetailsStatus.loaded,
          mutationMessage: 'Service prices saved.',
          clearMutatingServiceId: true,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          mutationMessage: _errorMessage(error),
          clearMutatingServiceId: true,
        ),
      );
    }
  }

  Future<void> _onPilotServiceCreated(
    PilotServiceCreated event,
    Emitter<PilotsState> emit,
  ) async {
    final context = _selectedMutationContext();
    if (context == null) {
      return;
    }

    emit(
      context.state.copyWith(
        mutatingServiceId: '__new_service__',
        clearMutationMessage: true,
      ),
    );

    try {
      await _repository.createPilotService(
        pilotId: context.pilot.id,
        service: event.service,
      );
      await _reloadSelectedPilot(
        emit: emit,
        previous: context.state,
        selectedIndex: context.selectedIndex,
        pilotId: context.pilot.id,
        mutationMessage: 'Service created.',
      );
    } on Object catch (error) {
      emit(
        context.state.copyWith(
          mutationMessage: _errorMessage(error),
          clearMutatingServiceId: true,
        ),
      );
    }
  }

  Future<void> _onPilotServiceSaved(
    PilotServiceSaved event,
    Emitter<PilotsState> emit,
  ) async {
    final context = _selectedMutationContext();
    if (context == null) {
      return;
    }

    emit(
      context.state.copyWith(
        mutatingServiceId: event.serviceId,
        clearMutationMessage: true,
      ),
    );

    try {
      await _repository.updatePilotService(
        pilotId: context.pilot.id,
        serviceId: event.serviceId,
        service: event.service,
      );
      await _reloadSelectedPilot(
        emit: emit,
        previous: context.state,
        selectedIndex: context.selectedIndex,
        pilotId: context.pilot.id,
        mutationMessage: 'Service saved.',
      );
    } on Object catch (error) {
      emit(
        context.state.copyWith(
          mutationMessage: _errorMessage(error),
          clearMutatingServiceId: true,
        ),
      );
    }
  }

  Future<void> _onPilotServiceDeleted(
    PilotServiceDeleted event,
    Emitter<PilotsState> emit,
  ) async {
    final context = _selectedMutationContext();
    if (context == null) {
      return;
    }

    emit(
      context.state.copyWith(
        mutatingServiceId: event.serviceId,
        clearMutationMessage: true,
      ),
    );

    try {
      await _repository.deletePilotService(serviceId: event.serviceId);
      await _reloadSelectedPilot(
        emit: emit,
        previous: context.state,
        selectedIndex: context.selectedIndex,
        pilotId: context.pilot.id,
        mutationMessage: 'Service deleted.',
      );
    } on Object catch (error) {
      emit(
        context.state.copyWith(
          mutationMessage: _errorMessage(error),
          clearMutatingServiceId: true,
        ),
      );
    }
  }

  Future<void> _onPilotBannerUploaded(
    PilotBannerUploaded event,
    Emitter<PilotsState> emit,
  ) async {
    final current = state;
    final selectedPilot = current is PilotsLoaded
        ? current.selectedPilot
        : null;
    final selectedIndex = current is PilotsLoaded
        ? current.selectedIndex
        : null;
    if (current is! PilotsLoaded ||
        selectedPilot == null ||
        selectedIndex == null) {
      return;
    }

    emit(current.copyWith(isUploadingBanner: true, clearMutationMessage: true));

    try {
      await _repository.uploadPilotBanner(
        pilotId: selectedPilot.id,
        image: event.image,
      );
      final banners = await _repository.fetchPilotBanners(selectedPilot.id);
      emit(
        current.copyWith(
          pilots: _replacePilot(
            current.pilots,
            selectedIndex,
            selectedPilot.copyWith(banners: banners),
          ),
          mutationMessage: 'Banner uploaded.',
          isUploadingBanner: false,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          mutationMessage: _errorMessage(error),
          isUploadingBanner: false,
        ),
      );
    }
  }

  Future<void> _onPilotBannerDeleted(
    PilotBannerDeleted event,
    Emitter<PilotsState> emit,
  ) async {
    final current = state;
    final selectedPilot = current is PilotsLoaded
        ? current.selectedPilot
        : null;
    final selectedIndex = current is PilotsLoaded
        ? current.selectedIndex
        : null;
    if (current is! PilotsLoaded ||
        selectedPilot == null ||
        selectedIndex == null) {
      return;
    }

    emit(
      current.copyWith(
        deletingBannerPath: event.path,
        clearMutationMessage: true,
      ),
    );

    try {
      await _repository.deletePilotBanner(path: event.path);
      final banners = await _repository.fetchPilotBanners(selectedPilot.id);
      emit(
        current.copyWith(
          pilots: _replacePilot(
            current.pilots,
            selectedIndex,
            selectedPilot.copyWith(banners: banners),
          ),
          mutationMessage: 'Banner deleted.',
          clearDeletingBannerPath: true,
        ),
      );
    } on Object catch (error) {
      emit(
        current.copyWith(
          mutationMessage: _errorMessage(error),
          clearDeletingBannerPath: true,
        ),
      );
    }
  }

  List<PilotAdminViewData> _replacePilot(
    List<PilotAdminViewData> pilots,
    int index,
    PilotAdminViewData pilot,
  ) {
    return [...pilots]..[index] = pilot;
  }

  _PilotMutationContext? _selectedMutationContext() {
    final current = state;
    final selectedPilot = current is PilotsLoaded
        ? current.selectedPilot
        : null;
    final selectedIndex = current is PilotsLoaded
        ? current.selectedIndex
        : null;
    if (current is! PilotsLoaded ||
        selectedPilot == null ||
        selectedIndex == null) {
      return null;
    }

    return _PilotMutationContext(
      state: current,
      pilot: selectedPilot,
      selectedIndex: selectedIndex,
    );
  }

  Future<void> _reloadSelectedPilot({
    required Emitter<PilotsState> emit,
    required PilotsLoaded previous,
    required int selectedIndex,
    required String pilotId,
    required String mutationMessage,
  }) async {
    final detailedPilot = await _repository.fetchPilotDetails(pilotId);
    emit(
      previous.copyWith(
        pilots: _replacePilot(previous.pilots, selectedIndex, detailedPilot),
        detailsStatus: PilotDetailsStatus.loaded,
        mutationMessage: mutationMessage,
        clearMutatingServiceId: true,
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is PilotsRepositoryException) {
      return error.message;
    }

    return 'Unable to load pilot data.';
  }
}

class _PilotMutationContext {
  const _PilotMutationContext({
    required this.state,
    required this.pilot,
    required this.selectedIndex,
  });

  final PilotsLoaded state;
  final PilotAdminViewData pilot;
  final int selectedIndex;
}
