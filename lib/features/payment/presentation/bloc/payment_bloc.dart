import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/usecases/create_payment_intent.dart';
import '../../domain/usecases/confirm_payment.dart';
import '../../domain/usecases/initiate_razorpay_payment.dart';
import '../../domain/usecases/process_razorpay_payment.dart';
import '../../../orders/domain/usecases/create_order.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../discover_revamp/presentation/services/cart_presentation_service.dart';
import '../../../checkout/data/data_sources/checkout_firebase_data_source.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePaymentIntent createPaymentIntent;
  final ConfirmPayment confirmPayment;
  final InitiateRazorpayPayment initiateRazorpayPayment;
  final ProcessRazorpayPayment processRazorpayPayment;
  final CreateOrder createOrder;

  PaymentBloc({
    required this.createPaymentIntent,
    required this.confirmPayment,
    required this.initiateRazorpayPayment,
    required this.processRazorpayPayment,
    required this.createOrder,
  }) : super(const PaymentInitial()) {
    // Stripe events
    on<CreatePaymentIntentEvent>(_onCreatePaymentIntent);
    on<ConfirmPaymentEvent>(_onConfirmPayment);

    // Razorpay events
    on<InitiateRazorpayPaymentEvent>(_onInitiateRazorpayPayment);
    on<ProcessRazorpayPaymentEvent>(_onProcessRazorpayPayment);
    on<RazorpayPaymentSuccessEvent>(_onRazorpayPaymentSuccess);
    on<RazorpayPaymentErrorEvent>(_onRazorpayPaymentError);

    // Order creation event
    on<CreateOrderAfterPaymentEvent>(_onCreateOrderAfterPayment);

    // Common events
    on<ResetPaymentEvent>(_onResetPayment);
  }

  Future<void> _onCreatePaymentIntent(
    CreatePaymentIntentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final paymentIntent = await createPaymentIntent(event.paymentRequest);
      emit(PaymentIntentCreated(paymentIntent));
    } catch (e) {
      emit(PaymentError('Failed to create payment: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final currentState = state;
    if (currentState is PaymentIntentCreated) {
      emit(PaymentProcessing(currentState.paymentIntent));
      try {
        final success = await confirmPayment(event.clientSecret);
        if (success) {
          emit(
            PaymentSuccess(
              paymentId: currentState.paymentIntent.id,
              amount: currentState.paymentIntent.amount,
              currency: currentState.paymentIntent.currency,
              paymentMethod: 'stripe',
            ),
          );
        } else {
          emit(const PaymentError('Payment confirmation failed'));
        }
      } catch (e) {
        emit(PaymentError('Payment failed: ${e.toString()}'));
      }
    } else {
      emit(const PaymentError('No payment intent available'));
    }
  }

  // Razorpay event handlers
  Future<void> _onInitiateRazorpayPayment(
    InitiateRazorpayPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final result = await initiateRazorpayPayment(event.paymentRequest);
      result.fold(
        (error) => emit(PaymentError(error)),
        (paymentOptions) => emit(RazorpayPaymentInitiated(paymentOptions)),
      );
    } catch (e) {
      emit(
        PaymentError('Failed to initiate Razorpay payment: ${e.toString()}'),
      );
    }
  }

  Future<void> _onProcessRazorpayPayment(
    ProcessRazorpayPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(
      RazorpayPaymentPending(
        paymentResponse: event.paymentResponse,
        amount: event.amount,
        currency: event.currency,
      ),
    );

    try {
      final result = await processRazorpayPayment(
        event.paymentResponse,
        event.amount,
        event.currency,
      );
      result.fold(
        (error) => emit(PaymentError(error)),
        (payment) => emit(
          PaymentSuccess(
            paymentId: payment.paymentId,
            amount: payment.amount,
            currency: payment.currency,
            paymentMethod: 'razorpay',
          ),
        ),
      );
    } catch (e) {
      emit(PaymentError('Failed to process Razorpay payment: ${e.toString()}'));
    }
  }

  void _onRazorpayPaymentSuccess(
    RazorpayPaymentSuccessEvent event,
    Emitter<PaymentState> emit,
  ) {
    // This will be handled by ProcessRazorpayPaymentEvent
    // We can emit a temporary state here if needed
    emit(const PaymentLoading());
  }

  void _onRazorpayPaymentError(
    RazorpayPaymentErrorEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentError('Razorpay payment failed: ${event.error}'));
  }

  Future<void> _onCreateOrderAfterPayment(
    CreateOrderAfterPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(const PaymentError('User not authenticated'));
        return;
      }

      // Create order from payment data
      final paymentDetails = PaymentDetailsEntity(
        paymentId: event.paymentId,
        orderId: '', // Will be set after order creation
        method: event.paymentMethod,
        status: 'captured',
        amount: event.amount,
        currency: event.currency,
        paidAt: DateTime.now(),
      );

      final deliveryAddress = AddressEntity(
        street: event.additionalData?['street'] ?? 'Not provided',
        city: event.additionalData?['city'] ?? 'Not provided',
        state: event.additionalData?['state'] ?? 'Not provided',
        postalCode: event.additionalData?['postalCode'] ?? '000000',
        country: event.additionalData?['country'] ?? 'India',
        fullName: event.additionalData?['fullName'] ?? currentUser.displayName,
        phoneNumber: event.additionalData?['phoneNumber'] ?? 'Not provided',
      );

      final order = OrderEntity(
        id: '', // Will be generated by Firestore
        userId: currentUser.uid,
        agentId: event.additionalData?['agentId'] ?? 'unknown',
        agentName: event.additionalData?['agentName'] ?? 'Unknown Agent',
        totalAmount: event.amount,
        currency: event.currency,
        status: 'confirmed',
        createdAt: DateTime.now(),
        deliveryAddress: deliveryAddress,
        paymentDetails: paymentDetails,
        items: [], // This would come from cart data in a real implementation
      );

      final result = await createOrder(order);
      result.fold(
        (error) => emit(PaymentError('Failed to create order: $error')),
        (orderId) => emit(
          OrderCreated(
            orderId: orderId,
            paymentId: event.paymentId,
            amount: event.amount,
            currency: event.currency,
            paymentMethod: event.paymentMethod,
          ),
        ),
      );
    } catch (e) {
      emit(PaymentError('Failed to create order: ${e.toString()}'));
    }
  }

  void _onResetPayment(ResetPaymentEvent event, Emitter<PaymentState> emit) {
    emit(const PaymentInitial());
  }
}
