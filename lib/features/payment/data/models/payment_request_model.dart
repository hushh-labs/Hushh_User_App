class PaymentRequestModel {
  final double amount;
  final String currency;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? customerId;

  const PaymentRequestModel({
    required this.amount,
    this.currency = 'usd',
    this.description,
    this.metadata,
    this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': (amount * 100).round(), // Convert to cents
      'currency': currency,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (customerId != null) 'customer': customerId,
      'automatic_payment_methods': {'enabled': true},
    };
  }

  PaymentRequestModel copyWith({
    double? amount,
    String? currency,
    String? description,
    Map<String, dynamic>? metadata,
    String? customerId,
  }) {
    return PaymentRequestModel(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      customerId: customerId ?? this.customerId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentRequestModel &&
        other.amount == amount &&
        other.currency == currency &&
        other.description == description &&
        other.customerId == customerId;
  }

  @override
  int get hashCode {
    return amount.hashCode ^
        currency.hashCode ^
        description.hashCode ^
        customerId.hashCode;
  }

  @override
  String toString() {
    return 'PaymentRequestModel(amount: $amount, currency: $currency, description: $description, customerId: $customerId)';
  }
}
