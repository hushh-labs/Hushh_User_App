import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String agentId;
  final String agentName;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final String currency;
  final AddressEntity deliveryAddress;
  final PaymentDetailsEntity paymentDetails;
  final String status;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.agentName,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.deliveryAddress,
    required this.paymentDetails,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    agentId,
    agentName,
    items,
    totalAmount,
    currency,
    deliveryAddress,
    paymentDetails,
    status,
    createdAt,
  ];
}

class OrderItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String? description;
  final String? imageUrl;
  final double price;
  final int quantity;
  final double totalPrice;

  const OrderItemEntity({
    required this.productId,
    required this.productName,
    this.description,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    description,
    imageUrl,
    price,
    quantity,
    totalPrice,
  ];
}

class AddressEntity extends Equatable {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? fullName;
  final String? phoneNumber;

  const AddressEntity({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.fullName,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    street,
    city,
    state,
    postalCode,
    country,
    fullName,
    phoneNumber,
  ];
}

class PaymentDetailsEntity extends Equatable {
  final String paymentId;
  final String orderId;
  final String? signature;
  final String method; // 'razorpay'
  final String status; // 'captured', 'failed', etc.
  final double amount;
  final String currency;
  final DateTime? paidAt;

  const PaymentDetailsEntity({
    required this.paymentId,
    required this.orderId,
    this.signature,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
  });

  @override
  List<Object?> get props => [
    paymentId,
    orderId,
    signature,
    method,
    status,
    amount,
    currency,
    paidAt,
  ];
}
