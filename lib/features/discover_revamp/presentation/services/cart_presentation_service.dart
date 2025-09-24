import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/services/cart_business_service.dart';

/// Presentation service for cart operations
/// Coordinates between UI and business logic following clean architecture
/// Implemented as singleton to ensure shared state across all widgets
class CartPresentationService {
  static CartPresentationService? _instance;
  static final StreamController<CartEntity> _cartStreamController =
      StreamController<CartEntity>.broadcast();

  final CartBusinessService _cartBusinessService;

  CartPresentationService._internal({CartBusinessService? cartBusinessService})
    : _cartBusinessService = cartBusinessService ?? CartBusinessService() {
    // Initialize with current cart state
    _initializeCart();
  }

  /// Get the singleton instance
  factory CartPresentationService({CartBusinessService? cartBusinessService}) {
    _instance ??= CartPresentationService._internal(
      cartBusinessService: cartBusinessService,
    );
    return _instance!;
  }

  /// Get the singleton instance (shorter syntax)
  static CartPresentationService get instance => CartPresentationService();

  /// Stream of cart updates for real-time UI synchronization
  Stream<CartEntity> get cartStream async* {
    // Always emit current cart first
    final currentCart = await _cartBusinessService.getCurrentCart();
    yield currentCart;

    // Then emit updates
    yield* _cartStreamController.stream;
  }

  /// Initialize cart with current state
  void _initializeCart() async {
    final cart = await _cartBusinessService.getCurrentCart();
    _cartStreamController.add(cart);
  }

  /// Get current cart
  Future<CartEntity> getCurrentCart() async {
    final cart = await _cartBusinessService.getCurrentCart();
    _cartStreamController.add(cart);
    return cart;
  }

  /// Add product to cart with UI-friendly response
  Future<CartActionResult> addToCart({
    required String productId,
    required String productName,
    required String agentId,
    required String agentName,
    required double price,
    String? imageUrl,
    String? description,
    int quantity = 1,
  }) async {
    final result = await _cartBusinessService.addToCart(
      productId: productId,
      productName: productName,
      agentId: agentId,
      agentName: agentName,
      price: price,
      imageUrl: imageUrl,
      description: description,
      quantity: quantity,
    );

    if (result.isSuccess) {
      _cartStreamController.add(result.cart!);
      return CartActionResult.success(
        message: '$productName added to cart',
        cart: result.cart!,
      );
    } else if (result.isAlreadyInCart) {
      return CartActionResult.info(
        message: '$productName is already in your cart',
      );
    } else if (result.isDifferentAgent) {
      return CartActionResult.requiresConfirmation(
        message:
            'Your cart contains items from ${result.currentAgentName}. Replace with items from $agentName?',
        currentAgentName: result.currentAgentName!,
        newAgentName: agentName,
        actionData: AddToCartData(
          productId: productId,
          productName: productName,
          agentId: agentId,
          agentName: agentName,
          price: price,
          imageUrl: imageUrl,
          description: description,
          quantity: quantity,
        ),
      );
    } else {
      return CartActionResult.error(
        message: result.errorMessage ?? 'Failed to add item to cart',
      );
    }
  }

  /// Remove product from cart
  Future<CartActionResult> removeFromCart(
    String productId,
    String agentId,
  ) async {
    final result = await _cartBusinessService.removeFromCart(productId);

    if (result.isSuccess) {
      _cartStreamController.add(result.cart!);
      return CartActionResult.success(
        message: 'Item removed from cart',
        cart: result.cart!,
      );
    } else {
      return CartActionResult.error(
        message: result.errorMessage ?? 'Failed to remove item',
      );
    }
  }

  /// Update item quantity
  Future<CartActionResult> updateQuantity(
    String productId,
    String productName,
    int quantity,
  ) async {
    final result = await _cartBusinessService.updateQuantity(
      productId,
      quantity,
    );

    if (result.isSuccess) {
      _cartStreamController.add(result.cart!);
      return CartActionResult.success(
        message: quantity > 0
            ? '$productName quantity updated'
            : '$productName removed from cart',
        cart: result.cart!,
      );
    } else {
      return CartActionResult.error(
        message: result.errorMessage ?? 'Failed to update quantity',
      );
    }
  }

  /// Clear entire cart
  Future<CartActionResult> clearCart() async {
    final result = await _cartBusinessService.clearCart();

    if (result.isSuccess) {
      _cartStreamController.add(result.cart!);
      return CartActionResult.success(
        message: 'Cart cleared',
        cart: result.cart!,
      );
    } else {
      return CartActionResult.error(
        message: result.errorMessage ?? 'Failed to clear cart',
      );
    }
  }

  /// Confirm and execute agent switch (clear cart and add new item)
  Future<CartActionResult> confirmAgentSwitch(AddToCartData actionData) async {
    final result = await _cartBusinessService.clearAndAddFromNewAgent(
      productId: actionData.productId,
      productName: actionData.productName,
      agentId: actionData.agentId,
      agentName: actionData.agentName,
      price: actionData.price,
      imageUrl: actionData.imageUrl,
      description: actionData.description,
      quantity: actionData.quantity,
    );

    if (result.isSuccess) {
      _cartStreamController.add(result.cart!);
      return CartActionResult.success(
        message: '${actionData.productName} added to cart',
        cart: result.cart!,
      );
    } else {
      return CartActionResult.error(
        message: result.errorMessage ?? 'Failed to switch agents',
      );
    }
  }

  /// Check if product is in cart
  Future<bool> isProductInCart(String productId) async {
    return await _cartBusinessService.isProductInCart(productId);
  }

  /// Check if product from specific agent is in cart
  Future<bool> isProductInCartFromAgent(
    String productId,
    String agentId,
  ) async {
    return await _cartBusinessService.isProductInCartFromAgent(
      productId,
      agentId,
    );
  }

  /// Get cart item for specific product
  Future<CartItemEntity?> getCartItem(String productId) async {
    return await _cartBusinessService.getCartItem(productId);
  }

  /// Get cart item for specific product from specific agent
  Future<CartItemEntity?> getCartItemFromAgent(
    String productId,
    String agentId,
  ) async {
    return await _cartBusinessService.getCartItemFromAgent(productId, agentId);
  }

  /// Get cart count for UI badge
  Future<int> getCartCount() async {
    final cart = await _cartBusinessService.getCurrentCart();
    return cart.itemCount;
  }

  /// Get cart total price
  Future<double> getCartTotal() async {
    final cart = await _cartBusinessService.getCurrentCart();
    return cart.totalPrice;
  }

  /// Refresh cart and notify listeners
  Future<CartEntity> refreshCart() async {
    final cart = await _cartBusinessService.refreshCart();
    _cartStreamController.add(cart);
    return cart;
  }

  /// Dispose resources
  /// Note: For singleton pattern, we don't dispose the shared stream controller
  /// unless the entire app is being disposed
  void dispose() {
    // Don't close the shared StreamController for singleton instance
    // The StreamController will be disposed when the app terminates
  }
}

/// UI-friendly result class for cart actions
class CartActionResult {
  final bool isSuccess;
  final bool isInfo;
  final bool requiresConfirmation;
  final String message;
  final CartEntity? cart;
  final String? currentAgentName;
  final String? newAgentName;
  final AddToCartData? actionData;

  const CartActionResult._({
    required this.isSuccess,
    this.isInfo = false,
    this.requiresConfirmation = false,
    required this.message,
    this.cart,
    this.currentAgentName,
    this.newAgentName,
    this.actionData,
  });

  factory CartActionResult.success({
    required String message,
    required CartEntity cart,
  }) {
    return CartActionResult._(isSuccess: true, message: message, cart: cart);
  }

  factory CartActionResult.info({required String message}) {
    return CartActionResult._(isSuccess: false, isInfo: true, message: message);
  }

  factory CartActionResult.error({required String message}) {
    return CartActionResult._(isSuccess: false, message: message);
  }

  factory CartActionResult.requiresConfirmation({
    required String message,
    required String currentAgentName,
    required String newAgentName,
    required AddToCartData actionData,
  }) {
    return CartActionResult._(
      isSuccess: false,
      requiresConfirmation: true,
      message: message,
      currentAgentName: currentAgentName,
      newAgentName: newAgentName,
      actionData: actionData,
    );
  }
}

/// Data class for pending add to cart action
class AddToCartData {
  final String productId;
  final String productName;
  final String agentId;
  final String agentName;
  final double price;
  final String? imageUrl;
  final String? description;
  final int quantity;

  const AddToCartData({
    required this.productId,
    required this.productName,
    required this.agentId,
    required this.agentName,
    required this.price,
    this.imageUrl,
    this.description,
    this.quantity = 1,
  });
}
