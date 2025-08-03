import 'package:equatable/equatable.dart';

class CartNotificationEntity extends Equatable {
  final String productId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final String agentId;
  final String agentName;
  final String userId;
  final String userName;
  final int quantity;

  const CartNotificationEntity({
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.agentId,
    required this.agentName,
    required this.userId,
    required this.userName,
    required this.quantity,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    productPrice,
    productImage,
    agentId,
    agentName,
    userId,
    userName,
    quantity,
  ];
}
