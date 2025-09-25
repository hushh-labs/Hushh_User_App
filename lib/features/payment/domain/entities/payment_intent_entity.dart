class PaymentIntentEntity {
  final String id;
  final String clientSecret;
  final double amount;
  final String currency;
  final String status;
  final String? description;
  final Map<String, dynamic>? metadata;

  const PaymentIntentEntity({
    required this.id,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    this.metadata,
  });

  PaymentIntentEntity copyWith({
    String? id,
    String? clientSecret,
    double? amount,
    String? currency,
    String? status,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentIntentEntity(
      id: id ?? this.id,
      clientSecret: clientSecret ?? this.clientSecret,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentIntentEntity &&
        other.id == id &&
        other.clientSecret == clientSecret &&
        other.amount == amount &&
        other.currency == currency &&
        other.status == status &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clientSecret.hashCode ^
        amount.hashCode ^
        currency.hashCode ^
        status.hashCode ^
        description.hashCode;
  }

  @override
  String toString() {
    return 'PaymentIntentEntity(id: $id, clientSecret: $clientSecret, amount: $amount, currency: $currency, status: $status, description: $description)';
  }
}
