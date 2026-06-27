import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'pilot_management_event.dart';
part 'pilot_management_state.dart';

class PilotsManagementBloc
    extends Bloc<PilotsManagementEvent, PilotsManagementState> {
  PilotsManagementBloc() : super(PilotsManagementInitial()) {
    on<PilotsManagementEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
