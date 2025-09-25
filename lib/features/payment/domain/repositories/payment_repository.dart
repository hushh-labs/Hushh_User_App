import '../entities/payment_intent_entity.dart';
import '../entities/razorpay_payment_entity.dart';
import '../../data/models/payment_request_model.dart';
import '../../data/models/razorpay_request_model.dart';

abstract class PaymentRepository {
  // Stripe payment methods
  /// Create a payment intent with Stripe
  Future<PaymentIntentEntity> createPaymentIntent(PaymentRequestModel request);

  /// Confirm payment with payment method
  Future<bool> confirmPayment(String paymentIntentClientSecret);

  /// Get payment intent status
  Future<String> getPaymentStatus(String paymentIntentId);

  // Razorpay payment methods
  /// Initiate payment with Razorpay
  Future<Map<String, dynamic>> initiateRazorpayPayment(
    RazorpayRequestModel request,
  );

  /// Process Razorpay payment success
  Future<RazorpayPaymentEntity> processRazorpayPayment(
    Map<String, dynamic> paymentResponse,
    double amount,
    String currency,
  );

  /// Verify Razorpay payment
  Future<bool> verifyRazorpayPayment(RazorpayPaymentEntity payment);
}
