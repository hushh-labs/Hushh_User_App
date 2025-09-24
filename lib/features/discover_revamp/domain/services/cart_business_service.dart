import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';
import '../../data/services/cart_data_service.dart';

/// Business service for cart operations following clean architecture
/// Contains all cart business logic including single-agent validation
class CartBusinessService {
  final CartDataService _cartDataService;
  CartEntity? _currentCart;

  CartBusinessService({CartDataService? cartDataService})
    : _cartDataService = cartDataService ?? CartDataService();

  /// Get current cart state
  Future<CartEntity> getCurrentCart() async {
    if (_currentCart == null) {
      _currentCart = await _cartDataService.loadCart();
    }
    return _currentCart!;
  }

  /// Add item to cart with business validation
  Future<CartAddResult> addToCart({
    required String productId,
    required String productName,
    required String agentId,
    required String agentName,
    required double price,
    String? imageUrl,
    String? description,
    int quantity = 1,
  }) async {
    try {
      final currentCart = await getCurrentCart();

      // Check if item already exists in cart
      if (currentCart.containsProduct(productId)) {
        return CartAddResult.alreadyInCart();
      }

      // Check single-agent business rule
      if (!currentCart.canAddItemFromAgent(agentId)) {
        return CartAddResult.differentAgent(
          currentAgentName: currentCart.currentAgentName!,
        );
      }

      // Create new cart item
      final cartItem = CartItemEntity(
        productId: productId,
        productName: productName,
        agentId: agentId,
        agentName: agentName,
        price: price,
        imageUrl: imageUrl,
        description: description,
        quantity: quantity,
        addedAt: DateTime.now(),
      );

      // Add item to cart
      final updatedCart = currentCart.addItem(cartItem);

      // Persist changes
      await _cartDataService.saveCart(updatedCart);
      _currentCart = updatedCart;

      return CartAddResult.success(cart: updatedCart);
    } catch (e) {
      return CartAddResult.error(message: 'Failed to add item to cart: $e');
    }
  }

  /// Remove item from cart
  Future<CartOperationResult> removeFromCart(String productId) async {
    try {
      final currentCart = await getCurrentCart();

      if (!currentCart.containsProduct(productId)) {
        return CartOperationResult.error(message: 'Product not found in cart');
      }

      final updatedCart = currentCart.removeItem(productId);

      await _cartDataService.saveCart(updatedCart);
      _currentCart = updatedCart;

      return CartOperationResult.success(cart: updatedCart);
    } catch (e) {
      return CartOperationResult.error(message: 'Failed to remove item: $e');
    }
  }

  /// Update item quantity
  Future<CartOperationResult> updateQuantity(
    String productId,
    int quantity,
  ) async {
    try {
      final currentCart = await getCurrentCart();

      if (!currentCart.containsProduct(productId)) {
        return CartOperationResult.error(message: 'Product not found in cart');
      }

      final updatedCart = currentCart.updateItemQuantity(productId, quantity);

      await _cartDataService.saveCart(updatedCart);
      _currentCart = updatedCart;

      return CartOperationResult.success(cart: updatedCart);
    } catch (e) {
      return CartOperationResult.error(
        message: 'Failed to update quantity: $e',
      );
    }
  }

  /// Clear entire cart
  Future<CartOperationResult> clearCart() async {
    try {
      final clearedCart = CartEntity(lastUpdated: DateTime.now());

      await _cartDataService.saveCart(clearedCart);
      _currentCart = clearedCart;

      return CartOperationResult.success(cart: clearedCart);
    } catch (e) {
      return CartOperationResult.error(message: 'Failed to clear cart: $e');
    }
  }

  /// Check if product is in cart
  Future<bool> isProductInCart(String productId) async {
    final currentCart = await getCurrentCart();
    return currentCart.containsProduct(productId);
  }

  /// Check if product from specific agent is in cart
  Future<bool> isProductInCartFromAgent(
    String productId,
    String agentId,
  ) async {
    final currentCart = await getCurrentCart();
    return currentCart.items.any(
      (item) => item.productId == productId && item.agentId == agentId,
    );
  }

  /// Get cart item for specific product
  Future<CartItemEntity?> getCartItem(String productId) async {
    final currentCart = await getCurrentCart();
    return currentCart.getItem(productId);
  }

  /// Get cart item for specific product from specific agent
  Future<CartItemEntity?> getCartItemFromAgent(
    String productId,
    String agentId,
  ) async {
    final currentCart = await getCurrentCart();
    try {
      return currentCart.items.firstWhere(
        (item) => item.productId == productId && item.agentId == agentId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Force add item after clearing conflicting agent items
  Future<CartOperationResult> clearAndAddFromNewAgent({
    required String productId,
    required String productName,
    required String agentId,
    required String agentName,
    required double price,
    String? imageUrl,
    String? description,
    int quantity = 1,
  }) async {
    try {
      // Clear the cart first
      await clearCart();

      // Add the new item
      final addResult = await addToCart(
        productId: productId,
        productName: productName,
        agentId: agentId,
        agentName: agentName,
        price: price,
        imageUrl: imageUrl,
        description: description,
        quantity: quantity,
      );

      if (addResult.isSuccess) {
        return CartOperationResult.success(cart: addResult.cart!);
      } else {
        return CartOperationResult.error(message: addResult.errorMessage!);
      }
    } catch (e) {
      return CartOperationResult.error(
        message: 'Failed to clear and add item: $e',
      );
    }
  }

  /// Refresh cart from storage
  Future<CartEntity> refreshCart() async {
    _currentCart = await _cartDataService.loadCart();
    return _currentCart!;
  }
}

/// Result class for add to cart operations
class CartAddResult {
  final bool isSuccess;
  final bool isAlreadyInCart;
  final bool isDifferentAgent;
  final String? currentAgentName;
  final String? errorMessage;
  final CartEntity? cart;

  const CartAddResult._({
    required this.isSuccess,
    this.isAlreadyInCart = false,
    this.isDifferentAgent = false,
    this.currentAgentName,
    this.errorMessage,
    this.cart,
  });

  factory CartAddResult.success({required CartEntity cart}) {
    return CartAddResult._(isSuccess: true, cart: cart);
  }

  factory CartAddResult.alreadyInCart() {
    return const CartAddResult._(isSuccess: false, isAlreadyInCart: true);
  }

  factory CartAddResult.differentAgent({required String currentAgentName}) {
    return CartAddResult._(
      isSuccess: false,
      isDifferentAgent: true,
      currentAgentName: currentAgentName,
    );
  }

  factory CartAddResult.error({required String message}) {
    return CartAddResult._(isSuccess: false, errorMessage: message);
  }
}

/// Result class for general cart operations
class CartOperationResult {
  final bool isSuccess;
  final String? errorMessage;
  final CartEntity? cart;

  const CartOperationResult._({
    required this.isSuccess,
    this.errorMessage,
    this.cart,
  });

  factory CartOperationResult.success({required CartEntity cart}) {
    return CartOperationResult._(isSuccess: true, cart: cart);
  }

  factory CartOperationResult.error({required String message}) {
    return CartOperationResult._(isSuccess: false, errorMessage: message);
  }
}
