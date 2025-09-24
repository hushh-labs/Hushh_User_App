import '../../domain/entities/cart_entity.dart';
import 'cart_item_model.dart';

class CartModel {
  final List<CartItemModel> items;
  final String? currentAgentId;
  final String? currentAgentName;
  final String lastUpdated; // ISO 8601 string for JSON serialization

  const CartModel({
    this.items = const [],
    this.currentAgentId,
    this.currentAgentName,
    required this.lastUpdated,
  });

  /// Create model from entity
  factory CartModel.fromEntity(CartEntity entity) {
    return CartModel(
      items: entity.items
          .map((item) => CartItemModel.fromEntity(item))
          .toList(),
      currentAgentId: entity.currentAgentId,
      currentAgentName: entity.currentAgentName,
      lastUpdated: entity.lastUpdated.toIso8601String(),
    );
  }

  /// Convert model to entity
  CartEntity toEntity() {
    return CartEntity(
      items: items.map((item) => item.toEntity()).toList(),
      currentAgentId: currentAgentId,
      currentAgentName: currentAgentName,
      lastUpdated: DateTime.parse(lastUpdated),
    );
  }

  /// Create model from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map(
          (itemJson) =>
              CartItemModel.fromJson(itemJson as Map<String, dynamic>),
        )
        .toList();

    return CartModel(
      items: items,
      currentAgentId: json['currentAgentId'] as String?,
      currentAgentName: json['currentAgentName'] as String?,
      lastUpdated: json['lastUpdated'] as String,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'currentAgentId': currentAgentId,
      'currentAgentName': currentAgentName,
      'lastUpdated': lastUpdated,
    };
  }

  CartModel copyWith({
    List<CartItemModel>? items,
    String? currentAgentId,
    String? currentAgentName,
    String? lastUpdated,
  }) {
    return CartModel(
      items: items ?? this.items,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      currentAgentName: currentAgentName ?? this.currentAgentName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
