import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout_entity.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckoutDataEvent extends CheckoutEvent {
  final String uid;

  const LoadCheckoutDataEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateCheckoutFieldEvent extends CheckoutEvent {
  final String fieldName;
  final String value;

  const UpdateCheckoutFieldEvent(this.fieldName, this.value);

  @override
  List<Object?> get props => [fieldName, value];
}

class SubmitCheckoutDataEvent extends CheckoutEvent {
  final String uid;

  const SubmitCheckoutDataEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadUserBasicInfoEvent extends CheckoutEvent {
  final String uid;

  const LoadUserBasicInfoEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ResetCheckoutEvent extends CheckoutEvent {
  const ResetCheckoutEvent();
}
