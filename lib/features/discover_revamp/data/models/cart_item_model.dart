import '../../domain/entities/cart_item_entity.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String agentId;
  final String agentName;
  final double price;
  final String? imageUrl;
  final String? description;
  final int quantity;
  final String addedAt; // ISO 8601 string for JSON serialization

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.agentId,
    required this.agentName,
    required this.price,
    this.imageUrl,
    this.description,
    required this.quantity,
    required this.addedAt,
  });

  /// Create model from entity
  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      productId: entity.productId,
      productName: entity.productName,
      agentId: entity.agentId,
      agentName: entity.agentName,
      price: entity.price,
      imageUrl: entity.imageUrl,
      description: entity.description,
      quantity: entity.quantity,
      addedAt: entity.addedAt.toIso8601String(),
    );
  }

  /// Convert model to entity
  CartItemEntity toEntity() {
    return CartItemEntity(
      productId: productId,
      productName: productName,
      agentId: agentId,
      agentName: agentName,
      price: price,
      imageUrl: imageUrl,
      description: description,
      quantity: quantity,
      addedAt: DateTime.parse(addedAt),
    );
  }

  /// Create model from JSON
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      addedAt: json['addedAt'] as String,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'agentId': agentId,
      'agentName': agentName,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }

  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? agentId,
    String? agentName,
    double? price,
    String? imageUrl,
    String? description,
    int? quantity,
    String? addedAt,
  }) {
    return CartItemModel(
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
}
