import 'package:equatable/equatable.dart';

class RazorpayPaymentEntity extends Equatable {
  final String orderId;
  final String paymentId;
  final String signature;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  const RazorpayPaymentEntity({
    required this.orderId,
    required this.paymentId,
    required this.signature,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    orderId,
    paymentId,
    signature,
    amount,
    currency,
    status,
    createdAt,
  ];
}
