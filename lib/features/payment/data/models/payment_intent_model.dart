import '../../domain/entities/payment_intent_entity.dart';

class PaymentIntentModel extends PaymentIntentEntity {
  const PaymentIntentModel({
    required super.id,
    required super.clientSecret,
    required super.amount,
    required super.currency,
    required super.status,
    super.description,
    super.metadata,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      id: json['id'] as String,
      clientSecret: json['client_secret'] as String,
      amount: (json['amount'] as int) / 100.0, // Convert from cents
      currency: json['currency'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_secret': clientSecret,
      'amount': (amount * 100).round(), // Convert to cents
      'currency': currency,
      'status': status,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory PaymentIntentModel.fromEntity(PaymentIntentEntity entity) {
    return PaymentIntentModel(
      id: entity.id,
      clientSecret: entity.clientSecret,
      amount: entity.amount,
      currency: entity.currency,
      status: entity.status,
      description: entity.description,
      metadata: entity.metadata,
    );
  }

  PaymentIntentEntity toEntity() {
    return PaymentIntentEntity(
      id: id,
      clientSecret: clientSecret,
      amount: amount,
      currency: currency,
      status: status,
      description: description,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    return 'PaymentIntentModel(id: $id, clientSecret: $clientSecret, amount: $amount, currency: $currency, status: $status, description: $description)';
  }
}
