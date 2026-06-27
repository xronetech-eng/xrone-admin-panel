part of 'pilot_management_bloc.dart';

sealed class PilotsManagementState extends Equatable {
  const PilotsManagementState();

  @override
  List<Object> get props => [];
}

final class PilotsManagementInitial extends PilotsManagementState {}
