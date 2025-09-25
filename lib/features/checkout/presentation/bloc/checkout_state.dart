import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout_entity.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

class CheckoutLoaded extends CheckoutState {
  final CheckoutEntity checkoutData;

  const CheckoutLoaded(this.checkoutData);

  @override
  List<Object?> get props => [checkoutData];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

class CheckoutSubmitted extends CheckoutState {
  final CheckoutEntity checkoutData;

  const CheckoutSubmitted(this.checkoutData);

  @override
  List<Object?> get props => [checkoutData];
}

class CheckoutFieldUpdated extends CheckoutState {
  final CheckoutEntity checkoutData;

  const CheckoutFieldUpdated(this.checkoutData);

  @override
  List<Object?> get props => [checkoutData];
}
