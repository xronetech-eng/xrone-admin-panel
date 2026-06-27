import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/payments_model.dart';
import '../repository/payments_repository.dart';

part 'payments_event.dart';
part 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  PaymentsBloc({required PaymentsRepository repository})
    : _repository = repository,
      super(const PaymentsInitial()) {
    on<PaymentsRequested>(_onPaymentsRequested);
  }

  final PaymentsRepository _repository;

  Future<void> _onPaymentsRequested(
    PaymentsRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());

    try {
      final data = await _repository.load();
      if (data.isEmpty) {
        emit(const PaymentsEmpty());
        return;
      }

      emit(PaymentsLoaded(data));
    } on Object catch (error) {
      emit(PaymentsFailure(_errorMessage(error)));
    }
  }

  String _errorMessage(Object error) {
    if (error is PaymentsRepositoryException) {
      return error.message;
    }

    return 'Unable to load payment data.';
  }
}
