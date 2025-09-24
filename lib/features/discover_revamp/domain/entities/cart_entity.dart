import 'package:equatable/equatable.dart';
import 'cart_item_entity.dart';

class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final String? currentAgentId;
  final String? currentAgentName;
  final DateTime lastUpdated;

  const CartEntity({
    this.items = const [],
    this.currentAgentId,
    this.currentAgentName,
    required this.lastUpdated,
  });

  CartEntity copyWith({
    List<CartItemEntity>? items,
    String? currentAgentId,
    String? currentAgentName,
    DateTime? lastUpdated,
  }) {
    return CartEntity(
      items: items ?? this.items,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      currentAgentName: currentAgentName ?? this.currentAgentName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Business logic methods
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  CartItemEntity? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasItemsFromAgent(String agentId) {
    return items.any((item) => item.agentId == agentId);
  }

  bool canAddItemFromAgent(String agentId) {
    if (isEmpty) return true;
    return currentAgentId == agentId;
  }

  List<String> get agentIds {
    return items.map((item) => item.agentId).toSet().toList();
  }

  CartEntity clearCart() {
    return CartEntity(
      items: [],
      currentAgentId: null,
      currentAgentName: null,
      lastUpdated: DateTime.now(),
    );
  }

  CartEntity addItem(CartItemEntity item) {
    final updatedItems = List<CartItemEntity>.from(items);

    // Check if item already exists
    final existingIndex = updatedItems.indexWhere(
      (existing) => existing.productId == item.productId,
    );

    if (existingIndex >= 0) {
      // Update quantity of existing item
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      // Add new item
      updatedItems.add(item);
    }

    return copyWith(
      items: updatedItems,
      currentAgentId: item.agentId,
      currentAgentName: item.agentName,
      lastUpdated: DateTime.now(),
    );
  }

  CartEntity removeItem(String productId) {
    final updatedItems = items
        .where((item) => item.productId != productId)
        .toList();

    return copyWith(
      items: updatedItems,
      currentAgentId: updatedItems.isEmpty ? null : currentAgentId,
      currentAgentName: updatedItems.isEmpty ? null : currentAgentName,
      lastUpdated: DateTime.now(),
    );
  }

  CartEntity updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return copyWith(items: updatedItems, lastUpdated: DateTime.now());
  }

  @override
  List<Object?> get props => [
    items,
    currentAgentId,
    currentAgentName,
    lastUpdated,
  ];
}
