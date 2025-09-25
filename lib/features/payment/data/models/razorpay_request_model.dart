class RazorpayRequestModel {
  final double amount;
  final String currency;
  final String description;
  final String? customerId;
  final String? customerEmail;
  final String? customerPhone;

  const RazorpayRequestModel({
    required this.amount,
    required this.currency,
    required this.description,
    this.customerId,
    this.customerEmail,
    this.customerPhone,
  });

  factory RazorpayRequestModel.fromJson(Map<String, dynamic> json) {
    return RazorpayRequestModel(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      customerId: json['customerId'] as String?,
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'description': description,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
    };
  }

  // Convert to Razorpay options format
  Map<String, dynamic> toRazorpayOptions({
    required String keyId,
    required String orderId,
  }) {
    return {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'currency': currency.toUpperCase(),
      'name': 'Hushh',
      'description': description,
      // Remove order_id for simple testing - this requires backend integration
      // 'order_id': orderId,
      'prefill': {
        if (customerEmail != null) 'email': customerEmail,
        if (customerPhone != null) 'contact': customerPhone,
      },
      'theme': {'color': '#A342FF'},
    };
  }
}
