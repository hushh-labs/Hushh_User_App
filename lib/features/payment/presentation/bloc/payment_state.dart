import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_intent_entity.dart';
import '../../domain/entities/razorpay_payment_entity.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

// Stripe States
class PaymentIntentCreated extends PaymentState {
  final PaymentIntentEntity paymentIntent;

  const PaymentIntentCreated(this.paymentIntent);

  @override
  List<Object?> get props => [paymentIntent];
}

class StripePaymentSuccess extends PaymentState {
  final PaymentIntentEntity paymentIntent;

  const StripePaymentSuccess(this.paymentIntent);

  @override
  List<Object?> get props => [paymentIntent];
}

class PaymentProcessing extends PaymentState {
  final PaymentIntentEntity paymentIntent;

  const PaymentProcessing(this.paymentIntent);

  @override
  List<Object?> get props => [paymentIntent];
}

// Razorpay States
class RazorpayPaymentInitiated extends PaymentState {
  final Map<String, dynamic> paymentOptions;

  const RazorpayPaymentInitiated(this.paymentOptions);

  @override
  List<Object?> get props => [paymentOptions];
}

class RazorpayPaymentSuccess extends PaymentState {
  final RazorpayPaymentEntity payment;

  const RazorpayPaymentSuccess(this.payment);

  @override
  List<Object?> get props => [payment];
}

class RazorpayPaymentPending extends PaymentState {
  final Map<String, dynamic> paymentResponse;
  final double amount;
  final String currency;

  const RazorpayPaymentPending({
    required this.paymentResponse,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [paymentResponse, amount, currency];
}

// Generic success state for both payment methods
class PaymentSuccess extends PaymentState {
  final String paymentId;
  final double amount;
  final String currency;
  final String paymentMethod;

  const PaymentSuccess({
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [paymentId, amount, currency, paymentMethod];
}

class OrderCreated extends PaymentState {
  final String orderId;
  final String paymentId;
  final double amount;
  final String currency;
  final String paymentMethod;

  const OrderCreated({
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    orderId,
    paymentId,
    amount,
    currency,
    paymentMethod,
  ];
}
