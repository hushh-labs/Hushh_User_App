import '../../domain/entities/razorpay_payment_entity.dart';

class RazorpayPaymentModel {
  final String orderId;
  final String paymentId;
  final String signature;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  const RazorpayPaymentModel({
    required this.orderId,
    required this.paymentId,
    required this.signature,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory RazorpayPaymentModel.fromJson(Map<String, dynamic> json) {
    return RazorpayPaymentModel(
      orderId: json['order_id'] as String,
      paymentId: json['payment_id'] as String,
      signature: json['signature'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'payment_id': paymentId,
      'signature': signature,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RazorpayPaymentModel.fromRazorpayResponse(
    Map<String, dynamic> response,
    double amount,
    String currency,
  ) {
    // Handle null values safely
    final orderId = response['razorpay_order_id']?.toString() ?? '';
    final paymentId = response['razorpay_payment_id']?.toString() ?? '';
    final signature = response['razorpay_signature']?.toString() ?? '';

    return RazorpayPaymentModel(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      amount: amount,
      currency: currency,
      status: 'captured',
      createdAt: DateTime.now(),
    );
  }

  RazorpayPaymentEntity toEntity() {
    return RazorpayPaymentEntity(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      amount: amount,
      currency: currency,
      status: status,
      createdAt: createdAt,
    );
  }
}
