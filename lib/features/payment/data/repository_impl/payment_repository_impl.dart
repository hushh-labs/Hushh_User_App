import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/config/remote_config_service.dart';
import '../../domain/entities/payment_intent_entity.dart';
import '../../domain/entities/razorpay_payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../data_sources/stripe_api_data_source.dart';
import '../data_sources/razorpay_api_data_source.dart';
import '../models/payment_request_model.dart';
import '../models/razorpay_request_model.dart';
import '../models/razorpay_payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final StripeApiDataSource? stripeApiDataSource;
  final RazorpayApiDataSource? razorpayApiDataSource;

  PaymentRepositoryImpl({
    this.stripeApiDataSource,
    this.razorpayApiDataSource,
  }) {
    if (stripeApiDataSource == null && razorpayApiDataSource == null) {
      throw Exception('At least one payment data source must be provided');
    }
  }

  @override
  Future<PaymentIntentEntity> createPaymentIntent(
    PaymentRequestModel request,
  ) async {
    if (stripeApiDataSource == null) {
      throw Exception('Stripe not configured. Please set STRIPE_SECRET_KEY');
    }

    // Check if we're in demo mode (secret key is placeholder)
    final stripeSecretKey = RemoteConfigService.stripeSecretKey;
    if (stripeSecretKey.isEmpty ||
        stripeSecretKey.contains('your_secret_key_here')) {
      // Demo mode - create a mock payment intent for testing
      return PaymentIntentEntity(
        id: 'pi_demo_${DateTime.now().millisecondsSinceEpoch}',
        clientSecret:
            'pi_demo_${DateTime.now().millisecondsSinceEpoch}_secret_demo',
        amount: request.amount,
        currency: request.currency,
        status: 'requires_payment_method',
      );
    }

    try {
      final paymentIntentModel = await stripeApiDataSource!.createPaymentIntent(
        request,
      );
      return paymentIntentModel.toEntity();
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  @override
  Future<bool> confirmPayment(String paymentIntentClientSecret) async {
    if (stripeApiDataSource == null) {
      throw Exception('Stripe not configured. Please set STRIPE_SECRET_KEY');
    }

    // Check if this is a demo payment (demo client secret)
    if (paymentIntentClientSecret.contains('_secret_demo')) {
      // Demo mode - simulate successful payment
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate processing time
      return true; // Simulate successful payment
    }

    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      return result.status == PaymentIntentsStatus.Succeeded;
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  @override
  Future<String> getPaymentStatus(String paymentIntentId) async {
    if (stripeApiDataSource == null) {
      throw Exception('Stripe not configured. Please set STRIPE_SECRET_KEY');
    }
    try {
      return await stripeApiDataSource!.getPaymentStatus(paymentIntentId);
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  // Razorpay methods
  @override
  Future<Map<String, dynamic>> initiateRazorpayPayment(
    RazorpayRequestModel request,
  ) async {
    if (razorpayApiDataSource == null) {
      throw Exception('Razorpay not configured. Please set RAZORPAY_KEY_ID');
    }
    try {
      return await razorpayApiDataSource!.initiatePayment(request);
    } catch (e) {
      throw Exception('Failed to initiate Razorpay payment: $e');
    }
  }

  @override
  Future<RazorpayPaymentEntity> processRazorpayPayment(
    Map<String, dynamic> paymentResponse,
    double amount,
    String currency,
  ) async {
    try {
      final paymentModel = RazorpayPaymentModel.fromRazorpayResponse(
        paymentResponse,
        amount,
        currency,
      );
      return paymentModel.toEntity();
    } catch (e) {
      throw Exception('Failed to process Razorpay payment: $e');
    }
  }

  @override
  Future<bool> verifyRazorpayPayment(RazorpayPaymentEntity payment) async {
    if (razorpayApiDataSource == null) {
      throw Exception('Razorpay not configured. Please set RAZORPAY_KEY_ID');
    }
    try {
      final paymentModel = RazorpayPaymentModel(
        orderId: payment.orderId,
        paymentId: payment.paymentId,
        signature: payment.signature,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        createdAt: payment.createdAt,
      );
      return await razorpayApiDataSource!.verifyPayment(paymentModel);
    } catch (e) {
      throw Exception('Failed to verify Razorpay payment: $e');
    }
  }
}
