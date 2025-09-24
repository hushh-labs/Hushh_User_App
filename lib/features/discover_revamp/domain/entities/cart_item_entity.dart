import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String agentId;
  final String agentName;
  final double price;
  final String? imageUrl;
  final String? description;
  final int quantity;
  final DateTime addedAt;

  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.agentId,
    required this.agentName,
    required this.price,
    this.imageUrl,
    this.description,
    this.quantity = 1,
    required this.addedAt,
  });

  CartItemEntity copyWith({
    String? productId,
    String? productName,
    String? agentId,
    String? agentName,
    double? price,
    String? imageUrl,
    String? description,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => price * quantity;

  @override
  List<Object?> get props => [
    productId,
    productName,
    agentId,
    agentName,
    price,
    imageUrl,
    description,
    quantity,
    addedAt,
  ];
}
