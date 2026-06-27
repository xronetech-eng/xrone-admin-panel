part of 'payments_bloc.dart';

sealed class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object?> get props => [];
}

final class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
}

final class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

final class PaymentsEmpty extends PaymentsState {
  const PaymentsEmpty();
}

final class PaymentsFailure extends PaymentsState {
  const PaymentsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PaymentsLoaded extends PaymentsState {
  const PaymentsLoaded(this.data);

  final PaymentAdminData data;

  @override
  List<Object?> get props => [data];
}
