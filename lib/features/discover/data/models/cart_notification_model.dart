import '../../domain/entities/cart_notification_entity.dart';

class CartNotificationModel extends CartNotificationEntity {
  const CartNotificationModel({
    required super.productId,
    required super.productName,
    required super.productPrice,
    super.productImage,
    required super.agentId,
    required super.agentName,
    required super.userId,
    required super.userName,
    required super.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'agentId': agentId,
      'agentName': agentName,
      'userId': userId,
      'userName': userName,
      'quantity': quantity,
    };
  }
}
