import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/razorpay_request_model.dart';
import '../models/razorpay_payment_model.dart';

abstract class RazorpayApiDataSource {
  Future<Map<String, dynamic>> initiatePayment(RazorpayRequestModel request);
  Future<bool> verifyPayment(RazorpayPaymentModel payment);
}

class RazorpayApiDataSourceImpl implements RazorpayApiDataSource {
  final String keyId;
  late final Razorpay _razorpay;

  RazorpayApiDataSourceImpl({required this.keyId}) {
    _razorpay = Razorpay();
  }

  @override
  Future<Map<String, dynamic>> initiatePayment(
    RazorpayRequestModel request,
  ) async {
    try {
      // Check if we're in demo mode (missing secret key)
      final razorpaySecret = dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';
      if (razorpaySecret.isEmpty ||
          keyId.contains('your_actual_razorpay_key_id_here')) {
        // Demo mode - create mock payment options for testing
        final demoOrderId =
            'demo_order_${DateTime.now().millisecondsSinceEpoch}';
        return {
          'key': 'rzp_demo_key',
          'amount': (request.amount * 100).toInt(),
          'currency': request.currency.toUpperCase(),
          'name': 'Hushh (Demo)',
          'description': '${request.description} - Demo Mode',
          'order_id': demoOrderId,
          'prefill': {
            if (request.customerEmail != null) 'email': request.customerEmail,
            if (request.customerPhone != null) 'contact': request.customerPhone,
          },
          'theme': {'color': '#A342FF'},
          'demo_mode': true,
        };
      }

      // Real Razorpay payment flow
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      return request.toRazorpayOptions(keyId: keyId, orderId: orderId);
    } catch (e) {
      throw Exception('Failed to initiate Razorpay payment: $e');
    }
  }

  @override
  Future<bool> verifyPayment(RazorpayPaymentModel payment) async {
    try {
      // In a real implementation, you would verify the payment signature
      // with your backend server using the payment details

      // For now, we'll assume the payment is valid if we have all required fields
      final isValid =
          payment.orderId.isNotEmpty &&
          payment.paymentId.isNotEmpty &&
          payment.signature.isNotEmpty;

      return isValid;
    } catch (e) {
      throw Exception('Failed to verify Razorpay payment: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
