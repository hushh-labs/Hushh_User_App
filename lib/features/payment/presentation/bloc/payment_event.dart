import 'package:equatable/equatable.dart';
import '../../data/models/payment_request_model.dart';
import '../../data/models/razorpay_request_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

// Stripe Events
class CreatePaymentIntentEvent extends PaymentEvent {
  final PaymentRequestModel paymentRequest;

  const CreatePaymentIntentEvent(this.paymentRequest);

  @override
  List<Object?> get props => [paymentRequest];
}

class ConfirmPaymentEvent extends PaymentEvent {
  final String clientSecret;

  const ConfirmPaymentEvent(this.clientSecret);

  @override
  List<Object?> get props => [clientSecret];
}

// Razorpay Events
class InitiateRazorpayPaymentEvent extends PaymentEvent {
  final RazorpayRequestModel paymentRequest;

  const InitiateRazorpayPaymentEvent(this.paymentRequest);

  @override
  List<Object?> get props => [paymentRequest];
}

class ProcessRazorpayPaymentEvent extends PaymentEvent {
  final Map<String, dynamic> paymentResponse;
  final double amount;
  final String currency;

  const ProcessRazorpayPaymentEvent({
    required this.paymentResponse,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [paymentResponse, amount, currency];
}

class RazorpayPaymentSuccessEvent extends PaymentEvent {
  final Map<String, dynamic> paymentResponse;

  const RazorpayPaymentSuccessEvent(this.paymentResponse);

  @override
  List<Object?> get props => [paymentResponse];
}

class RazorpayPaymentErrorEvent extends PaymentEvent {
  final String error;

  const RazorpayPaymentErrorEvent(this.error);

  @override
  List<Object?> get props => [error];
}

// Order Creation Event
class CreateOrderAfterPaymentEvent extends PaymentEvent {
  final String paymentId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final Map<String, dynamic>? additionalData;

  const CreateOrderAfterPaymentEvent({
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.additionalData,
  });

  @override
  List<Object?> get props => [
    paymentId,
    amount,
    currency,
    paymentMethod,
    additionalData,
  ];
}

// Common Events
class ResetPaymentEvent extends PaymentEvent {
  const ResetPaymentEvent();
}
